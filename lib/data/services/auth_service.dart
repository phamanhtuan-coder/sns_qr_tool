import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class AuthService {
  final ApiClient _apiClient = getIt<ApiClient>();
  User? _user;
  final http.Client _client;
  final Duration _timeout;
  Timer? _tokenExpiryTimer;

  // Stream controller for token expiration events
  final StreamController<bool> _tokenExpiryStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get tokenExpiryStream => _tokenExpiryStreamController.stream;

  AuthService({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15) {
    print('DEBUG: AuthService initialized');
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    print('DEBUG: AuthService.login called with username: $username');
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/auth/employee/login');
      print('DEBUG: Attempting login at URL: $url');

      final response = await _client.post(
        url,
        headers: _getDefaultHeaders(),
        body: json.encode({'username': username, 'password': password}),
      ).timeout(_timeout);

      print('DEBUG: Login response status: ${response.statusCode}, Body length: ${response.body.length}');

      // First check for status code to determine success
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body);
          print('DEBUG: Successfully parsed response body: $responseData');
        } catch (e) {
          print('DEBUG: Error parsing response body: $e');
          return {
            'success': false,
            'message': 'Lỗi định dạng phản hồi từ máy chủ',
          };
        }

        // Extract the accessToken directly from the response
        final accessToken = responseData['accessToken'];
        if (accessToken == null) {
          print('DEBUG: No access token in response');
          return {
            'success': false,
            'message': 'Không nhận được mã xác thực',
          };
        }

        print('DEBUG: Got access token, storing credentials');

        // Save the access token
        await _apiClient.setAccessToken(accessToken);

        // Always store the username for the current session
        await _apiClient.setUsername(username);

        try {
          // Decode the JWT token to get user info and expiration
          final parts = accessToken.split('.');
          if (parts.length != 3) {
            throw FormatException('Invalid JWT token format');
          }

          final payload = parts[1];
          final normalizedPayload = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalizedPayload));
          final decodedPayload = json.decode(decoded);

          print('DEBUG: Decoded JWT payload: $decodedPayload');

          // Set up token expiration timer if exp claim exists
          if (decodedPayload.containsKey('exp')) {
            _setupTokenExpiryTimer(decodedPayload['exp']);
          }

          // Extract user info from token
          _user = User(
            name: decodedPayload['username'] ?? username,
            role: _getRoleName(decodedPayload['role'] ?? 1),
            department: _getDepartment(decodedPayload['role'] ?? 1),
          );

          print('DEBUG: Created user object: $_user');
          return {
            'success': true,
            'user': _user,
          };
        } catch (e) {
          // If token decoding fails, create a basic user
          print('DEBUG: Failed to decode token, creating basic user: $e');
          _user = User(
            name: username,
            role: 'Nhân viên',
            department: 'Chưa xác định',
          );

          return {
            'success': true,
            'user': _user,
          };
        }
      } else {
        // Handle error cases
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? _getErrorMessage(response.statusCode);
        } catch (e) {
          errorMessage = _getErrorMessage(response.statusCode);
        }

        print('DEBUG: Login failed with status ${response.statusCode}: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on TimeoutException {
      print('DEBUG: Login request timed out');
      return {
        'success': false,
        'message': 'Yêu cầu hết thời gian. Vui lòng thử lại sau.',
      };
    } catch (e) {
      print('DEBUG: Login error: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      };
    }
  }

  // Set up a timer to notify when the token is about to expire
  void _setupTokenExpiryTimer(int expiryTimestamp) {
    // Cancel any existing timer
    _tokenExpiryTimer?.cancel();

    // Convert unix timestamp to DateTime
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
    final now = DateTime.now();

    // Calculate time until token expires
    final timeUntilExpiry = expiryDateTime.difference(now);

    // Calculate warning time (5 minutes before expiry)
    final warningDuration = Duration(minutes: 5);
    final timeUntilWarning = timeUntilExpiry - warningDuration;

    print('DEBUG: Token expires in ${timeUntilExpiry.inMinutes} minutes');

    // Only set up timer if token expiry is in the future and more than 5 minutes away
    if (timeUntilWarning.isNegative) {
      // Token is already expired or about to expire
      print('DEBUG: Token is already near expiry');
      _tokenExpiryStreamController.add(true);
    } else {
      // Set timer to warn before token expires
      print('DEBUG: Setting token expiry warning timer for ${timeUntilWarning.inMinutes} minutes from now');
      _tokenExpiryTimer = Timer(timeUntilWarning, () {
        print('DEBUG: Token expiring soon, notifying listeners');
        _tokenExpiryStreamController.add(true);
      });
    }
  }

  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400: return 'Yêu cầu không hợp lệ';
      case 401: return 'Tên đăng nhập hoặc mật khẩu không chính xác';
      case 403: return 'Truy cập bị từ chối';
      case 404: return 'Không tìm thấy tài nguyên yêu cầu';
      case 500: return 'Lỗi máy chủ nội bộ';
      default: return 'Lỗi không xác định (mã $statusCode)';
    }
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 1: return 'Quản trị viên';
      case 2: return 'Quản lý';
      case 3: return 'Nhân viên kỹ thuật';
      default: return 'Nhân viên';
    }
  }

  String _getDepartment(int roleId) {
    switch (roleId) {
      case 1: return 'Ban điều hành';
      case 2: return 'Quản lý sản xuất';
      case 3: return 'Phòng kỹ thuật';
      default: return 'Sản xuất';
    }
  }

  /// Gets the stored username if both username and token exist
  Future<String?> getUsername() async {
    try {
      final username = await _apiClient.getUsername();
      final token = await _apiClient.getAccessToken();

      print('DEBUG: AuthService checking stored credentials - Username: $username, Has token: ${token != null}');

      // Only return username if both username and token exist
      if (username != null && token != null) {
        // Check if token is expired
        if (await isTokenExpired(token)) {
          print('DEBUG: Stored token is expired');
          await logout();
          return null;
        }

        // Attempt to restore the user object from the token if needed
        if (_user == null && token.isNotEmpty) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalizedPayload = base64Url.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalizedPayload));
              final decodedPayload = json.decode(decoded);

              // Set up token expiry timer
              if (decodedPayload.containsKey('exp')) {
                _setupTokenExpiryTimer(decodedPayload['exp']);
              }

              _user = User(
                name: decodedPayload['username'] ?? username,
                role: _getRoleName(decodedPayload['role'] ?? 1),
                department: _getDepartment(decodedPayload['role'] ?? 1),
              );

              print('DEBUG: Restored user from stored token: $_user');
            }
          } catch (e) {
            print('DEBUG: Failed to restore user from token: $e');
          }
        }
        return username;
      }

      // If either is missing, clear both to maintain consistency
      if (username != null || token != null) {
        await logout();
        print('DEBUG: Cleared inconsistent credentials');
      }

      return null;
    } catch (e) {
      print('DEBUG: Error getting stored credentials: $e');
      return null;
    }
  }

  /// Check if a token is expired
  Future<bool> isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final decodedPayload = json.decode(decoded);

      if (!decodedPayload.containsKey('exp')) return false;

      final expiryTimestamp = decodedPayload['exp'] as int;
      final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);

      return DateTime.now().isAfter(expiryDateTime);
    } catch (e) {
      print('DEBUG: Error checking token expiration: $e');
      return true; // Assume expired if we can't verify
    }
  }

  /// Log the user out by clearing stored credentials
  Future<void> logout() async {
    print('DEBUG: AuthService.logout called');
    try {
      // Call server logout endpoint first
      final logoutSuccessful = await _apiClient.logout();
      print('DEBUG: Server logout ${logoutSuccessful ? 'successful' : 'failed'}');

      // Clear token expiry timer
      _tokenExpiryTimer?.cancel();
      _tokenExpiryTimer = null;

      // Clear stored credentials
      await _apiClient.setAccessToken(null);
      await _apiClient.setUsername(null);

      // Clear user data
      _user = null;

      print('DEBUG: Local logout completed');
    } catch (e) {
      print('DEBUG: Error during logout: $e');
      // Still clear local data even if server request fails
      _tokenExpiryTimer?.cancel();
      _tokenExpiryTimer = null;
      await _apiClient.setAccessToken(null);
      await _apiClient.setUsername(null);
      _user = null;
    }
  }

  /// Get the currently authenticated user
  User? get user => _user;

  /// Cleanup resources
  void dispose() {
    _tokenExpiryTimer?.cancel();
    _tokenExpiryStreamController.close();
    _client.close();
  }
}
