import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firmware_deployment_tool/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:firmware_deployment_tool/presentation/widgets/qr_overlay.dart';
import 'package:firmware_deployment_tool/presentation/widgets/result_dialog.dart';

class QRScannerScreen extends StatelessWidget {
  final String purpose;
  final VoidCallback onBack;

  const QRScannerScreen({super.key, required this.purpose, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScannerBloc(),
      child: Scaffold(
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                context.read<ScannerBloc>().add(ScanQR(purpose, barcode.rawValue ?? ''));
              },
            ),
            QROverlay(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _getPurposeTitle(purpose),
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
                child: const Text(
                  'Position the QR code within the frame to scan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            BlocBuilder<ScannerBloc, ScannerState>(
              builder: (context, state) {
                if (state is ScannerSuccess) {
                  return ResultDialog(
                    type: 'success',
                    title: state.result['title'],
                    message: state.result['message'],
                    details: Map<String, String>.from(state.result['details']),
                    onClose: onBack,
                    onContinue: () => context.read<ScannerBloc>().add(ResetScanner()),
                  );
                } else if (state is ScannerFailure) {
                  return ResultDialog(
                    type: 'error',
                    title: state.error['title'],
                    message: state.error['message'],
                    details: Map<String, String>.from(state.error['details']),
                    onClose: onBack,
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
      'identify': 'Scan for Device ID',
      'firmware': 'Scan for Firmware Update',
      'testing': 'Scan for Testing',
      'packaging': 'Scan for Packaging',
      'stockin': 'Scan for Stock In',
      'stockout': 'Scan for Stock Out',
    };
    return titles[purpose] ?? 'Scan QR Code';
  }
}