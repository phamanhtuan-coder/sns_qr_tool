import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/services/scanner_service.dart';
import 'package:smart_net_qr_scanner/data/services/production_service.dart';
import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();
  final ProductionService _productionService = getIt<ProductionService>();
  final CameraService _cameraService = getIt<CameraService>();
  String _currentFunctionId = '';

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      try {
        // Store the current function ID for later use
        _currentFunctionId = event.purpose;

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
            'actions': ['retry', 'dashboard'],
          }));
          return;
        }

        // Handle stockin and stockout with new workflow
        if (event.purpose == 'stockin' || event.purpose == 'stockout') {
          // For stock operations, trigger the stock bloc
          final stockBloc = getIt<StockBloc>();
          if (event.purpose == 'stockin') {
            stockBloc.add(ScanImportDevice(event.data));
          } else {
            stockBloc.add(ScanDevice(event.data));
          }

          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét thiết bị cho ${event.purpose == 'stockin' ? 'nhập kho' : 'xuất kho'}',
            'details': {
              'device_serial': event.data,
              'operation': event.purpose == 'stockin' ? 'Nhập kho' : 'Xuất kho',
              'status': 'Thành công',
            },
            'actions': const ['retry', 'dashboard'],
          }));
          return;
        }

        // Handle all production purposes (identify, firmware, testing, packaging) the same way
        emit(ScannerSuccess(result: {
          'title': 'Quét thành công',
          'message': '��ã quét thiết bị thành công',
          'details': {'device_serial': event.data},
          'actions': const ['retry', 'submit'], // All production modes use submit
        }));
      } catch (e, stackTrace) {
        print("DEBUG: Exception in ScanQR handler: $e");
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi khi xử lý quét mã QR.',
          'details': {'errorCode': 'SYS-001', 'reason': e.toString(), 'actions': const ['retry', 'dashboard']},
        }));
      }
    });

    on<SubmitScan>((event, emit) async {
      print("DEBUG: SubmitScan event received with serialNumber: ${event.serialNumber}, functionId: ${event.functionId}");
      try {
        if (event.serialNumber.isEmpty) {
          print("DEBUG: Empty serial number");
          emit(const ScannerFailure(error: {
            'title': 'Lỗi dữ liệu',
            'message': 'Không có thông tin thiết bị để gửi.',
            'details': {'errorCode': 'DATA-001', 'reason': 'Empty serial number', 'actions': ['retry', 'dashboard']},
          }));
          return;
        }

        await _handleSubmitScan(event.serialNumber, event.functionId, emit);
      } catch (e, stackTrace) {
        print("DEBUG: Exception in SubmitScan handler: $e");
        logError('Lỗi xử lý sự kiện SubmitScan', e, stackTrace);
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi khi cập nhật thông tin thiết bị.',
          'details': {
            'errorCode': 'SYS-002',
            'reason': e.toString(),
            'device_serial': event.serialNumber,
            'actions': const ['retry', 'dashboard']
          },
        }));
      }
    });

    on<RetryScan>((event, emit) async {
      try {
        await _cameraService.reset();
        emit(const ScannerInitial());
      } catch (e) {
        emit(ScannerFailure(error: {
          'title': 'Lỗi khởi động lại',
          'message': 'Không thể khởi động lại quá trình quét.',
          'details': {'errorCode': 'SYS-003', 'reason': e.toString(), 'actions': const ['dashboard']},
        }));
      }
    });

    on<ResetScanner>((event, emit) {
      emit(const ScannerInitial());
    });
  }

  Future<void> _handleSubmitScan(String serialNumber, String functionId, Emitter<ScannerState> emit) async {
    if (state is! ScannerSuccess) return;
    final currentState = state as ScannerSuccess;

    try {
      // Handle stock operations for stockin and stockout
      if (functionId == 'stockin' || functionId == 'stockout') {
        // Handle stock operations - already handled in ScanQR event
        emit(ScannerSuccess(result: {
          'title': 'Quét thành công',
          'message': 'Đã quét thiết bị cho ${functionId == 'stockin' ? 'nhập kho' : 'xuất kho'}',
          'details': {
            'device_serial': serialNumber,
            'operation': functionId == 'stockin' ? 'Nhập kho' : 'Xuất kho',
            'status': 'Thành công',
          },
          'actions': const ['retry', 'dashboard'],
        }));
        return;
      }

      // Set loading state for API call
      emit(currentState.copyWith(isApiLoading: true));

      // Call API to update serial - no timeout, let it complete naturally
      final apiResult = await _productionService.processScannedSerial(
        serialNumber,
        functionId: functionId,
      );

      // Handle API result
      if (apiResult['success']) {
        // Complete success
        emit(ScannerSuccess(
          result: {
            'title': 'Thành công',
            'message': 'Đã cập nhật thông tin thiết bị thành công',
            'details': {
              'device_serial': serialNumber,
              'stage': apiResult['data']?['stage'] ?? 'assembly',
              'status': apiResult['data']?['status'] ?? 'in_progress',
              'api_status': 'Thành công',
            },
            'actions': const ['retry', 'dashboard'],
          },
          isApiLoading: false,
        ));
      } else {
        // API failure
        emit(currentState.copyWith(
          isApiLoading: false,
          apiError: apiResult['message'] ?? 'Không thể cập nhật thông tin thiết bị',
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isApiLoading: false,
        apiError: 'Lỗi hệ thống: ${e.toString()}',
      ));
    }
  }

  @override
  Future<void> close() {
    _cameraService.dispose();
    return super.close();
  }
}
