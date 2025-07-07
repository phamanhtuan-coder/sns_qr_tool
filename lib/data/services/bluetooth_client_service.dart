import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum AppBluetoothState {
  unknown,
  unavailable,
  unauthorized,
  poweredOff,
  poweredOn,
}

class AppBluetoothDevice {
  final String name;
  final String address;
  final bool isBonded;
  final bool isConnected;

  const AppBluetoothDevice({
    required this.name,
    required this.address,
    required this.isBonded,
    this.isConnected = false,
  });

  @override
  String toString() => 'AppBluetoothDevice(name: $name, address: $address, bonded: $isBonded)';
}

class BluetoothClientService {
  static BluetoothClientService? _instance;
  BluetoothClientService._internal();

  factory BluetoothClientService() {
    _instance ??= BluetoothClientService._internal();
    return _instance!;
  }

  final StreamController<ConnectionStatus> _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final StreamController<AppBluetoothState> _bluetoothStateController = StreamController<AppBluetoothState>.broadcast();
  final StreamController<List<AppBluetoothDevice>> _devicesController = StreamController<List<AppBluetoothDevice>>.broadcast();

  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<AppBluetoothState> get bluetoothState => _bluetoothStateController.stream;
  Stream<List<AppBluetoothDevice>> get devicesStream => _devicesController.stream;

  AppBluetoothDevice? _connectedDevice;
  AppBluetoothDevice? _connectingDevice;
  List<AppBluetoothDevice> _discoveredDevices = [];
  List<AppBluetoothDevice> _bondedDevices = [];
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;

  AppBluetoothDevice? get connectedDevice => _connectedDevice;
  List<AppBluetoothDevice> get bondedDevices => _bondedDevices;
  List<AppBluetoothDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _scanSubscription != null;

  Future<void> initialize() async {
    try {
      print('DEBUG: Initializing Bluetooth service');
      await _checkBluetoothState();
      await _loadBondedDevices();
      _listenToBluetoothState();
    } catch (e) {
      print('DEBUG: Error initializing Bluetooth: $e');
      _bluetoothStateController.add(AppBluetoothState.unavailable);
    }
  }

  Future<void> _checkBluetoothState() async {
    try {
      final adapterState = await fbp.FlutterBluePlus.adapterState.first;
      _mapAdapterState(adapterState);
    } catch (e) {
      print('DEBUG: Error checking Bluetooth state: $e');
      _bluetoothStateController.add(AppBluetoothState.unavailable);
    }
  }

  void _mapAdapterState(fbp.BluetoothAdapterState state) {
    switch (state) {
      case fbp.BluetoothAdapterState.on:
        _bluetoothStateController.add(AppBluetoothState.poweredOn);
        break;
      case fbp.BluetoothAdapterState.off:
        _bluetoothStateController.add(AppBluetoothState.poweredOff);
        break;
      case fbp.BluetoothAdapterState.unavailable:
        _bluetoothStateController.add(AppBluetoothState.unavailable);
        break;
      case fbp.BluetoothAdapterState.unauthorized:
        _bluetoothStateController.add(AppBluetoothState.unauthorized);
        break;
      default:
        _bluetoothStateController.add(AppBluetoothState.unknown);
    }
  }

  void _listenToBluetoothState() {
    _adapterStateSubscription = fbp.FlutterBluePlus.adapterState.listen(_mapAdapterState);
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final permissions = [
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
        ];

        Map<Permission, PermissionStatus> statuses = await permissions.request();

        return statuses.values.every((status) =>
          status == PermissionStatus.granted || status == PermissionStatus.limited);
      }
      return true;
    } catch (e) {
      print('DEBUG: Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await fbp.FlutterBluePlus.turnOn();
        // Check if Bluetooth is actually enabled after the request
        final adapterState = await fbp.FlutterBluePlus.adapterState.first;
        return adapterState == fbp.BluetoothAdapterState.on;
      }
      return true;
    } catch (e) {
      print('DEBUG: Error enabling Bluetooth: $e');
      return false;
    }
  }

  Future<void> _loadBondedDevices() async {
    try {
      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      _bondedDevices = bondedDevices.map((device) => AppBluetoothDevice(
        name: device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
        address: device.remoteId.str,
        isBonded: true,
        isConnected: _connectedDevice?.address == device.remoteId.str,
      )).toList();

      _devicesController.add(_bondedDevices);
      print('DEBUG: Loaded ${_bondedDevices.length} bonded devices');
    } catch (e) {
      print('DEBUG: Error loading bonded devices: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (isScanning) return;

    try {
      _discoveredDevices.clear();
      print('DEBUG: Starting Bluetooth device discovery');

      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final device = result.device;
          final bluetoothDevice = AppBluetoothDevice(
            name: device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
            address: device.remoteId.str,
            isBonded: false,
          );

          // Add device if not already in list
          if (!_discoveredDevices.any((d) => d.address == bluetoothDevice.address) &&
              !_bondedDevices.any((d) => d.address == bluetoothDevice.address)) {
            _discoveredDevices.add(bluetoothDevice);
            _devicesController.add([..._bondedDevices, ..._discoveredDevices]);
          }
        }
      });

      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    } catch (e) {
      print('DEBUG: Error during device discovery: $e');
      await stopDiscovery();
    }
  }

  Future<void> stopDiscovery() async {
    if (!isScanning) return;

    try {
      await fbp.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      print('DEBUG: Device discovery stopped');
    } catch (e) {
      print('DEBUG: Error stopping discovery: $e');
    }
  }

  Future<bool> connectToDevice(AppBluetoothDevice device) async {
    try {
      print('DEBUG: Connecting to device: ${device.name} (${device.address})');
      _connectionStatusController.add(ConnectionStatus.connecting);
      _connectingDevice = device;

      // Disconnect from previous connection
      await disconnect();

      // Find the BluetoothDevice from flutter_blue_plus
      final targetDevice = fbp.BluetoothDevice.fromId(device.address);

      await targetDevice.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device.copyWith(isConnected: true);
      _connectingDevice = null;
      _connectionStatusController.add(ConnectionStatus.connected);
      await _loadBondedDevices(); // Refresh device list

      print('DEBUG: Successfully connected to ${device.name}');
      return true;
    } catch (e) {
      print('DEBUG: Error connecting to device: $e');
      _connectingDevice = null;
      _connectionStatusController.add(ConnectionStatus.error);
      return false;
    }
  }

  Future<bool> sendSerialToDesktop(String serialNumber) async {
    if (_connectedDevice == null) {
      print('DEBUG: No active Bluetooth connection');
      return false;
    }

    try {
      print('DEBUG: Sending serial number via Bluetooth: $serialNumber');

      // For flutter_blue_plus, we need to find services and characteristics
      final targetDevice = fbp.BluetoothDevice.fromId(_connectedDevice!.address);
      final services = await targetDevice.discoverServices();

      // Look for a suitable characteristic to write to
      // This is a simplified approach - you might need to adjust based on your specific device
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            final data = '$serialNumber\n';
            final dataBytes = Uint8List.fromList(data.codeUnits);
            await characteristic.write(dataBytes);
            print('DEBUG: Serial number sent successfully via Bluetooth');
            return true;
          }
        }
      }

      print('DEBUG: No writable characteristic found');
      return false;
    } catch (e) {
      print('DEBUG: Error sending serial via Bluetooth: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        final targetDevice = fbp.BluetoothDevice.fromId(_connectedDevice!.address);
        await targetDevice.disconnect();
      }

      _connectedDevice = null;
      _connectionStatusController.add(ConnectionStatus.disconnected);
      await _loadBondedDevices(); // Refresh device list

      print('DEBUG: Bluetooth disconnected');
    } catch (e) {
      print('DEBUG: Error during disconnect: $e');
    }
  }

  void dispose() {
    disconnect();
    stopDiscovery();
    _adapterStateSubscription?.cancel();
    _connectionStatusController.close();
    _bluetoothStateController.close();
    _devicesController.close();
  }
}

extension AppBluetoothDeviceExtension on AppBluetoothDevice {
  AppBluetoothDevice copyWith({
    String? name,
    String? address,
    bool? isBonded,
    bool? isConnected,
  }) {
    return AppBluetoothDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      isBonded: isBonded ?? this.isBonded,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
