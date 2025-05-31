import 'package:mobile_scanner/mobile_scanner.dart';

class CameraService {
  MobileScannerController? _controller;
  bool _isInitialized = false;

  MobileScannerController get controller {
    if (_controller == null) {
      _controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isInitialized = true;
    }
    return _controller!;
  }

  void dispose() {
    if (_isInitialized) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  Future<void> restart() async {
    if (_isInitialized) {
      await _controller?.stop();
      await _controller?.start();
    }
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _controller?.stop();
    }
  }

  Future<void> start() async {
    if (_isInitialized) {
      await _controller?.start();
    }
  }
}
