import 'package:smart_net_qr_scanner/data/models/user.dart';

class AuthService {
  User? _user;

  Future<bool> login(String username, String password, bool remember) async {
    if (username.isNotEmpty && password.isNotEmpty) {
      _user = User(name: username, role: 'Production Technician', department: 'Manufacturing');
      if (remember) {
        // Simulate local storage
      }
      return true;
    }
    return false;
  }

  User? get user => _user;
}

