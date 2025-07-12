import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:get_it/get_it.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _usernameKey = 'username';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final apiClient = GetIt.instance<ApiClient>();
      final response = await apiClient.post('/auth/employee/login', {
        'username': username,
        'password': password,
      });

      print('DEBUG: Login API full response: $response');

      // Handle successful API call first
      if (response['success'] == true && response['data'] != null) {
        // This handles wrapper format: { success: true, data: { accessToken, employeeId } }
        final data = response['data'];
        if (data['accessToken'] != null && data['employeeId'] != null) {
          final token = data['accessToken'];
          final employeeId = data['employeeId'];

          final userData = {
            'employeeId': employeeId,
            'username': username,
            'name': employeeId,
            'role': 'Admin',
            'department': 'IT',
          };

          await _saveAuthData(token, userData, username);
          return userData;
        }
      }

      // Handle direct response format: { accessToken, employeeId, refreshToken }
      else if (response['data'] != null) {
        final data = response['data'];
        if (data['accessToken'] != null && data['employeeId'] != null) {
          final token = data['accessToken'];
          final employeeId = data['employeeId'];

          final userData = {
            'employeeId': employeeId,
            'username': username,
            'name': employeeId,
            'role': 'Admin',
            'department': 'IT',
          };

          await _saveAuthData(token, userData, username);
          return userData;
        }
      }

      // Log the specific error if available
      if (response['success'] == false) {
        print('DEBUG: Login failed with API error: ${response['message']}');
      } else {
        print('DEBUG: Login failed - unexpected response format');
      }

      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setString(_usernameKey, username);
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_usernameKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final apiClient = GetIt.instance<ApiClient>();
      final response = await apiClient.get('/auth/validate');

      return response['success'] == true;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }
}