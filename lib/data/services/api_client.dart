import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  //static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'https://d7ba-14-183-169-129.ngrok-free.app/api';
  final http.Client _client;
  final Duration _timeout;

  ApiClient({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 30);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // Add other headers like auth tokens here in the future
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      print('DEBUG: API GET request to: $baseUrl$endpoint');
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(_timeout);

      print('DEBUG: API GET response status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': responseData,
        'errorCode': response.statusCode != 200 ? response.statusCode : null,
        'message': response.statusCode != 200 ? 'Request failed' : null,
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 503,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 408,
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
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
      print('DEBUG: API POST request to: $baseUrl$endpoint with body: $body');
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        body: json.encode(body),
        headers: _headers,
      ).timeout(_timeout);

      print('DEBUG: API POST response status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'data': responseData,
        'errorCode': responseData['errorCode'],
        'message': responseData['message'] ?? 'Unknown error occurred',
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 503,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 408,
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
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
      print('DEBUG: API PATCH request to: $baseUrl$endpoint with body: $body');
      final response = await _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        body: json.encode(body),
        headers: _headers,
      ).timeout(_timeout);

      print('DEBUG: API PATCH response status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      print('DEBUG: Response body: $responseData');
      return {
        'success': response.statusCode == 200 && (responseData['success'] ?? false),
        'errorCode': responseData['errorCode'],
        'message': responseData['message'] ?? 'Unknown error occurred',
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 503,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 408,
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      print('DEBUG: API DELETE request to: $baseUrl$endpoint');
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(_timeout);

      print('DEBUG: API DELETE response status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
        'data': responseData,
        'errorCode': response.statusCode != 200 && response.statusCode != 204 ? response.statusCode : null,
        'message': response.statusCode != 200 && response.statusCode != 204 ? 'Request failed' : null,
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 503,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 408,
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 400,
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
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
