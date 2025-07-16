import 'package:equatable/equatable.dart';

class ImportOrder extends Equatable {
  final String id;
  final int importNumber;
  final String employeeId;
  final int warehouseId;
  final DateTime importDate;
  final String? fileAuthenticate;
  final double? totalMoney;
  final String note;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? supplierName;
  final int? totalQuantity; // Add total quantity field

  const ImportOrder({
    required this.id,
    required this.importNumber,
    required this.employeeId,
    required this.warehouseId,
    required this.importDate,
    this.fileAuthenticate,
    this.totalMoney,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.supplierName,
    this.totalQuantity,
  });

  factory ImportOrder.fromJson(Map<String, dynamic> json) {
    return ImportOrder(
      id: json['id'] as String,
      importNumber: json['import_number'] as int,
      employeeId: json['employee_id'] as String,
      warehouseId: json['warehouse_id'] as int,
      importDate: DateTime.parse(json['import_date'] as String),
      fileAuthenticate: json['file_authenticate'] as String?,
      totalMoney: json['total_money']?.toDouble(),
      note: json['note'] as String? ?? '',
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      supplierName: json['supplier_name'] as String?,
      totalQuantity: json['total_quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'import_number': importNumber,
    'employee_id': employeeId,
    'warehouse_id': warehouseId,
    'import_date': importDate.toIso8601String(),
    'file_authenticate': fileAuthenticate,
    'total_money': totalMoney,
    'note': note,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'supplier_name': supplierName,
    'total_quantity': totalQuantity,
  };

  @override
  List<Object?> get props => [
    id,
    importNumber,
    employeeId,
    warehouseId,
    importDate,
    fileAuthenticate,
    totalMoney,
    note,
    status,
    createdAt,
    updatedAt,
    deletedAt,
    supplierName,
    totalQuantity,
  ];
}

class ImportOrderItem extends Equatable {
  final String importId;
  final String serialNumber;
  final String batchProductionId;
  final String templateId;

  const ImportOrderItem({
    required this.importId,
    required this.serialNumber,
    required this.batchProductionId,
    required this.templateId,
  });

  factory ImportOrderItem.fromJson(Map<String, dynamic> json) {
    return ImportOrderItem(
      importId: json['import_id'] as String,
      serialNumber: json['serial_number'] as String,
      batchProductionId: json['batch_production_id'] as String,
      templateId: json['template_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import_id': importId,
      'serial_number': serialNumber,
      'batch_production_id': batchProductionId,
      'template_id': templateId,
    };
  }

  @override
  List<Object> get props => [importId, serialNumber, batchProductionId, templateId];
}
