import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';
import 'package:firmware_deployment_tool/utils/logger.dart';
import 'package:firmware_deployment_tool/utils/di.dart';

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

        if (event.data.isEmpty) {
          emit(const ScannerFailure(error: {
            'title': 'Quét thất bại',
            'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
            'details': {'errorCode': 'QR-001', 'reason': 'Empty QR data'},
          }));
          return;
        }

        try {
          // Try to parse the QR data as JSON first
          Map<String, dynamic>? jsonData;
          try {
            jsonData = json.decode(event.data) as Map<String, dynamic>?;
          } catch (_) {
            // Not JSON data, use as plain text
          }

          // Process the data based on the purpose and format
          final processedData = _processQRData(event.purpose, event.data, jsonData);
          if (processedData == null) {
            throw FormatException('Invalid data format for purpose: ${event.purpose}');
          }

          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét thiết bị thành công cho ${_getPurposeTitle(event.purpose).toLowerCase()}',
            'details': processedData,
          }));
        } catch (dataError) {
          // Fallback for malformed data
          logError('Lỗi xử lý dữ liệu QR', dataError, StackTrace.current);
          emit(ScannerFailure(error: {
            'title': 'Định dạng không hợp lệ',
            'message': 'Mã QR không đúng định dạng hoặc không áp dụng cho thao tác này.',
            'details': {
              'errorCode': 'QR-004',
              'reason': 'Invalid format',
              'rawData': event.data.length > 100 ? '${event.data.substring(0, 100)}...' : event.data,
              'purpose': event.purpose,
            },
          }));
        }
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
          'details': {
            'errorCode': 'SYS-001',
            'reason': 'Unexpected error',
            'error': e.toString(),
          },
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

  Map<String, dynamic>? _processQRData(String purpose, String rawData, Map<String, dynamic>? jsonData) {
    // If we have JSON data, validate it based on purpose
    if (jsonData != null) {
      // Validate required fields based on purpose
      switch (purpose) {
        case 'identify':
          if (jsonData['deviceId'] != null) return jsonData;
          break;
        case 'firmware':
          if (jsonData['deviceId'] != null && jsonData['version'] != null) return jsonData;
          break;
        case 'testing':
        case 'packaging':
        case 'stockin':
        case 'stockout':
          if (jsonData['deviceId'] != null) return jsonData;
          break;
      }
    }

    // Fallback: treat raw data as device ID if it matches expected format
    if (_isValidDeviceId(rawData)) {
      return _getMockData(purpose, rawData);
    }

    return null;
  }

  bool _isValidDeviceId(String data) {
    // Check if it matches expected format like "DEV-XXXXX"
    return data.length >= 5 && data.length <= 20 && RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(data);
  }

  Map<String, dynamic> _getMockData(String purpose, String deviceId) {
    final mockData = {
      'identify': {
        'deviceId': deviceId,
        'model': 'Smart Device v2',
        'serialNumber': 'SN${DateTime.now().millisecondsSinceEpoch}',
        'manufacturer': 'Tech Corp',
      },
      'firmware': {
        'deviceId': deviceId,
        'currentVersion': 'v1.2.3',
        'targetVersion': 'v2.0.0',
      },
      'testing': {
        'deviceId': deviceId,
        'testPhase': 'Quality Control',
        'batchNumber': 'QC-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      },
      'packaging': {
        'deviceId': deviceId,
        'packageType': 'Retail Box',
        'destination': 'Warehouse A',
      },
      'stockin': {
        'deviceId': deviceId,
        'location': 'Shelf A-123',
        'timestamp': DateTime.now().toIso8601String(),
      },
      'stockout': {
        'deviceId': deviceId,
        'destination': 'Retail Store #123',
        'orderNumber': 'ORD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000}',
      },
    };

    return mockData[purpose] ?? {'deviceId': deviceId};
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
