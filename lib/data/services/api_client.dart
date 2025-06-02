import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Base URL - Only using ngrok
  static const String _ngrokUrl = 'https://c3e7-171-250-162-57.ngrok-free.app/api';
  static String _baseUrl = _ngrokUrl;

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) {
    print('DEBUG: Setting API base URL to: $url');
    _baseUrl = url;
    // Try to save the setting, but don't block the app if it fails
    saveCurrentBaseUrl().catchError((e) =>
      print('DEBUG: Non-blocking error saving URL preference: $e')
    );
  }

  final http.Client _client;
  final Duration _timeout;

  ApiClient({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 30);

  // Initialize the API client - Now only using ngrok URL
  static Future<void> initializeBaseUrl() async {
    // Always use ngrok URL
    _baseUrl = _ngrokUrl;
    print('DEBUG: Using ngrok API URL: $_baseUrl');

    // Try to save the setting for next time
    try {
      await saveCurrentBaseUrl();
    } catch (e) {
      print('DEBUG: Non-blocking error saving URL preference: $e');
    }
  }

  // Save the current base URL for future use
  static Future<void> saveCurrentBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', _baseUrl);
      print('DEBUG: Saved API URL preference: $_baseUrl');
    } catch (e) {
      print('DEBUG: Failed to save API URL preference: $e');
    }
  }

  // Set the API endpoint to a specific URL and save the preference
  static Future<void> setApiEndpoint(String url) async {
    _baseUrl = url;
    await saveCurrentBaseUrl();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
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

      if (response.body.isEmpty) {
        return {
          'success': false,
          'errorCode': 'EMPTY_RESPONSE',
          'message': 'Server returned an empty response',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        return {
          'success': false,
          'errorCode': 'PARSE_ERROR',
          'message': 'Failed to parse server response',
          'details': response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body,
        };
      }

      return {
        'success': response.statusCode == 200,
        'data': responseData,
        'errorCode': response.statusCode != 200 ? response.statusCode.toString() : null,
        'message': response.statusCode != 200 ? _getErrorMessage(response) : null,
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'FORMAT_ERROR',
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${e.toString()}',
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

      if (response.body.isEmpty) {
        return {
          'success': false,
          'errorCode': 'EMPTY_RESPONSE',
          'message': 'Server returned an empty response',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        return {
          'success': false,
          'errorCode': 'PARSE_ERROR',
          'message': 'Failed to parse server response',
          'details': response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body,
        };
      }

      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'data': responseData,
        'errorCode': responseData['errorCode'] ?? (response.statusCode != 200 && response.statusCode != 201 ? response.statusCode.toString() : null),
        'message': responseData['message'] ?? _getErrorMessage(response),
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'FORMAT_ERROR',
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${e.toString()}',
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

      if (response.body.isEmpty) {
        return {
          'success': false,
          'errorCode': 'EMPTY_RESPONSE',
          'message': 'Server returned an empty response',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
        print('DEBUG: Response body: $responseData');
      } catch (e) {
        return {
          'success': false,
          'errorCode': 'PARSE_ERROR',
          'message': 'Failed to parse server response',
          'details': response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body,
        };
      }

      return {
        'success': response.statusCode == 200 && (responseData['success'] ?? false),
        'data': responseData['data'],
        'errorCode': responseData['errorCode'] ?? (response.statusCode != 200 ? response.statusCode.toString() : null),
        'message': responseData['message'] ?? _getErrorMessage(response),
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'FORMAT_ERROR',
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${e.toString()}',
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

      if (response.body.isEmpty && response.statusCode != 204) {
        return {
          'success': response.statusCode == 204, // No content can be successful for DELETE
          'errorCode': response.statusCode != 204 ? 'EMPTY_RESPONSE' : null,
          'message': response.statusCode != 204 ? 'Server returned an empty response' : null,
        };
      }

      Map<String, dynamic> responseData = {};
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          return {
            'success': false,
            'errorCode': 'PARSE_ERROR',
            'message': 'Failed to parse server response',
            'details': response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body,
          };
        }
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
        'data': responseData,
        'errorCode': response.statusCode != 200 && response.statusCode != 204 ? response.statusCode.toString() : null,
        'message': response.statusCode != 200 && response.statusCode != 204 ? _getErrorMessage(response) : null,
      };
    } on SocketException catch (e) {
      print('DEBUG: API connection error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      print('DEBUG: API timeout error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } on FormatException catch (e) {
      print('DEBUG: API format error: ${e.message}');
      return {
        'success': false,
        'errorCode': 'FORMAT_ERROR',
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } catch (e) {
      print('DEBUG: API unexpected error: $e');
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${e.toString()}',
      };
    }
  }

  String _getErrorMessage(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ';
      case 401:
        return 'Không được phép truy cập';
      case 403:
        return 'Truy cập bị từ chối';
      case 404:
        return 'Không tìm thấy tài nguyên yêu cầu';
      case 500:
        return 'Lỗi máy chủ nội bộ';
      default:
        return 'Lỗi HTTP: ${response.statusCode}';
    }
  }

  void dispose() {
    _client.close();
  }
}
