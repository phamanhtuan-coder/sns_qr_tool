import 'dart:async';
import 'dart:io';

import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_overlay.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/result_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../utils/di.dart';

class QRScannerScreen extends StatefulWidget {
  final String purpose;
  final VoidCallback onBack;

  const QRScannerScreen({super.key, required this.purpose, required this.onBack});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with TickerProviderStateMixin {
  bool _isDeviceSupported = false;
  bool _isScanning = true;
  bool _isSubmitting = false;
  bool _isProcessingQR = false;
  String? _lastScannedCode;
  Timer? _scanCooldownTimer;
  final MobileScannerController _controller = MobileScannerController();
  late final ScannerBloc _scannerBloc;
  late final CameraService _cameraService;
  StreamSubscription<String>? _cameraErrorSubscription;
  Timer? _scanTimeoutTimer;

  // Animation controllers
  late AnimationController _successAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;
  late Animation<double> _pulseAnimation;
  bool _showSuccessAnimation = false;

  // Scanning delay constants
  static const Duration _scanCooldown = Duration(milliseconds: 800);
  static const Duration _processingDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _scannerBloc = getIt<ScannerBloc>();
    _cameraService = getIt<CameraService>();

    // Get arguments from route after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final orderId = args?['order_id'] as String?;
      final exportId = args?['export_id'] as String?;

      if (orderId != null) {
        if (exportId != null) {
          _scannerBloc.add(SetExportId(exportId, orderId));
        } else {
          _scannerBloc.add(SetOrderId(orderId));
        }
      }
    });

    _setupAnimations();
    _setupCameraErrorListener();
    _checkDeviceSupport();
    _startScanTimeout();
  }

  void _setupAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));

    _successOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
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
      setState(() {
        _isScanning = true;
        _isProcessingQR = false;
        _showSuccessAnimation = false;
        _lastScannedCode = null;
        _isSubmitting = false; // Reset submitting state
      });

      _successAnimationController.reset();
      _pulseAnimationController.stop();

      _scanTimeoutTimer?.cancel();
      _scanCooldownTimer?.cancel();

      _startScanTimeout();
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
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _isScanning) {
        setState(() => _isScanning = false);
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

    _scanTimeoutTimer?.cancel();
    _scanCooldownTimer?.cancel();

    _successAnimationController.dispose();
    _pulseAnimationController.dispose();

    _controller.stop();

    _scannerBloc.add(ResetScanner());

    widget.onBack();
    Navigator.of(context).pop();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (!_isScanning || _isProcessingQR) return;

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      });
      return;
    }

    final scannedCode = barcode.rawValue!;

    if (_lastScannedCode == scannedCode) {
      print("DEBUG: Duplicate QR code detected, ignoring: $scannedCode");
      return;
    }

    if (_scanCooldownTimer?.isActive == true) {
      print("DEBUG: Scan cooldown active, ignoring detection");
      return;
    }

    print("DEBUG: QR code detected: $scannedCode");

    setState(() {
      _isProcessingQR = true;
      _lastScannedCode = scannedCode;
    });

    _showSuccessDetection();

    Timer(_processingDelay, () {
      if (mounted) {
        _scanTimeoutTimer?.cancel();
        setState(() => _isScanning = false);
        _scannerBloc.add(ScanQR(widget.purpose, scannedCode));
        _startScanCooldown();
      }
    });
  }

  void _showSuccessDetection() {
    setState(() {
      _showSuccessAnimation = true;
    });

    _successAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _successAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showSuccessAnimation = false;
            });
            _pulseAnimationController.stop();
          }
        });
      }
    });
  }

  void _startScanCooldown() {
    _scanCooldownTimer = Timer(_scanCooldown, () {
      if (mounted) {
        setState(() {
          _isProcessingQR = false;
        });
        print("DEBUG: Scan cooldown completed");
      }
    });
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _scanCooldownTimer?.cancel();
    _successAnimationController.dispose();
    _pulseAnimationController.dispose();
    _controller.stop();
    _controller.dispose();
    _isScanning = false;
    _cameraErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scannerBloc,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        child: Stack(
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
            QROverlay(
              isScanning: _isScanning && !_isProcessingQR,
              purpose: widget.purpose,
              isProcessing: _isProcessingQR,
            ),

            // Success Animation Overlay
            if (_showSuccessAnimation)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _successAnimationController,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Transform.scale(
                          scale: _successScaleAnimation.value,
                          child: Opacity(
                            opacity: _successOpacityAnimation.value,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.6),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isProcessingQR
                          ? 'Đang xử lý mã QR...'
                          : _isScanning
                          ? 'Đặt mã QR vào khung để quét'
                          : 'Quét tạm dừng. Nhấn "Thử lại" để tiếp tục.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (_isProcessingQR)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // CRITICAL FIX: Listen to state changes and rebuild dialog when state updates
            BlocConsumer<ScannerBloc, ScannerState>(
              bloc: _scannerBloc,
              listener: (context, state) {
                // Listen for state changes and update local state
                if (state is ScannerSuccess) {
                  print("DEBUG: Scanner state changed to Success - isApiLoading: ${state.isApiLoading}");
                  if (_isSubmitting && !state.isApiLoading) {
                    print("DEBUG: API loading finished, stopping local submission state");
                    setState(() {
                      _isSubmitting = false;
                    });
                  }
                } else if (state is ScannerFailure) {
                  print("DEBUG: Scanner state changed to Failure");
                  setState(() {
                    _isSubmitting = false;
                  });
                }
              },
              builder: (context, state) {
                if (state is ScannerSuccess) {
                  final Map<String, dynamic> details = Map<String, dynamic>.from(state.result['details']);
                  final actions = state.result['actions'] as List<dynamic>? ?? [];
                  final serial = widget.purpose == 'stockin' || widget.purpose == 'stockout'
                      ? details['serial_number']?.toString() ?? ''
                      : details['device_serial']?.toString() ?? '';

                  print("DEBUG: Building success dialog - isApiLoading: ${state.isApiLoading}, local _isSubmitting: $_isSubmitting");

                  return ResultDialog(
                    type: 'success',
                    title: state.result['title'] as String,
                    message: state.result['message'] as String,
                    details: details.map((key, value) => MapEntry(key, value.toString())),
                    actions: actions.map((e) => e.toString()).toList(),
                    isLoading: false, // Deprecated
                    isApiLoading: state.isApiLoading, // Use state from bloc
                    isBluetoothLoading: state.isBluetoothLoading, // Use state from bloc
                    apiError: state.apiError, // Pass API error from state
                    bluetoothError: state.bluetoothError, // Pass Bluetooth error from state
                    currentMode: widget.purpose,
                    onSubmit: actions.contains('submit')
                        ? () {
                      print("DEBUG: Submit button pressed with serial: $serial");
                      _handleSubmit(serial);
                    }
                        : null,
                    onSendToDevice: widget.purpose == 'firmware' && actions.contains('send_to_device')
                        ? () {
                      print("DEBUG: Send to device button pressed with serial: $serial");
                      if (mounted) {
                        setState(() => _isSubmitting = true);
                      }
                      _scannerBloc.add(SendToDeviceOnly(serial, widget.purpose));
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
                      _retryScanning();
                    },
                  );
                } else if (state is ScannerFailure) {
                  final Map<String, dynamic> details = Map<String, dynamic>.from(state.error['details'] ?? {});
                  final actions = state.error['details']['actions'] as List<dynamic>? ?? [];
                  final serial = details.containsKey('device_serial') ? details['device_serial'].toString() : '';

                  print("DEBUG: Building failure dialog");

                  return ResultDialog(
                    type: 'error',
                    title: state.error['title'] as String,
                    message: state.error['message'] as String,
                    details: details.map((key, value) => MapEntry(key, value.toString())),
                    actions: actions.map((e) => e.toString()).toList(),
                    isLoading: false, // Deprecated
                    isApiLoading: false, // Always false for failure
                    isBluetoothLoading: false, // Always false for failure
                    currentMode: widget.purpose,
                    onSubmit: actions.contains('submit')
                        ? () {
                      print("DEBUG: Submit button pressed with serial: $serial");
                      _handleSubmit(serial);
                    }
                        : null,
                    onSendToDevice: widget.purpose == 'firmware' && actions.contains('send_to_device')
                        ? () {
                      print("DEBUG: Send to device button pressed with serial: $serial");
                      if (mounted) {
                        setState(() => _isSubmitting = true);
                      }
                      _scannerBloc.add(SendToDeviceOnly(serial, widget.purpose));
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
    );
  }
}