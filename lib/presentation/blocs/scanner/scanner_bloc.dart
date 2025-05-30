import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      final success = event.data.isNotEmpty && (await _scannerService.requestCameraPermission());
      if (success) {
        final result = _getMockResult(event.purpose, event.data);
        emit(ScannerSuccess(result: result));
      } else {
        emit(const ScannerFailure(error: {
          'title': 'Scan Failed',
          'message': 'Unable to read QR code. Please try again.',
          'details': {'errorCode': 'QR-001', 'reason': 'Invalid or damaged QR code'},
        }));
      }
    });
    on<ResetScanner>((event, emit) => emit(const ScannerInitial()));
  }

  Map<String, dynamic> _getMockResult(String purpose, String data) {
    final mockData = {
      'identify': {
        'deviceId': data,
        'model': 'Smart Device v2',
        'serialNumber': 'SN20240215-001',
        'manufacturer': 'Tech Corp',
      },
      'firmware': {
        'deviceId': data,
        'currentVersion': 'v1.2.3',
        'targetVersion': 'v2.0.0',
      },
      'testing': {
        'deviceId': data,
        'testPhase': 'Quality Control',
        'batchNumber': 'QC-2024-015',
      },
      'packaging': {
        'deviceId': data,
        'packageType': 'Retail Box',
        'destination': 'Warehouse A',
      },
      'stockin': {
        'deviceId': data,
        'location': 'Shelf A-123',
        'timestamp': DateTime.now().toString(),
      },
      'stockout': {
        'deviceId': data,
        'destination': 'Retail Store #123',
        'orderNumber': 'ORD-2024-789',
      },
    };
    return {
      'title': 'Scan Successful',
      'message': 'Successfully scanned device for ${_getPurposeTitle(purpose).toLowerCase()}',
      'details': mockData[purpose] ?? {},
    };
  }

  String _getPurposeTitle(String purpose) {
    const titles = {
      'identify': 'Device Identification',
      'firmware': 'Firmware Update',
      'testing': 'Device Testing',
      'packaging': 'Device Packaging',
      'stockin': 'Stock In',
      'stockout': 'Stock Out',
    };
    return titles[purpose] ?? 'QR Code';
  }
}