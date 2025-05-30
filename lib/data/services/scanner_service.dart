import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerService {
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<String?> scanQR() async {
    // Simulated QR scan for demo
    return 'DEV-2024-001';
  }
}

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<ScannerService>(ScannerService());
}