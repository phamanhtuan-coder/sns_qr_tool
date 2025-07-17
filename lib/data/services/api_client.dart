import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Base URLs
  static const String _railwayUrl = 'https://iothomeconnectapiv2-production.up.railway.app/api';
  static const String _snsEcomUrl = 'https://sns-e-com-backend.up.railway.app/api';
  static String _baseUrl = _railwayUrl;

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) {
    print('DEBUG: Setting API base URL to: $url');
    _baseUrl = url;
    // Try to save the setting, but don't block the app if it fails
    saveCurrentBaseUrl().catchError((e) =>
      print('DEBUG: Non-blocking error saving URL preference: $e')
    );
  }

  // Get the appropriate base URL for different API endpoints
  static String _getUrlForEndpoint(String endpoint) {
    // Use SNS E-com backend for warehouse and stock operations
    if (endpoint.startsWith('/warehouse/') ||
        endpoint.startsWith('/import-warehouse') ||
        endpoint.startsWith('/export-warehouse') ||
        endpoint.startsWith('/stockin') ||
        endpoint.startsWith('/stockout') ||
        endpoint.startsWith('/stock') ||
        endpoint.startsWith('/delivery') ||
        endpoint.startsWith('/order') ||
        endpoint.startsWith('/shipper')) {
      print('DEBUG: Using SNS E-com URL for endpoint: $endpoint');
      return _snsEcomUrl;
    }

    // Use Railway URL for all other APIs (auth, production tracking, etc.)
    print('DEBUG: Using Railway URL for endpoint: $endpoint');
    return _railwayUrl;
  }

  final http.Client _client;
  final Duration _timeout;

  ApiClient({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10); // Reduced timeout

  // Initialize the API client - Now using both URLs
  static Future<void> initializeBaseUrl() async {
    // Default to Railway URL
    _baseUrl = _railwayUrl;
    print('DEBUG: Initialized with Railway API URL: $_baseUrl');
    print('DEBUG: SNS E-com URL available: $_snsEcomUrl');

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

  static const String _userPrefKey = 'user_username';
  static const String _tokenPrefKey = 'access_token';

  // Get the stored access token
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenPrefKey);
    } catch (e) {
      print('DEBUG: Error getting access token: $e');
      return null;
    }
  }

  // Make a logout request to the server
  Future<bool> logout() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        print('DEBUG: No token found for logout');
        return true; // Consider it successful if there's no token to invalidate
      }

      // Use the appropriate URL for logout endpoint
      final targetUrl = _getUrlForEndpoint('/auth/employee/logout');
      final url = Uri.parse('$targetUrl/auth/employee/logout');
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      print('DEBUG: Logout response status: ${response.statusCode}');
      return response.statusCode == 204;
    } catch (e) {
      print('DEBUG: Error during logout request: $e');
      return false;
    }
  }

  // Store access token
  Future<void> setAccessToken(String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenPrefKey);
        print('DEBUG: Access token removed from storage');
      } else {
        await prefs.setString(_tokenPrefKey, token);
        print('DEBUG: Access token stored successfully');
      }
    } catch (e) {
      print('DEBUG: Error managing access token in storage: $e');
    }
  }

  // Store username
  Future<void> setUsername(String? username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (username == null) {
        await prefs.remove(_userPrefKey);
        print('DEBUG: Username removed from storage');
      } else {
        await prefs.setString(_userPrefKey, username);
        print('DEBUG: Username stored successfully');
      }
    } catch (e) {
      print('DEBUG: Error managing username in storage: $e');
    }
  }

  // Get stored username
  Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userPrefKey);
    } catch (e) {
      print('DEBUG: Error getting username: $e');
      return null;
    }
  }

  // Get headers with authorization if token exists
  Future<Map<String, String>> get headers async {
    final baseHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await getAccessToken();
    if (token != null) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }

    return baseHeaders;
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }

  Future<Map<String, dynamic>> _handleRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        print('DEBUG: API error status ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Lỗi máy chủ, vui lòng thử lại sau',
        };
      }
    } on TimeoutException {
      print('DEBUG: API request timed out');
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ, vui lòng kiểm tra kết nối mạng',
      };
    } on SocketException {
      print('DEBUG: Network connection error');
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ, vui lòng kiểm tra kết nối mạng',
      };
    } catch (e) {
      print('DEBUG: Unexpected API error: $e');
      return {
        'success': false,
        'message': 'Có lỗi xảy ra, vui lòng thử lại',
      };
    }
  }

  void _logApiCall(String method, String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    dynamic response,
    String? error,
  }) {
    print('\n');
    print('🔷🔷🔷🔷🔷🔷🔷🔷 API CALL START 🔷🔷🔷🔷🔷🔷🔷🔷');
    print('📍 Time: ${DateTime.now().toString()}');
    print('🌐 URL: ${_getUrlForEndpoint(endpoint)}$endpoint');
    print('🔧 Method: $method');

    if (headers != null) {
      print('\n📋 Headers:');
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          print('  $key: Bearer ${value.substring(7, min(27, value.length))}...');
        } else {
          print('  $key: $value');
        }
      });
    }

    if (body != null) {
      print('\n📦 Request Body:');
      _prettyPrintJson(body);
    }

    if (response != null) {
      if (response is http.Response) {
        print('\n📥 Response Status: ${response.statusCode}');
        print('\n📥 Response Headers:');
        response.headers.forEach((key, value) {
          print('  $key: $value');
        });

        print('\n📥 Response Body:');
        try {
          final decodedBody = json.decode(response.body);
          _prettyPrintJson(decodedBody);
        } catch (e) {
          print('  Raw: ${response.body}');
          print('  (Could not parse as JSON: $e)');
        }
      } else {
        print('\n📥 Response (non-HTTP): $response');
      }
    }

    if (error != null) {
      print('\n❌ Error: $error');
      print('❌ Stack Trace:');
      try {
        throw Exception();
      } catch (e, stackTrace) {
        print(stackTrace.toString().split('\n').take(3).join('\n'));
      }
    }

    print('🔷🔷🔷🔷🔷🔷🔷🔷 API CALL END 🔷🔷🔷🔷🔷🔷🔷🔷\n');
  }

  void _prettyPrintJson(dynamic json) {
    const indent = '  ';
    final encoder = JsonEncoder.withIndent(indent);
    try {
      print(encoder.convert(json).split('\n').map((line) => '  $line').join('\n'));
    } catch (e) {
      print('  $json');
      print('  (Could not pretty print: $e)');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final currentHeaders = await headers;
      final targetUrl = _getUrlForEndpoint(endpoint);
      
      _logApiCall('GET', endpoint, headers: currentHeaders);

      final response = await _client.get(
        Uri.parse('$targetUrl$endpoint'),
        headers: currentHeaders,
      ).timeout(_timeout);

      _logApiCall('GET', endpoint, 
        headers: currentHeaders,
        response: response
      );

      if (response.body.isEmpty) {
        _logApiCall('GET', endpoint, error: 'Empty response body');
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
        _logApiCall('GET', endpoint, error: 'Failed to parse response: $e');
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
    } catch (e) {
      _logApiCall('GET', endpoint, error: e.toString());
      return _handleApiError(e);
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final currentHeaders = await headers;
      final targetUrl = _getUrlForEndpoint(endpoint);
      
      _logApiCall('POST', endpoint, 
        headers: currentHeaders,
        body: body
      );

      final response = await _client.post(
        Uri.parse('$targetUrl$endpoint'),
        body: json.encode(body),
        headers: currentHeaders,
      ).timeout(_timeout);

      _logApiCall('POST', endpoint, 
        headers: currentHeaders,
        body: body,
        response: response
      );

      if (response.body.isEmpty) {
        _logApiCall('POST', endpoint, error: 'Empty response body');
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
        _logApiCall('POST', endpoint, error: 'Failed to parse response: $e');
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
    } catch (e) {
      _logApiCall('POST', endpoint, error: e.toString());
      return _handleApiError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final currentHeaders = await headers;
      final targetUrl = _getUrlForEndpoint(endpoint);
      print('DEBUG: API PATCH request to: $targetUrl$endpoint with body: $body');

      final response = await _client.patch(
        Uri.parse('$targetUrl$endpoint'),
        body: json.encode(body),
        headers: currentHeaders,
      ).timeout(_timeout);

      print('DEBUG: API PATCH response status: ${response.statusCode}');
      print('DEBUG: API PATCH response body: ${response.body}');

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
        };
      }

      // Handle different response structures
      bool isSuccess = false;
      if (response.statusCode == 200) {
        // Check for success field first, then status_code
        if (responseData.containsKey('success')) {
          isSuccess = responseData['success'] == true;
        } else if (responseData.containsKey('status_code')) {
          isSuccess = responseData['status_code'] == 200;
        } else {
          isSuccess = true; // Default to success for 200 status
        }
      }

      return {
        'success': isSuccess,
        'data': responseData['data'] ?? responseData,
        'errorCode': !isSuccess ? (responseData['errorCode'] ?? response.statusCode.toString()) : null,
        'message': !isSuccess ? (responseData['message'] ?? _getErrorMessage(response)) : null,
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } catch (e) {
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${e.toString()}',
      };
    }
  }
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final currentHeaders = await headers;
      final targetUrl = _getUrlForEndpoint(endpoint);
      print('DEBUG: API DELETE request to: $targetUrl$endpoint');
      print('DEBUG: DELETE Request Headers: $currentHeaders');
      print('DEBUG: DELETE Authorization Header: ${currentHeaders['Authorization'] ?? 'MISSING'}');

      final response = await _client.delete(
        Uri.parse('$targetUrl$endpoint'),
        headers: currentHeaders,
      ).timeout(_timeout);

      print('DEBUG: API DELETE response status: ${response.statusCode}');
      print('DEBUG: API DELETE response headers: ${response.headers}');
      print('DEBUG: API DELETE response body: ${response.body}');

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

  Map<String, dynamic> _handleApiError(dynamic error) {
    if (error is SocketException) {
      return {
        'success': false,
        'errorCode': 'NETWORK_ERROR',
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    } else if (error is TimeoutException) {
      return {
        'success': false,
        'errorCode': 'TIMEOUT',
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } else if (error is FormatException) {
      return {
        'success': false,
        'errorCode': 'FORMAT_ERROR',
        'message': 'Định dạng phản hồi không hợp lệ.',
      };
    } else {
      return {
        'success': false,
        'errorCode': 'UNKNOWN_ERROR',
        'message': 'Đã xảy ra lỗi không xác định: ${error.toString()}',
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

  // Debug method to check token storage and retrieval
  Future<void> debugTokenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenPrefKey);
      final username = prefs.getString(_userPrefKey);

      print('DEBUG: ========== TOKEN DEBUG INFO ==========');
      print('DEBUG: Token exists: ${token != null}');
      print('DEBUG: Token length: ${token?.length ?? 0}');
      print('DEBUG: Token preview: ${token != null ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'NULL'}');
      print('DEBUG: Username: $username');
      print('DEBUG: Storage keys checked: $_tokenPrefKey, $_userPrefKey');
      print('DEBUG: =====================================');
    } catch (e) {
      print('DEBUG: Error in debugTokenInfo: $e');
    }
  }

  // Add utilities for parsing response data
  T? getResponseData<T>(Map<String, dynamic> response, String key) {
    try {
      return response['data']?[key] as T?;
    } catch (e) {
      print('DEBUG: Error parsing response data for key $key: $e');
      return null;
    }
  }

  List<T>? getResponseList<T>(Map<String, dynamic> response, String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final list = response['data']?[key] as List?;
      return list?.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DEBUG: Error parsing response list for key $key: $e');
      return null;
    }
  }

  void debugPrintResponse(Map<String, dynamic> response) {
    print('\n=== API Response Debug Info ===');
    print('Success: ${response['success']}');
    print('Error Code: ${response['errorCode']}');
    print('Message: ${response['message']}');
    print('Data: ${response['data']}');
    print('===========================\n');
  }
}
