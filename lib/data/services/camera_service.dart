import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'package:firmware_deployment_tool/utils/logger.dart';

class CameraService {
  MobileScannerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  // Stream to broadcast camera errors
  final StreamController<String> _errorStreamController = StreamController<String>.broadcast();
  Stream<String> get onCameraError => _errorStreamController.stream;

  MobileScannerController get controller {
    if (_controller == null || _hasError) {
      _resetController();
    }
    return _controller!;
  }

  void _resetController() {
    try {
      // Properly dispose of old controller if it exists
      if (_controller != null) {
        _controller!.dispose();
      }

      _controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isInitialized = true;
      _hasError = false;
    } catch (e) {
      _hasError = true;
      _errorStreamController.add("Failed to initialize camera: $e");
      logError("Camera initialization failed", e);
    }
  }

  Future<bool> reset() async {
    try {
      _resetController();
      await Future.delayed(const Duration(milliseconds: 300)); // Small delay for camera to stabilize
      return true;
    } catch (e) {
      _hasError = true;
      _errorStreamController.add("Failed to reset camera: $e");
      logError("Camera reset failed", e);
      return false;
    }
  }

  void dispose() {
    try {
      if (_isInitialized && _controller != null) {
        _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      logError("Error disposing camera", e);
    } finally {
      _isInitialized = false;
      _errorStreamController.close();
    }
  }

  Future<bool> restart() async {
    try {
      if (_hasError) {
        return await reset();
      }

      if (_isInitialized && _controller != null) {
        await _controller!.stop();
        await Future.delayed(const Duration(milliseconds: 300)); // Small delay between operations
        await _controller!.start();
        return true;
      }
      return false;
    } catch (e) {
      _hasError = true;
      _errorStreamController.add("Camera restart failed: $e");
      logError("Camera restart failed", e);
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      if (_isInitialized && _controller != null && !_hasError) {
        await _controller!.stop();
        return true;
      }
      return false;
    } catch (e) {
      _hasError = true;
      _errorStreamController.add("Camera stop failed: $e");
      logError("Camera stop failed", e);
      return false;
    }
  }

  Future<bool> start() async {
    try {
      if (_hasError) {
        return await reset();
      }

      if (_isInitialized && _controller != null) {
        await _controller!.start();
        return true;
      }
      return false;
    } catch (e) {
      _hasError = true;
      _errorStreamController.add("Camera start failed: $e");
      logError("Camera start failed", e);
      return false;
    }
  }
}
