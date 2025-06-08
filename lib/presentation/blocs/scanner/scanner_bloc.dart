import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/services/scanner_service.dart';
import 'package:smart_net_qr_scanner/data/services/production_service.dart';
import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:smart_net_qr_scanner/data/services/bluetooth_client_service.dart'; // Added import
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();
  final ProductionService _productionService = getIt<ProductionService>();
  final CameraService _cameraService = getIt<CameraService>();
  final BluetoothClientService _bluetoothService = getIt<BluetoothClientService>();
  String _currentFunctionId = '';

  // Add listener for Bluetooth connection status
  Stream<ConnectionStatus> get connectionStatus => _bluetoothService.connectionStatus;

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      try {
        // Store the current function ID for later use
        _currentFunctionId = event.purpose;

        if (event.error != null) {
          emit(ScannerFailure(error: event.error!));
          // Don't stop the camera here, let the UI control camera state
          return;
        }

        final permissionResult = await _scannerService.requestCameraPermission();
        if (!permissionResult['success']) {
          emit(ScannerFailure(error: permissionResult['error']));
          // Don't stop the camera here, let the UI control camera state
          return;
        }

        if (event.data.isEmpty) {
          emit(const ScannerFailure(error: {
            'title': 'Quét thất bại',
            'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
            'details': {'errorCode': 'QR-001', 'reason': 'Empty QR data'},
            'actions': ['retry', 'dashboard'],
          }));
          // Don't stop the camera here, let the UI control camera state
          return;
        }

        // For identify purpose, we expect a simple serial string
        if (event.purpose == 'identify') {
          // Don't stop the camera here, let the UI control camera state
          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét thiết bị thành công',
            'details': {'device_serial': event.data},
            'actions': const ['retry', 'submit'],
          }));
          return;
        }

        // Handle other purposes
        // Don't stop the camera here, let the UI control camera state
        emit(ScannerSuccess(result: {
          'title': 'Quét thành công',
          'message': 'Đã quét thiết bị thành công',
          'details': {'device_serial': event.data},
          'actions': const ['retry', 'submit'],
        }));
      } catch (e, stackTrace) {
        print("DEBUG: Exception in SubmitScan handler: $e");
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        // Don't stop the camera here, let the UI control camera state
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
      // Set loading states
      emit(currentState.copyWith(
        isApiLoading: true,
        isBluetoothLoading: functionId == 'firmware',
      ));

      // Start both operations concurrently if in firmware mode
      final Future<bool> bluetoothFuture = functionId == 'firmware'
          ? _bluetoothService.sendSerialToDesktop(serialNumber)
          : Future.value(true);

      final Future<Map<String, dynamic>> apiFuture = _productionService.processScannedSerial(
        serialNumber,
        functionId: functionId,
      );

      // Wait for both operations to complete
      final results = await Future.wait([
        bluetoothFuture,
        apiFuture,
      ]);

      final bool bluetoothSuccess = results[0] as bool;
      final Map<String, dynamic> apiResult = results[1] as Map<String, dynamic>;

      // Handle API result
      String? apiError;
      if (!apiResult['success']) {
        apiError = apiResult['message'] ?? 'Không thể cập nhật thông tin thiết bị';
      }

      // Handle Bluetooth result
      String? bluetoothError;
      if (functionId == 'firmware' && !bluetoothSuccess) {
        bluetoothError = 'Không thể gửi dữ liệu tới máy tính';
      }

      // Update state based on results
      if (apiResult['success'] && (functionId != 'firmware' || bluetoothSuccess)) {
        // Complete success
        emit(ScannerSuccess(
          result: {
            'title': 'Thành công',
            'message': functionId == 'firmware'
                ? 'Đã cập nhật thông tin thiết bị và gửi dữ liệu tới máy tính thành công'
                : 'Đã cập nhật thông tin thiết bị thành công',
            'details': {
              'device_serial': serialNumber,
              'stage': apiResult['data']?['stage'] ?? 'Unknown',
              'status': apiResult['data']?['status'] ?? 'Unknown',
              'sent_to_desktop': functionId == 'firmware' ? 'Thành công' : 'N/A',
            },
            'actions': const ['retry', 'dashboard'],
          },
        ));
      } else {
        // Partial success or complete failure
        emit(currentState.copyWith(
          isApiLoading: false,
          isBluetoothLoading: false,
          apiError: apiError,
          bluetoothError: bluetoothError,
          result: {
            ...currentState.result,
            'details': {
              ...currentState.result['details'] as Map<String, dynamic>,
              'sent_to_desktop': functionId == 'firmware'
                  ? (bluetoothSuccess ? 'Thành công' : 'Thất bại')
                  : 'N/A',
            },
          },
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isApiLoading: false,
        isBluetoothLoading: false,
        apiError: 'Lỗi hệ thống: ${e.toString()}',
      ));
    }
  }

  @override
  Future<void> close() {
    _bluetoothService.dispose();
    _cameraService.dispose();
    return super.close();
  }
}
