import 'package:firmware_deployment_tool/data/models/user.dart';
import 'package:get_it/get_it.dart';

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

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<AuthService>(AuthService());
}