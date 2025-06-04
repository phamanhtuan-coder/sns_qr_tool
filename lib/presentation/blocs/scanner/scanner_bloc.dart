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
  final BluetoothClientService _bluetoothService = getIt<BluetoothClientService>(); // Added service
  String _currentFunctionId = ''; // Store current function ID/purpose

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

        bool sentToDesktop = false;

        // Only send data via Bluetooth for firmware mode
        if (event.functionId == 'firmware') {
          // Try to send data to desktop via Bluetooth/Socket
          print("⚡ DEBUG: Firmware mode - attempting to send serial data to desktop");
          sentToDesktop = await _bluetoothService.sendSerialToDesktop(event.serialNumber);
          print("⚡ DEBUG: Sent to desktop result: $sentToDesktop");
        } else {
          print("⚡ DEBUG: Non-firmware mode - skipping Bluetooth communication");
        }

        // Always call the API for all modes
        print("DEBUG: Calling processScannedSerial with serial: ${event.serialNumber}, functionId: ${event.functionId}");
        final result = await _productionService.processScannedSerial(
          event.serialNumber,
          functionId: event.functionId,
        );
        print("DEBUG: API result: $result");

        if (result['success']) {
          print("DEBUG: API call successful, emitting success state");
          emit(ScannerSuccess(result: {
            'title': 'Thành công',
            'message': event.functionId == 'firmware'
              ? (sentToDesktop
                  ? 'Đã cập nhật thông tin thiết bị và gửi dữ liệu tới máy tính thành công'
                  : 'Đã cập nhật thông tin thiết bị thành công (Không gửi được tới PC)')
              : 'Đã cập nhật thông tin thiết bị thành công',
            'details': {
              'device_serial': event.serialNumber,
              'stage': result['data']?['stage'] ?? 'Unknown',
              'status': result['data']?['status'] ?? 'Unknown',
              'sent_to_desktop': event.functionId == 'firmware' ? (sentToDesktop ? 'Thành công' : 'Thất bại') : 'N/A'
            },
            'actions': const ['retry', 'dashboard'],
          }));
        } else {
          print("DEBUG: API call failed: ${result['message']}");
          emit(ScannerFailure(error: {
            'title': 'Lỗi cập nhật',
            'message': result['message'] ?? 'Không thể cập nhật thông tin thiết bị.',
            'details': {
              'errorCode': result['errorCode'] ?? 'API-001',
              'reason': result['message'] ?? 'Unknown error',
              'device_serial': event.serialNumber,
              'sent_to_desktop': event.functionId == 'firmware' ? (sentToDesktop ? 'Thành công' : 'Thất bại') : 'N/A'
            },
            'actions': const ['retry', 'dashboard'],
          }));
        }
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

  @override
  Future<void> close() {
    _bluetoothService.dispose(); // Also dispose bluetooth service
    _cameraService.dispose();
    return super.close();
  }
}
