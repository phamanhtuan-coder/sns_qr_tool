import 'package:equatable/equatable.dart';

class ExportOrder extends Equatable {
  final String id;
  final int exportNumber;
  final String employeeId;
  final int warehouseId;
  final DateTime exportDate;
  final String? fileAuthenticate;
  final double? totalMoney;
  final String note;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ExportOrder({
    required this.id,
    required this.exportNumber,
    required this.employeeId,
    required this.warehouseId,
    required this.exportDate,
    this.fileAuthenticate,
    this.totalMoney,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ExportOrder.fromJson(Map<String, dynamic> json) {
    return ExportOrder(
      id: json['id'] as String,
      exportNumber: json['export_number'] as int,
      employeeId: json['employee_id'] as String,
      warehouseId: json['warehouse_id'] as int,
      exportDate: DateTime.parse(json['export_date'] as String),
      fileAuthenticate: json['file_authenticate'] as String?,
      totalMoney: json['total_money']?.toDouble(),
      note: json['note'] as String? ?? '',
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'export_number': exportNumber,
      'employee_id': employeeId,
      'warehouse_id': warehouseId,
      'export_date': exportDate.toIso8601String(),
      'file_authenticate': fileAuthenticate,
      'total_money': totalMoney,
      'note': note,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        exportNumber,
        employeeId,
        warehouseId,
        exportDate,
        fileAuthenticate,
        totalMoney,
        note,
        status,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

class ExportItem extends Equatable {
  final String serialNumber;
  final String templateId;
  final String batchProductionId;

  const ExportItem({
    required this.serialNumber,
    required this.templateId,
    required this.batchProductionId,
  });

  factory ExportItem.fromJson(Map<String, dynamic> json) {
    return ExportItem(
      serialNumber: json['serial_number'] as String,
      templateId: json['template_id'] as String,
      batchProductionId: json['batch_production_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'template_id': templateId,
      'batch_production_id': batchProductionId,
    };
  }

  @override
  List<Object?> get props => [serialNumber, templateId, batchProductionId];
}
