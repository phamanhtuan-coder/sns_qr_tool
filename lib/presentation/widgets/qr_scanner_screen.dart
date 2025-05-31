import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firmware_deployment_tool/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:firmware_deployment_tool/presentation/widgets/qr_overlay.dart';
import 'package:firmware_deployment_tool/presentation/widgets/result_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../data/services/auth_service.dart';
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
  final MobileScannerController _controller = MobileScannerController();
  late final ScannerBloc _scannerBloc;

  @override
  void initState() {
    super.initState();
    _scannerBloc = getIt<ScannerBloc>();
    _checkDeviceSupport();
    _startScanTimeout();
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
        _scannerBloc.add(ScanQR(widget.purpose, '', error: {
          'title': 'Thiết bị không hỗ trợ',
          'message': 'Thiết bị này không hỗ trợ quét QR. Vui lòng sử dụng thiết bị khác.',
          'details': {'errorCode': 'DEVICE-001', 'reason': 'No camera support'},
        }));
        setState(() => _isScanning = false);
      }
    } catch (e) {
      _scannerBloc.add(ResetScanner());
      _scannerBloc.add(ScanQR(widget.purpose, '', error: {
        'title': 'Lỗi thiết bị',
        'message': 'Không thể kiểm tra hỗ trợ thiết bị. Vui lòng thử lại.',
        'details': {'errorCode': 'DEVICE-002', 'reason': e.toString()},
      }));
      setState(() => _isScanning = false);
    }
  }

  void _startScanTimeout() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) {
        setState(() => _isScanning = false);
        _controller.stop();
        _scannerBloc.add(ScanQR(widget.purpose, '', error: {
          'title': 'Hết thời gian quét',
          'message': 'Không tìm thấy mã QR trong 10 giây. Vui lòng thử lại.',
          'details': {'errorCode': 'QR-003', 'reason': 'Timeout'},
        }));
      }
    });
  }

  void _safePop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      widget.onBack(); // Reset DashboardBloc state
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _isScanning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scannerBloc,
      child: Scaffold(
        body: Stack(
          children: [
            if (_isDeviceSupported && _isScanning)
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode == null || barcode.rawValue == null || barcode.rawValue!.isEmpty) {
                    _scannerBloc.add(ScanQR(widget.purpose, '', error: {
                      'title': 'Quét thất bại',
                      'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
                      'details': {'errorCode': 'QR-002', 'reason': 'Invalid or empty QR code'},
                    }));
                    setState(() => _isScanning = false);
                    return;
                  }
                  setState(() => _isScanning = false);
                  _scannerBloc.add(ScanQR(widget.purpose, barcode.rawValue!));
                },
                errorBuilder: (context, error, child) {
                  _scannerBloc.add(ScanQR(widget.purpose, '', error: {
                    'title': 'Lỗi camera',
                    'message': 'Không thể truy cập camera. Vui lòng kiểm tra thiết bị.',
                    'details': {'errorCode': 'CAM-001', 'reason': error.toString()},
                  }));
                  setState(() => _isScanning = false);
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
                  _isScanning ? 'Position the QR code within the frame to scan' : 'Quét tạm dừng. Nhấn "Thử lại" để tiếp tục.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            BlocBuilder<ScannerBloc, ScannerState>(
              bloc: _scannerBloc,
              builder: (context, state) {
                if (state is ScannerSuccess) {
                  return ResultDialog(
                    type: 'success',
                    title: state.result['title'],
                    message: state.result['message'],
                    details: Map<String, String>.from(state.result['details']),
                    onClose: _safePop,
                    onContinue: () {
                      setState(() {
                        _isScanning = true;
                        _controller.start();
                        _startScanTimeout();
                      });
                      _scannerBloc.add(ResetScanner());
                    },
                  );
                } else if (state is ScannerFailure) {
                  return ResultDialog(
                    type: 'error',
                    title: state.error['title'],
                    message: state.error['message'],
                    details: Map<String, String>.from(state.error['details'] ?? {}),
                    onClose: _safePop,
                    onContinue: state.error['action'] == 'open_settings'
                        ? () => openAppSettings()
                        : () {
                            setState(() {
                              _isScanning = true;
                              _controller.start();
                              _startScanTimeout();
                            });
                            _scannerBloc.add(ResetScanner());
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

