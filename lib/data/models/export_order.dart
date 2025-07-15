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
      ];
}

class ExportOrderDetail extends Equatable {
  final String id;
  final String exportOrderId;
  final String productId;
  final int quantity;
  final double price;
  final double discount;
  final double total;

  const ExportOrderDetail({
    required this.id,
    required this.exportOrderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
  });

  factory ExportOrderDetail.fromJson(Map<String, dynamic> json) {
    return ExportOrderDetail(
      id: json['id'] as String,
      exportOrderId: json['export_order_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'export_order_id': exportOrderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
    };
  }

  @override
  List<Object?> get props => [id, exportOrderId, productId, quantity, price, discount, total];
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
