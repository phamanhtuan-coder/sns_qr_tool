import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductionService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> updateDeviceStage(String serialNumber, String stage, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/production-tracking/update-serial'),
        body: json.encode({
          'device_serial': serialNumber,
          'stage': stage,
          'status': status,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200 && (responseData['success'] ?? false),
        'errorCode': responseData['errorCode'],
        'message': responseData['message'] ?? 'Unknown error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    }
  }
}
