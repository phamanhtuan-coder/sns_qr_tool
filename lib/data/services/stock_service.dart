import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';

class StockService {
  // Mock devices database
  final List<Device> _mockDevices = [
    const Device(
      id: 1,
      batchId: 1,
      serial: 'DEV-2024-001',
      status: 'pending',
    ),
    const Device(
      id: 2,
      batchId: 1,
      serial: 'DEV-2024-002',
      status: 'pending',
    ),
    const Device(
      id: 3,
      batchId: 1,
      serial: 'DEV-2024-003',
      status: 'pending',
    ),
    const Device(
      id: 4,
      batchId: 2,
      serial: 'DEV-2024-004',
      status: 'pending',
    ),
    const Device(
      id: 5,
      batchId: 2,
      serial: 'DEV-2024-005',
      status: 'pending',
    ),
    const Device(
      id: 6,
      batchId: 3,
      serial: 'DEV-2024-006',
      status: 'pending',
    ),
  ];

  // Mock expanded devices with types
  final List<Map<String, dynamic>> _mockDevicesWithTypes = [
    {
      'id': 'DEV-2024-001',
      'type': 'Smart Sensor',
      'model': 'SS-100',
      'serialNumber': 'SN20240215-001',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-002',
      'type': 'Smart Sensor',
      'model': 'SS-100',
      'serialNumber': 'SN20240215-002',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-003',
      'type': 'Smart Sensor',
      'model': 'SS-100',
      'serialNumber': 'SN20240215-003',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-004',
      'type': 'Control Unit',
      'model': 'CU-200',
      'serialNumber': 'SN20240216-001',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-005',
      'type': 'Control Unit',
      'model': 'CU-200',
      'serialNumber': 'SN20240216-002',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-006',
      'type': 'Gateway',
      'model': 'GW-300',
      'serialNumber': 'SN20240217-001',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-007',
      'type': 'Gateway',
      'model': 'GW-300',
      'serialNumber': 'SN20240217-002',
      'manufacturer': 'Tech Corp',
    },
    {
      'id': 'DEV-2024-008',
      'type': 'Gateway',
      'model': 'GW-300',
      'serialNumber': 'SN20240217-003',
      'manufacturer': 'Tech Corp',
    },
  ];

  Future<List<StockOrder>> getOrdersByType(String type) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return mockStockOrders.where((order) => order.type == type).toList();
  }

  Future<Map<String, dynamic>> scanDevice(
      String deviceId,
      StockOrder order,
      Map<String, bool> scannedItems,
      Map<String, int> scannedCounts,
      List<Device> scannedDevices,
      ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (order.type == 'stockIn') {
      return _handleStockInScan(deviceId, order, scannedItems);
    } else {
      return _handleStockOutScan(deviceId, order, scannedCounts);
    }
  }

  Map<String, dynamic> _handleStockInScan(
      String deviceId,
      StockOrder order,
      Map<String, bool> scannedItems,
      ) {
    // Find device in order
    bool deviceFound = false;
    for (final deviceType in order.deviceTypes) {
      if (deviceType.devices?.any((device) => device.id == deviceId) ?? false) {
        deviceFound = true;
        break;
      }
    }

    if (!deviceFound) {
      return {
        'success': false,
        'message': 'Thiết bị không có trong đơn hàng này',
      };
    }

    if (scannedItems[deviceId] == true) {
      return {
        'success': false,
        'message': 'Thiết bị đã được quét trước đó',
      };
    }

    final deviceData = _mockDevicesWithTypes.firstWhere(
          (device) => device['id'] == deviceId,
      orElse: () => {},
    );

    return {
      'success': true,
      'message': 'Quét thiết bị thành công',
      'device': Device(
        id: 1,
        batchId: 1,
        serial: deviceId,
        status: 'scanned',
      ),
      'deviceData': deviceData,
    };
  }

  Map<String, dynamic> _handleStockOutScan(
      String deviceId,
      StockOrder order,
      Map<String, int> scannedCounts,
      ) {
    final deviceData = _mockDevicesWithTypes.firstWhere(
          (device) => device['id'] == deviceId,
      orElse: () => {},
    );

    if (deviceData.isEmpty) {
      return {
        'success': false,
        'message': 'Thiết bị không hợp lệ',
      };
    }

    final deviceType = deviceData['type'] as String;

    // Check if device type is required in order
    final deviceTypeInOrder = order.deviceTypes.firstWhere(
          (dt) => dt.type == deviceType,
      orElse: () => const DeviceType(type: '', quantity: 0),
    );

    if (deviceTypeInOrder.type.isEmpty) {
      return {
        'success': false,
        'message': 'Loại thiết bị này không cần thiết trong đơn hàng',
      };
    }

    final currentCount = scannedCounts[deviceType] ?? 0;
    if (currentCount >= deviceTypeInOrder.quantity) {
      return {
        'success': false,
        'message': 'Đã quét đủ thiết bị loại $deviceType',
      };
    }

    return {
      'success': true,
      'message': 'Quét thiết bị thành công',
      'device': Device(
        id: 1,
        batchId: 1,
        serial: deviceId,
        status: 'scanned',
      ),
      'deviceData': deviceData,
    };
  }
}