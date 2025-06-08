import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class AuthService {
  final ApiClient _apiClient = getIt<ApiClient>();
  User? _user;

  Future<bool> login(String username, String password, bool remember) async {
    try {
      final response = await _apiClient.login(username, password);

      if (response['success']) {
        // Set user info
        _user = User(
          name: username,
          role: 'Production Technician', // This should come from API in the future
          department: 'Manufacturing'     // This should come from API in the future
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<String?> getUsername() => _apiClient.getUsername();

  User? get user => _user;
}
