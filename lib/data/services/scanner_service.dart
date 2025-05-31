import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  final MobileScannerController controller = MobileScannerController();

  Future<Map<String, dynamic>> requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return {'success': true};
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return {'success': true};
      }
    }

    if (status.isPermanentlyDenied) {
      return {
        'success': false,
        'error': {
          'title': 'Quyền camera bị từ chối',
          'message': 'Vui lòng cấp quyền camera trong cài đặt thiết bị để sử dụng chức năng quét QR.',
          'action': 'open_settings'
        }
      };
    }

    return {
      'success': false,
      'error': {
        'title': 'Không thể truy cập camera',
        'message': 'Quyền camera bị từ chối. Vui lòng thử lại.',
        'action': 'retry'
      }
    };
  }

  Future<String?> scanQR() async {
    final permissionResult = await requestCameraPermission();
    if (!permissionResult['success']) {
      return null;
    }

    return null;
  }

  void dispose() {
    controller.dispose();
  }
}

final getIt = GetIt.instance;


