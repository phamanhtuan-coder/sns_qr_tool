import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final int id;
  final int batchId;
  final String serial;
  final String status;
  final String? reason;
  final String? imageUrl;
  final String? modelType; // Added modelType property to represent device type

  const Device({
    required this.id,
    required this.batchId,
    required this.serial,
    required this.status,
    this.reason,
    this.imageUrl,
    this.modelType, // Added modelType parameter
  });

  Device copyWith({
    String? status,
    String? reason,
    String? imageUrl,
    String? modelType, // Added modelType
  }) {
    return Device(
      id: id,
      batchId: batchId,
      serial: serial,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      imageUrl: imageUrl ?? this.imageUrl,
      modelType: modelType ?? this.modelType, // Added modelType
    );
  }

  @override
  List<Object?> get props => [id, batchId, serial, status, reason, imageUrl, modelType];
}

final sampleDevices = [
  const Device(id: 1, batchId: 1, serial: 'SN001', status: 'pending'),
  const Device(id: 2, batchId: 1, serial: 'SN002', status: 'pending'),
  const Device(id: 3, batchId: 1, serial: 'SN003', status: 'pending'),
  const Device(id: 4, batchId: 2, serial: 'SN004', status: 'pending'),
  const Device(id: 5, batchId: 2, serial: 'SN005', status: 'pending'),
  const Device(id: 6, batchId: 3, serial: 'SN006', status: 'pending'),
];