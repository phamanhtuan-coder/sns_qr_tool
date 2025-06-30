import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
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

class BluetoothDevice {
  final String name;
  final String address;
  final bool isBonded;
  final bool isConnected;

  const BluetoothDevice({
    required this.name,
    required this.address,
    required this.isBonded,
    this.isConnected = false,
  });

  @override
  String toString() => 'BluetoothDevice(name: $name, address: $address, bonded: $isBonded)';
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
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();

  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<AppBluetoothState> get bluetoothState => _bluetoothStateController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  fbs.BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  List<BluetoothDevice> _discoveredDevices = [];
  List<BluetoothDevice> _bondedDevices = [];

  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get bondedDevices => _bondedDevices;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;

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
      final isEnabled = await fbs.FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == true) {
        _bluetoothStateController.add(AppBluetoothState.poweredOn);
      } else {
        _bluetoothStateController.add(AppBluetoothState.poweredOff);
      }
    } catch (e) {
      print('DEBUG: Error checking Bluetooth state: $e');
      _bluetoothStateController.add(AppBluetoothState.unavailable);
    }
  }

  void _listenToBluetoothState() {
    fbs.FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      switch (state) {
        case fbs.BluetoothState.STATE_ON:
          _bluetoothStateController.add(AppBluetoothState.poweredOn);
          break;
        case fbs.BluetoothState.STATE_OFF:
          _bluetoothStateController.add(AppBluetoothState.poweredOff);
          break;
        default:
          _bluetoothStateController.add(AppBluetoothState.unknown);
      }
    });
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
      final isEnabled = await fbs.FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == true) return true;

      final result = await fbs.FlutterBluetoothSerial.instance.requestEnable();
      return result == true;
    } catch (e) {
      print('DEBUG: Error enabling Bluetooth: $e');
      return false;
    }
  }

  Future<void> _loadBondedDevices() async {
    try {
      final bondedDevices = await fbs.FlutterBluetoothSerial.instance.getBondedDevices();
      _bondedDevices = bondedDevices.map((device) => BluetoothDevice(
        name: device.name ?? 'Unknown Device',
        address: device.address,
        isBonded: true,
        isConnected: _connectedDevice?.address == device.address,
      )).toList();

      _devicesController.add(_bondedDevices);
      print('DEBUG: Loaded ${_bondedDevices.length} bonded devices');
    } catch (e) {
      print('DEBUG: Error loading bonded devices: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _discoveredDevices.clear();

      print('DEBUG: Starting Bluetooth device discovery');

      fbs.FlutterBluetoothSerial.instance.startDiscovery().listen((device) {
        final bluetoothDevice = BluetoothDevice(
          name: device.device.name ?? 'Unknown Device',
          address: device.device.address,
          isBonded: device.device.isBonded,
        );

        // Add device if not already in list
        if (!_discoveredDevices.any((d) => d.address == bluetoothDevice.address)) {
          _discoveredDevices.add(bluetoothDevice);
          _devicesController.add([..._bondedDevices, ..._discoveredDevices]);
        }
      }).onDone(() {
        _isScanning = false;
        print('DEBUG: Device discovery completed');
      });

    } catch (e) {
      _isScanning = false;
      print('DEBUG: Error during device discovery: $e');
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isScanning) return;

    try {
      await fbs.FlutterBluetoothSerial.instance.cancelDiscovery();
      _isScanning = false;
      print('DEBUG: Device discovery stopped');
    } catch (e) {
      print('DEBUG: Error stopping discovery: $e');
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print('DEBUG: Connecting to device: ${device.name} (${device.address})');
      _connectionStatusController.add(ConnectionStatus.connecting);

      // Disconnect from previous connection
      await disconnect();

      _connection = await fbs.BluetoothConnection.toAddress(device.address);
      _connectedDevice = device.copyWith(isConnected: true);

      _connectionStatusController.add(ConnectionStatus.connected);
      await _loadBondedDevices(); // Refresh device list

      print('DEBUG: Successfully connected to ${device.name}');
      return true;
    } catch (e) {
      print('DEBUG: Error connecting to device: $e');
      _connectionStatusController.add(ConnectionStatus.error);
      return false;
    }
  }

  Future<bool> sendSerialToDesktop(String serialNumber) async {
    if (_connection == null || _connectedDevice == null) {
      print('DEBUG: No active Bluetooth connection');
      return false;
    }

    try {
      print('DEBUG: Sending serial number via Bluetooth: $serialNumber');

      final data = '$serialNumber\n';
      final dataBytes = Uint8List.fromList(data.codeUnits);
      _connection!.output.add(dataBytes);
      await _connection!.output.allSent;

      print('DEBUG: Serial number sent successfully via Bluetooth');
      return true;
    } catch (e) {
      print('DEBUG: Error sending serial via Bluetooth: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        _connection!.dispose();
        _connection = null;
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
    _connectionStatusController.close();
    _bluetoothStateController.close();
    _devicesController.close();
  }
}

extension BluetoothDeviceExtension on BluetoothDevice {
  BluetoothDevice copyWith({
    String? name,
    String? address,
    bool? isBonded,
    bool? isConnected,
  }) {
    return BluetoothDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      isBonded: isBonded ?? this.isBonded,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
