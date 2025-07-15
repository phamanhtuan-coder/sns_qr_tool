import 'package:equatable/equatable.dart';

class ImportOrderDetail extends Equatable {
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
  final List<ImportOrderDevice> devices;

  const ImportOrderDetail({
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
    required this.devices,
  });

  factory ImportOrderDetail.fromJson(Map<String, dynamic> json) {
    return ImportOrderDetail(
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
      devices: (json['devices'] as List<dynamic>? ?? [])
          .map((device) => ImportOrderDevice.fromJson(device))
          .toList(),
    );
  }

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
        devices,
      ];
}

class ImportOrderDevice extends Equatable {
  final String id;
  final String templateId;
  final String deviceType;
  final String productName;
  final String? productImage;
  final int requiredQuantity;
  final int scannedQuantity;
  final bool isCompleted;
  final List<String> scannedSerials;

  const ImportOrderDevice({
    required this.id,
    required this.templateId,
    required this.deviceType,
    required this.productName,
    this.productImage,
    required this.requiredQuantity,
    required this.scannedQuantity,
    required this.isCompleted,
    required this.scannedSerials,
  });

  factory ImportOrderDevice.fromJson(Map<String, dynamic> json) {
    return ImportOrderDevice(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      deviceType: json['device_type'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      requiredQuantity: json['required_quantity'] as int,
      scannedQuantity: json['scanned_quantity'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      scannedSerials: (json['scanned_serials'] as List<dynamic>? ?? [])
          .map((serial) => serial.toString())
          .toList(),
    );
  }

  ImportOrderDevice copyWith({
    String? id,
    String? templateId,
    String? deviceType,
    String? productName,
    String? productImage,
    int? requiredQuantity,
    int? scannedQuantity,
    bool? isCompleted,
    List<String>? scannedSerials,
  }) {
    return ImportOrderDevice(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      deviceType: deviceType ?? this.deviceType,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      scannedQuantity: scannedQuantity ?? this.scannedQuantity,
      isCompleted: isCompleted ?? this.isCompleted,
      scannedSerials: scannedSerials ?? this.scannedSerials,
    );
  }

  @override
  List<Object?> get props => [
        id,
        templateId,
        deviceType,
        productName,
        productImage,
        requiredQuantity,
        scannedQuantity,
        isCompleted,
        scannedSerials,
      ];
}
