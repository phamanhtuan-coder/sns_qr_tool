import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_net_qr_scanner/data/services/auth_service.dart';

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

  @override
  String toString() => 'AppBluetoothDevice(name: $name, address: $address, bonded: $isBonded)';
}

class BluetoothProtocol {
  static const String serviceUuid = "0000110E-0000-1000-8000-00805F9B34FB";
  static const String characteristicUuid = "0000110A-0000-1000-8000-00805F9B34FB";
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration dataTimeout = Duration(seconds: 5);
  static const int maxRetries = 3;
}

class QrDataPayload {
  final String type;
  final String username;
  final String serialNumber;
  final int timestamp;
  final String checksum;

  QrDataPayload({
    required this.username,
    required this.serialNumber,
    this.type = "qr_data",
  }) : timestamp = DateTime.now().millisecondsSinceEpoch,
        checksum = _generateChecksum(username, serialNumber);

  static String _generateChecksum(String username, String serialNumber) {
    return (username + serialNumber).hashCode.abs().toRadixString(16);
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'username': username,
    'serial_number': serialNumber,
    'timestamp': timestamp,
    'checksum': checksum,
  };

  String toJsonString() => jsonEncode(toJson());
}

class BluetoothClientService {
  static BluetoothClientService? _instance;
  BluetoothClientService._internal();

  factory BluetoothClientService() {
    _instance ??= BluetoothClientService._internal();
    return _instance!;
  }

  final StreamController<ConnectionStatus> _connectionStatusController =
  StreamController<ConnectionStatus>.broadcast();
  final StreamController<AppBluetoothState> _bluetoothStateController =
  StreamController<AppBluetoothState>.broadcast();
  final StreamController<List<AppBluetoothDevice>> _devicesController =
  StreamController<List<AppBluetoothDevice>>.broadcast();

  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<AppBluetoothState> get bluetoothState => _bluetoothStateController.stream;
  Stream<List<AppBluetoothDevice>> get devicesStream => _devicesController.stream;

  AppBluetoothDevice? _connectedDevice;
  AppBluetoothDevice? _connectingDevice;
  List<AppBluetoothDevice> _discoveredDevices = [];
  List<AppBluetoothDevice> _bondedDevices = [];
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;

  fbp.BluetoothCharacteristic? _writeCharacteristic;
  fbp.BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription? _readSubscription;

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

      await disconnect();

      final targetDevice = fbp.BluetoothDevice.fromId(device.address);
      await targetDevice.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device.copyWith(isConnected: true);
      _connectingDevice = null;
      _connectionStatusController.add(ConnectionStatus.connected);
      await _loadBondedDevices();

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

      final targetDevice = fbp.BluetoothDevice.fromId(_connectedDevice!.address);

      if (_writeCharacteristic == null) {
        await _discoverServices(targetDevice);
      }

      if (_writeCharacteristic == null) {
        print('DEBUG: No suitable characteristic found for writing');
        return false;
      }

      // Get username from AuthService (async call)
      final authService = GetIt.instance<AuthService>();
      final username = await authService.getUsername() ?? 'unknown_user';

      final payload = QrDataPayload(
        username: username,
        serialNumber: serialNumber,
      );

      return await _sendDataWithRetry(payload);

    } catch (e) {
      print('DEBUG: Error sending serial via Bluetooth: $e');
      return false;
    }
  }

  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    try {
      print('DEBUG: Discovering services...');
      final services = await device.discoverServices();

      for (final service in services) {
        print('DEBUG: Found service: ${service.uuid}');

        if (service.uuid.toString().toUpperCase().contains('110E') ||
            service.characteristics.any((c) => c.properties.write)) {

          for (final characteristic in service.characteristics) {
            print('DEBUG: Found characteristic: ${characteristic.uuid}, properties: ${characteristic.properties}');

            if (characteristic.properties.write && _writeCharacteristic == null) {
              _writeCharacteristic = characteristic;
              print('DEBUG: Using write characteristic: ${characteristic.uuid}');
            }

            if ((characteristic.properties.read || characteristic.properties.notify) &&
                _readCharacteristic == null) {
              _readCharacteristic = characteristic;

              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                _readSubscription = characteristic.lastValueStream.listen(_handleAcknowledgment);
                print('DEBUG: Enabled notifications on: ${characteristic.uuid}');
              }
            }
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error discovering services: $e');
    }
  }

  Future<bool> _sendDataWithRetry(QrDataPayload payload) async {
    for (int attempt = 1; attempt <= BluetoothProtocol.maxRetries; attempt++) {
      try {
        print('DEBUG: Send attempt $attempt/${BluetoothProtocol.maxRetries}');

        final data = payload.toJsonString();
        final dataBytes = Uint8List.fromList(utf8.encode(data + '\n'));

        await _writeCharacteristic!.write(dataBytes, withoutResponse: false);
        print('DEBUG: Data sent successfully: $data');

        if (_readCharacteristic != null) {
          final ackReceived = await _waitForAcknowledgment();
          if (ackReceived) {
            print('DEBUG: Acknowledgment received');
            return true;
          } else {
            print('DEBUG: No acknowledgment received, retrying...');
            continue;
          }
        } else {
          return true;
        }

      } catch (e) {
        print('DEBUG: Send attempt $attempt failed: $e');
        if (attempt == BluetoothProtocol.maxRetries) {
          return false;
        }

        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return false;
  }

  Future<bool> _waitForAcknowledgment() async {
    final completer = Completer<bool>();
    Timer? timeout;

    timeout = Timer(BluetoothProtocol.dataTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    _readSubscription?.onData((data) {
      try {
        final response = utf8.decode(data);
        final json = jsonDecode(response);

        if (json['type'] == 'ack' && json['status'] == 'received') {
          timeout?.cancel();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      } catch (e) {
        print('DEBUG: Error parsing acknowledgment: $e');
      }
    });

    return completer.future;
  }

  void _handleAcknowledgment(List<int> data) {
    try {
      final response = utf8.decode(data);
      print('DEBUG: Received data: $response');

      final json = jsonDecode(response);
      if (json['type'] == 'ready') {
        print('DEBUG: Desktop is ready to receive data');
      } else if (json['type'] == 'ack') {
        print('DEBUG: Received acknowledgment: ${json['status']}');
      }
    } catch (e) {
      print('DEBUG: Error handling acknowledgment: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _readSubscription?.cancel();
      _readSubscription = null;
      _writeCharacteristic = null;
      _readCharacteristic = null;

      if (_connectedDevice != null) {
        final targetDevice = fbp.BluetoothDevice.fromId(_connectedDevice!.address);
        await targetDevice.disconnect();
      }

      _connectedDevice = null;
      _connectionStatusController.add(ConnectionStatus.disconnected);
      await _loadBondedDevices();

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