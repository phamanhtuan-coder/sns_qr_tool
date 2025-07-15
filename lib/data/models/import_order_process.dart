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
    return ImportOrderProcess(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      totalSerialNeed: int.tryParse(json['total_serial_need']?.toString() ?? '0') ?? 0,
      totalSerialImported: int.tryParse(json['total_serial_imported']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isCompleted => totalSerialImported >= totalSerialNeed;

  int get remainingToScan => totalSerialNeed - totalSerialImported;

  @override
  List<Object?> get props => [
    productId,
    productName,
    totalSerialNeed,
    totalSerialImported,
  ];
}
