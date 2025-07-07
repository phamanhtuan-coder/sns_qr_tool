// Add this to your export_order.dart file or create a new enhanced_export_item.dart

import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';

class EnhancedExportItem extends Equatable {
  final String serialNumber;
  final String templateId;
  final String batchProductionId;
  final String deviceType;
  final String productName;
  final String? productImage;
  final String status;
  final DateTime scannedAt;

  const EnhancedExportItem({
    required this.serialNumber,
    required this.templateId,
    required this.batchProductionId,
    required this.deviceType,
    required this.productName,
    this.productImage,
    required this.status,
    required this.scannedAt,
  });

  factory EnhancedExportItem.fromJson(Map<String, dynamic> json) {
    return EnhancedExportItem(
      serialNumber: json['serial_number'] as String,
      templateId: json['template_id'] as String,
      batchProductionId: json['batch_production_id'] as String,
      deviceType: json['device_type'] as String? ?? 'Unknown Device',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      productImage: json['product_image'] as String?,
      status: json['status'] as String? ?? 'unknown',
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'template_id': templateId,
      'batch_production_id': batchProductionId,
      'device_type': deviceType,
      'product_name': productName,
      'product_image': productImage,
      'status': status,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  // Convert to original ExportItem for compatibility
  ExportItem toExportItem() {
    return ExportItem(
      serialNumber: serialNumber,
      templateId: templateId,
      batchProductionId: batchProductionId,
    );
  }

  // Factory method to create from original ExportItem
  factory EnhancedExportItem.fromExportItem(
      ExportItem item, {
        String? deviceType,
        String? productName,
        String? productImage,
        String? status,
      }) {
    return EnhancedExportItem(
      serialNumber: item.serialNumber,
      templateId: item.templateId,
      batchProductionId: item.batchProductionId,
      deviceType: deviceType ?? getDefaultDeviceType(item.templateId),
      productName: productName ?? 'Product ${item.templateId}',
      productImage: productImage,
      status: status ?? 'scanned',
      scannedAt: DateTime.now(),
    );
  }

  // Static method to get default device type (will be replaced by API data)
  static String getDefaultDeviceType(String templateId) {
    // This is a fallback - should be replaced with actual API data
    return 'Device Type $templateId';
  }

  @override
  List<Object?> get props => [
    serialNumber,
    templateId,
    batchProductionId,
    deviceType,
    productName,
    productImage,
    status,
    scannedAt,
  ];
}