import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  //static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'https://d3b7-14-183-169-129.ngrok-free.app/api';
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // Add other headers like auth tokens here in the future
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': responseData,
        'errorCode': response.statusCode != 200 ? response.statusCode : null,
        'message': response.statusCode != 200 ? 'Request failed' : null,
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        body: json.encode(body),
        headers: _headers,
      );

      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'data': responseData,
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

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        body: json.encode(body),
        headers: _headers,
      );

      final responseData = json.decode(response.body);
      print('Response body: $responseData');
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

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
        'data': responseData,
        'errorCode': response.statusCode != 200 && response.statusCode != 204 ? response.statusCode : null,
        'message': response.statusCode != 200 && response.statusCode != 204 ? 'Delete failed' : null,
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
