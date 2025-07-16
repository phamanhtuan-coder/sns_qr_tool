import 'package:equatable/equatable.dart';

class ImportOrderProcess extends Equatable {
  final String productId;
  final String productName;
  final int totalSerialNeed;
  final int totalSerialImported;

  const ImportOrderProcess({
    required this.productId,
    required this.productName,
    required this.totalSerialNeed,
    required this.totalSerialImported,
  });

  factory ImportOrderProcess.fromJson(Map<String, dynamic> json) {
    // Convert string values to int where needed
    int parseNumber(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ImportOrderProcess(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      totalSerialNeed: parseNumber(json['total_serial_need']),
      totalSerialImported: parseNumber(json['total_serial_imported']),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'total_serial_need': totalSerialNeed,
    'total_serial_imported': totalSerialImported,
  };

  bool get isCompleted => totalSerialImported >= totalSerialNeed;
  int get remainingToScan => totalSerialNeed - totalSerialImported;
  double get progressPercentage => totalSerialNeed > 0 ? (totalSerialImported / totalSerialNeed) : 0;

  @override
  List<Object> get props => [productId, productName, totalSerialNeed, totalSerialImported];
}
