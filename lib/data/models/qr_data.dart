import 'dart:convert';

class QrData {
  final String serialNumber;
  final String batchProductionId;
  final String templateId;

  const QrData({
    required this.serialNumber,
    required this.batchProductionId,
    required this.templateId,
  });

  factory QrData.fromJson(Map<String, dynamic> json) {
    return QrData(
      serialNumber: json['serial_number'] ?? '',
      batchProductionId: json['batch_production_id'] ?? '',
      templateId: json['template_id'] ?? '',
    );
  }

  factory QrData.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return QrData.fromJson(json);
    } catch (e) {
      print('DEBUG: Error parsing QR JSON: $e');
      // Fallback: treat the entire string as serial number for backward compatibility
      return QrData(
        serialNumber: jsonString,
        batchProductionId: '',
        templateId: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'batch_production_id': batchProductionId,
      'template_id': templateId,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  // Check if this is a complete QR data (has all required fields)
  bool get isComplete =>
      serialNumber.isNotEmpty &&
      batchProductionId.isNotEmpty &&
      templateId.isNotEmpty;

  // Check if this is legacy format (only serial number)
  bool get isLegacyFormat =>
      serialNumber.isNotEmpty &&
      batchProductionId.isEmpty &&
      templateId.isEmpty;

  @override
  String toString() => 'QrData(serial: $serialNumber, batch: $batchProductionId, template: $templateId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrData &&
          runtimeType == other.runtimeType &&
          serialNumber == other.serialNumber &&
          batchProductionId == other.batchProductionId &&
          templateId == other.templateId;

  @override
  int get hashCode =>
      serialNumber.hashCode ^
      batchProductionId.hashCode ^
      templateId.hashCode;
}
