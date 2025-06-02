import 'dart:async';
import 'dart:io';

import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_overlay.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/result_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../utils/di.dart';

class QRScannerScreen extends StatefulWidget {
  final String purpose;
  final VoidCallback onBack;

  const QRScannerScreen({super.key, required this.purpose, required this.onBack});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isDeviceSupported = false;
  bool _isScanning = true;
  bool _isSubmitting = false;
  final MobileScannerController _controller = MobileScannerController();
  late final ScannerBloc _scannerBloc;
  late final CameraService _cameraService;
  StreamSubscription<String>? _cameraErrorSubscription;
  Timer? _scanTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _scannerBloc = getIt<ScannerBloc>();
    _cameraService = getIt<CameraService>();
    _setupCameraErrorListener();
    _checkDeviceSupport();
    _startScanTimeout();
  }

  void _setupCameraErrorListener() {
    _cameraErrorSubscription = _cameraService.onCameraError.listen((errorMsg) {
      print("DEBUG: Camera error detected: $errorMsg");
      if (mounted) {
        setState(() => _isScanning = false);
        _handleCameraError("Camera hardware error detected. Please try again.");
      }
    });
  }

  void _handleCameraError(String message) {
    _scannerBloc.add(ResetScanner());
    _scannerBloc.add(ScanQR(widget.purpose, '', error: {
      'title': 'Lỗi camera',
      'message': message,
      'details': const {
        'errorCode': 'CAM-002',
        'reason': 'Camera hardware error',
        'actions': ['retry', 'dashboard']
      },
    }));
  }

  Future<void> _retryScanning() async {
    print("DEBUG: Attempting camera restart for retry");

    if (mounted) {
      // Don't stop the camera, just reset the scanning state
      setState(() {
        _isScanning = true;
        // Cancel existing timer if any
        _scanTimeoutTimer?.cancel();
        _startScanTimeout();
      });
      _scannerBloc.add(ResetScanner());
    }
  }

  Future<void> _checkDeviceSupport() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      bool isSupported = false;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        isSupported = androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        isSupported = iosInfo.isPhysicalDevice;
      }

      setState(() => _isDeviceSupported = isSupported);

      if (!isSupported) {
        _scannerBloc.add(ResetScanner());
        _scannerBloc.add(ScanQR(widget.purpose, '', error: const {
          'title': 'Thiết bị không hỗ trợ',
          'message': 'Thiết bị này không hỗ trợ quét QR. Vui lòng sử dụng thiết bị khác.',
          'details': {'errorCode': 'DEVICE-001', 'reason': 'No camera support', 'actions': ['dashboard']},
        }));
        setState(() => _isScanning = false);
      }
    } catch (e) {
      _scannerBloc.add(ResetScanner());
      _scannerBloc.add(ScanQR(widget.purpose, '', error: {
        'title': 'Lỗi thiết bị',
        'message': 'Không thể kiểm tra hỗ trợ thiết bị. Vui lòng thử lại.',
        'details': {'errorCode': 'DEVICE-002', 'reason': e.toString(), 'actions': const ['dashboard']},
      }));
      setState(() => _isScanning = false);
    }
  }

  void _startScanTimeout() {
    // Cancel existing timer if any
    _scanTimeoutTimer?.cancel();

    // Set a longer timeout (45 seconds)
    _scanTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _isScanning) {
        setState(() => _isScanning = false);
        // Don't stop the camera, just stop the scanning process
        _scannerBloc.add(ScanQR(widget.purpose, '', error: const {
          'title': 'Hết thời gian quét',
          'message': 'Không tìm thấy mã QR trong 45 giây. Vui lòng thử lại.',
          'details': {
            'errorCode': 'QR-003',
            'reason': 'Timeout',
            'actions': ['retry', 'dashboard']
          },
        }));
      }
    });
  }

  void _handleSubmit(String serial) {
    print("DEBUG: Submit action with serial: $serial");
    if (serial.isEmpty) {
      print("DEBUG: Serial string is empty, cannot submit");
      _scannerBloc.add(ResetScanner());
      setState(() => _isSubmitting = false);
      return;
    }

    setState(() => _isSubmitting = true);
    _scannerBloc.add(SubmitScan(serial, widget.purpose));
  }

  void _safePop() {
    print("DEBUG: _safePop called - navigating back to dashboard");

    // Cancel any active timer
    _scanTimeoutTimer?.cancel();

    // Make sure controller is stopped on navigation
    _controller.stop();

    // Reset scanner state before navigation
    _scannerBloc.add(ResetScanner());

    // First call the onBack callback to reset DashboardBloc state
    widget.onBack();

    // Then use Navigator to pop if possible
    if (Navigator.canPop(context)) {
      print("DEBUG: Popping navigator");
      Navigator.pop(context);
    } else {
      print("DEBUG: Can't pop navigator, using onBack callback only");
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (!_isScanning) return;  // Ignore detections when not in scanning mode

    final barcode = capture.barcodes.firstOrNull;

    if (barcode == null || barcode.rawValue == null || barcode.rawValue!.isEmpty) {
      _scannerBloc.add(ScanQR(widget.purpose, '', error: const {
        'title': 'Quét thất bại',
        'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
        'details': {
          'errorCode': 'QR-002',
          'reason': 'Invalid or empty QR code',
          'actions': ['retry', 'dashboard']
        },
      }));

      // Don't stop the camera, just stop the scanning process
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      });
      return;
    }

    // Cancel timeout timer since we detected a valid QR code
    _scanTimeoutTimer?.cancel();

    // Don't stop the camera, just stop the scanning process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });

    _scannerBloc.add(ScanQR(widget.purpose, barcode.rawValue!));
  }

  void _handleError(MobileScannerException error) {
    if (!_isScanning) return;

    _scannerBloc.add(ScanQR(widget.purpose, '', error: {
      'title': 'Lỗi camera',
      'message': 'Không thể truy cập camera. Vui lòng kiểm tra thiết bị.',
      'details': {
        'errorCode': 'CAM-001',
        'reason': error.toString(),
        'actions': const ['retry', 'dashboard']
      },
    }));

    // Don't stop the camera, just stop the scanning process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _controller.stop();
    _controller.dispose();
    _isScanning = false;
    _cameraErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle the back button press by navigating to the dashboard
        _safePop();
        // Return false to prevent default back behavior (exiting app)
        return false;
      },
      child: BlocProvider.value(
        value: _scannerBloc,
        child: Scaffold(
          body: Stack(
            children: [
              if (_isDeviceSupported && _isScanning)
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error, child) {
                    _handleError(error);
                    return const SizedBox.shrink();
                  },
                ),
              QROverlay(isScanning: _isScanning),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _safePop,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _getPurposeTitle(widget.purpose),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    _isScanning ? 'Đặt mã QR vào khung để quét' : 'Quét tạm dừng. Nhấn "Thử lại" đ�� tiếp tục.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              BlocBuilder<ScannerBloc, ScannerState>(
                bloc: _scannerBloc,
                builder: (context, state) {
                  if (state is ScannerSuccess) {
                    final Map<String, dynamic> details = Map<String, dynamic>.from(state.result['details']);
                    final actions = state.result['actions'] as List<dynamic>? ?? [];
                    final serial = details.containsKey('device_serial') ? details['device_serial'].toString() : '';

                    print("DEBUG: Showing success dialog with actions: $actions");
                    print("DEBUG: Success details: $details");

                    return ResultDialog(
                      type: 'success',
                      title: state.result['title'] as String,
                      message: state.result['message'] as String,
                      details: details.map((key, value) => MapEntry(key, value.toString())),
                      actions: actions.map((e) => e.toString()).toList(),
                      isLoading: _isSubmitting,
                      onSubmit: actions.contains('submit')
                          ? () {
                              print("DEBUG: Submit button pressed with serial: $serial");
                              _handleSubmit(serial);
                            }
                          : null,
                      onRetry: actions.contains('retry')
                          ? () {
                              print("DEBUG: Retry button pressed");
                              _retryScanning();
                            }
                          : null,
                      onDashboard: actions.contains('dashboard')
                          ? () {
                              print("DEBUG: Dashboard button pressed");
                              _safePop();
                            }
                          : null,
                      onClose: () {
                        print("DEBUG: Dialog close button pressed - restarting scanner");
                        // When dialog is dismissed, restart scanning like retry button
                        _retryScanning();
                      },
                    );
                  } else if (state is ScannerFailure) {
                    final Map<String, dynamic> details = Map<String, dynamic>.from(state.error['details'] ?? {});
                    final actions = state.error['actions'] as List<dynamic>? ?? [];
                    final serial = details.containsKey('device_serial') ? details['device_serial'].toString() : '';

                    print("DEBUG: Showing failure dialog with actions: $actions");

                    return ResultDialog(
                      type: 'error',
                      title: state.error['title'] as String,
                      message: state.error['message'] as String,
                      details: details.map((key, value) => MapEntry(key, value.toString())),
                      actions: actions.map((e) => e.toString()).toList(),
                      isLoading: _isSubmitting,
                      onSubmit: actions.contains('submit')
                          ? () {
                              print("DEBUG: Submit button pressed with serial: $serial");
                              _handleSubmit(serial);
                            }
                          : null,
                      onRetry: actions.contains('retry')
                          ? () {
                              print("DEBUG: Retry button pressed");
                              _retryScanning();
                            }
                          : null,
                      onDashboard: actions.contains('dashboard')
                          ? () {
                              print("DEBUG: Dashboard button pressed");
                              _safePop();
                            }
                          : null,
                      onClose: () {
                        print("DEBUG: Dialog close button pressed - restarting scanner");
                        // When dialog is dismissed, restart scanning like retry button
                        _retryScanning();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPurposeTitle(String purpose) {
    const titles = {
      'identify': 'Quét để xác định thiết bị',
      'firmware': 'Quét để cập nhật Firmware',
      'testing': 'Quét để kiểm tra thiết bị',
      'packaging': 'Quét để đóng gói thiết bị',
      'stockin': 'Quét để nhập kho',
      'stockout': 'Quét để xuất kho',
    };
    return titles[purpose] ?? 'Quét mã QR';
  }
}

