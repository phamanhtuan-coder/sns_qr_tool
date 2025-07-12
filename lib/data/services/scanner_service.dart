import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';
import 'dart:async';

class ScannerService {
  final MobileScannerController controller = MobileScannerController();
  final StreamController<QrData> _scannedDataController = StreamController<QrData>.broadcast();

  Stream<QrData> get onQrDataScanned => _scannedDataController.stream;

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
      final qrRawData = barcode.rawValue!;
      print('DEBUG: Raw QR data: $qrRawData');

      // Parse the QR data (handles both JSON format and legacy string format)
      final qrData = QrData.fromJsonString(qrRawData);
      print('DEBUG: Parsed QR data: $qrData');

      _scannedDataController.add(qrData);
    }
  }

  void dispose() {
    controller.dispose();
    _scannedDataController.close();
  }
}
