import 'package:equatable/equatable.dart';

class ExportOrder extends Equatable {
  final String id;
  final String? exportCode;
  final int? exportNumber;
  final String employeeId;
  final DateTime exportDate;
  final String? fileAuthenticate;
  final double? totalProfit;
  final String note;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ExportOrderDetail> detailExport;
  final String? customerName; // Add this field

  const ExportOrder({
    required this.id,
    this.exportCode,
    this.exportNumber,
    required this.employeeId,
    required this.exportDate,
    this.fileAuthenticate,
    this.totalProfit,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.detailExport = const [],
    this.customerName, // Add this parameter
  });

  factory ExportOrder.fromJson(Map<String, dynamic> json) {
    return ExportOrder(
      id: json['id']?.toString() ?? '',
      exportCode: json['export_code']?.toString(),
      exportNumber: json['export_number'] != null ? int.tryParse(json['export_number'].toString()) : null,
      employeeId: json['employee_id']?.toString() ?? '',
      exportDate: DateTime.parse(json['export_date'] as String),
      fileAuthenticate: json['file_authenticate']?.toString(),
      totalProfit: json['total_profit'] != null ? double.tryParse(json['total_profit'].toString()) : null,
      note: json['note']?.toString() ?? '',
      status: json['status'] != null ? int.tryParse(json['status'].toString()) ?? 0 : 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      detailExport: (json['detail_export'] as List<dynamic>? ?? [])
          .map((detail) => ExportOrderDetail.fromJson(detail))
          .toList(),
      customerName: json['customer_name'] as String?, // Add this field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'export_code': exportCode,
      'export_number': exportNumber,
      'employee_id': employeeId,
      'export_date': exportDate.toIso8601String(),
      'file_authenticate': fileAuthenticate,
      'total_profit': totalProfit,
      'note': note,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'detail_export': detailExport.map((detail) => detail.toJson()).toList(),
      'customer_name': customerName, // Add this field
    };
  }

  @override
  List<Object?> get props => [
        id,
        exportCode,
        exportNumber,
        employeeId,
        exportDate,
        fileAuthenticate,
        totalProfit,
        note,
        status,
        createdAt,
        updatedAt,
        deletedAt,
        detailExport,
        customerName, // Add customerName to props
      ];
}

class ExportOrderDetail extends Equatable {
  final String? batchCode;
  final int? exportId;
  final String? orderId;
  final String productId;
  final int quantity;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ExportOrderDetail({
    this.batchCode,
    this.exportId,
    this.orderId,
    required this.productId,
    required this.quantity,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ExportOrderDetail.fromJson(Map<String, dynamic> json) {
    return ExportOrderDetail(
      batchCode: json['batch_code']?.toString(),
      exportId: json['export_id'] != null ? int.tryParse(json['export_id'].toString()) : null,
      orderId: json['order_id']?.toString(),
      productId: json['product_id'].toString(),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_code': batchCode,
      'export_id': exportId,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        batchCode,
        exportId,
        orderId,
        productId,
        quantity,
        note,
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
