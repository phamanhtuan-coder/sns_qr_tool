import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';
import 'package:firmware_deployment_tool/utils/logger.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      try {
        if (event.error != null) {
          emit(ScannerFailure(error: event.error!));
          return;
        }

        final permissionResult = await _scannerService.requestCameraPermission();
        if (!permissionResult['success']) {
          emit(ScannerFailure(error: permissionResult['error']));
          return;
        }

        final result = await _scannerService.scanQR();
        if (result != null) {
          final mockResult = _getMockResult(event.purpose, result);
          emit(ScannerSuccess(result: mockResult));
        } else {
          emit(const ScannerFailure(error: {
            'title': 'Quét thất bại',
            'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
            'details': {'errorCode': 'QR-001', 'reason': 'Invalid or damaged QR code'},
          }));
        }
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        emit(const ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
          'details': {'errorCode': 'SYS-001', 'reason': 'Unexpected error'},
        }));
      }
    });

    on<ResetScanner>((event, emit) {
      try {
        emit(const ScannerInitial());
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện ResetScanner', e, stackTrace);
      }
    });
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
      'title': 'Quét thành công',
      'message': 'Đã quét thiết bị thành công cho ${_getPurposeTitle(purpose).toLowerCase()}',
      'details': mockData[purpose] ?? {},
    };
  }

  String _getPurposeTitle(String purpose) {
    const titles = {
      'identify': 'Xác định thiết bị',
      'firmware': 'Cập nhật Firmware',
      'testing': 'Kiểm tra thiết bị',
      'packaging': 'Đóng gói thiết bị',
      'stockin': 'Nhập kho',
      'stockout': 'Xuất kho',
    };
    return titles[purpose] ?? 'Mã QR';
  }
}