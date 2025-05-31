import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

class ScannerService {
  final MobileScannerController controller = MobileScannerController();
  final StreamController<String> _scannedSerialController = StreamController<String>.broadcast();

  Stream<String> get onSerialScanned => _scannedSerialController.stream;

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

    // This should be used in a widget to actually start the scanning
    try {
      await controller.start();
      return "Scanning started"; // In reality, you'd handle the scan in the UI with a Completer
    } catch (e) {
      return null;
    }
  }

  void onBarcodeDetected(Barcode barcode) {
    if (barcode.rawValue != null) {
      final serialNumber = barcode.rawValue!;
      _scannedSerialController.add(serialNumber);
    }
  }

  void dispose() {
    controller.dispose();
    _scannedSerialController.close();
  }
}

