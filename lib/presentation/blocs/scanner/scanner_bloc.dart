import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';
import 'package:firmware_deployment_tool/data/services/production_service.dart';
import 'package:firmware_deployment_tool/data/services/camera_service.dart';
import 'package:firmware_deployment_tool/data/services/bluetooth_client_service.dart'; // Added import
import 'package:firmware_deployment_tool/utils/logger.dart';
import 'package:firmware_deployment_tool/utils/di.dart';

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
          await _cameraService.stop();
          return;
        }

        final permissionResult = await _scannerService.requestCameraPermission();
        if (!permissionResult['success']) {
          emit(ScannerFailure(error: permissionResult['error']));
          await _cameraService.stop();
          return;
        }

        if (event.data.isEmpty) {
          emit(const ScannerFailure(error: {
            'title': 'Quét thất bại',
            'message': 'Không thể đọc mã QR. Vui lòng thử lại.',
            'details': {'errorCode': 'QR-001', 'reason': 'Empty QR data'},
            'actions': ['retry', 'dashboard'],
          }));
          await _cameraService.stop();
          return;
        }

        // For identify purpose, we expect a simple serial string
        if (event.purpose == 'identify') {
          await _cameraService.stop();
          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét thiết bị thành công',
            'details': {'device_serial': event.data},
            'actions': const ['retry', 'submit'],
          }));
          return;
        }

        // Handle other purposes
        await _cameraService.stop();
        emit(ScannerSuccess(result: {
          'title': 'Quét thành công',
          'message': 'Đã quét thiết bị thành công',
          'details': {'device_serial': event.data},
          'actions': const ['retry', 'submit'],
        }));
      } catch (e, stackTrace) {
        print("DEBUG: Exception in SubmitScan handler: $e");
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        await _cameraService.stop();
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi khi xử lý quét mã QR.',
          'details': {'errorCode': 'SYS-001', 'reason': e.toString(), 'actions': ['retry', 'dashboard']},
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

        // First, try to send data to desktop via Bluetooth/Socket
        print("⚡ DEBUG: Attempting to send serial data to desktop");
        bool sentToDesktop = await _bluetoothService.sendSerialToDesktop(event.serialNumber);
        print("⚡ DEBUG: Sent to desktop result: $sentToDesktop");

        // Whether desktop communication succeeded or not, still proceed with API call
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
            'message': sentToDesktop
              ? 'Đã cập nhật thông tin thiết bị và gửi dữ liệu tới máy tính thành công'
              : 'Đã cập nhật thông tin thiết bị thành công (Không gửi được tới PC)',
            'details': {
              'device_serial': event.serialNumber,
              'stage': result['data']?['stage'] ?? 'Unknown',
              'status': result['data']?['status'] ?? 'Unknown',
              'sent_to_desktop': sentToDesktop ? 'Thành công' : 'Thất bại'
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
              'sent_to_desktop': sentToDesktop ? 'Thành công' : 'Thất bại'
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
            'actions': ['retry', 'dashboard']
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
          'details': {'errorCode': 'SYS-003', 'reason': e.toString(), 'actions': ['dashboard']},
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
