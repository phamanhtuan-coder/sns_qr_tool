import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';

class StockOrder extends Equatable {
  final String id;
  final String type; // 'stockIn' or 'stockOut'
  final String date;
  final String status;
  final List<DeviceType> deviceTypes;

  const StockOrder({
    required this.id,
    required this.type,
    required this.date,
    required this.status,
    required this.deviceTypes,
  });

  @override
  List<Object> get props => [id, type, date, status, deviceTypes];
}

class DeviceType extends Equatable {
  final String type;
  final int quantity;
  final List<OrderDevice>? devices; // Chỉ dùng cho stockIn

  const DeviceType({
    required this.type,
    required this.quantity,
    this.devices,
  });

  @override
  List<Object?> get props => [type, quantity, devices];
}

class OrderDevice extends Equatable {
  final String id;
  final String serialNumber;

  const OrderDevice({
    required this.id,
    required this.serialNumber,
  });

  @override
  List<Object> get props => [id, serialNumber];
}

// Mock data
final List<StockOrder> mockStockOrders = [
  const StockOrder(
    id: 'IN-2024-001',
    type: 'stockIn',
    date: '2024-02-20',
    status: 'pending',
    deviceTypes: [
      DeviceType(
        type: 'Smart Sensor',
        quantity: 2,
        devices: [
          OrderDevice(id: 'DEV-2024-001', serialNumber: 'SN20240215-001'),
          OrderDevice(id: 'DEV-2024-002', serialNumber: 'SN20240215-002'),
        ],
      ),
      DeviceType(
        type: 'Control Unit',
        quantity: 1,
        devices: [
          OrderDevice(id: 'DEV-2024-004', serialNumber: 'SN20240216-001'),
        ],
      ),
    ],
  ),
  const StockOrder(
    id: 'IN-2024-002',
    type: 'stockIn',
    date: '2024-02-21',
    status: 'pending',
    deviceTypes: [
      DeviceType(
        type: 'Smart Sensor',
        quantity: 1,
        devices: [
          OrderDevice(id: 'DEV-2024-003', serialNumber: 'SN20240215-003'),
        ],
      ),
      DeviceType(
        type: 'Control Unit',
        quantity: 1,
        devices: [
          OrderDevice(id: 'DEV-2024-005', serialNumber: 'SN20240216-002'),
        ],
      ),
      DeviceType(
        type: 'Gateway',
        quantity: 1,
        devices: [
          OrderDevice(id: 'DEV-2024-006', serialNumber: 'SN20240217-001'),
        ],
      ),
    ],
  ),
  const StockOrder(
    id: 'OUT-2024-001',
    type: 'stockOut',
    date: '2024-02-22',
    status: 'pending',
    deviceTypes: [
      DeviceType(type: 'Smart Sensor', quantity: 2),
      DeviceType(type: 'Control Unit', quantity: 1),
    ],
  ),
  const StockOrder(
    id: 'OUT-2024-002',
    type: 'stockOut',
    date: '2024-02-23',
    status: 'pending',
    deviceTypes: [
      DeviceType(type: 'Gateway', quantity: 2),
      DeviceType(type: 'Smart Sensor', quantity: 1),
    ],
  ),
];