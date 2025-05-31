import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';
import 'package:firmware_deployment_tool/data/services/production_service.dart';
import 'package:firmware_deployment_tool/data/services/camera_service.dart';
import 'package:firmware_deployment_tool/utils/logger.dart';
import 'package:firmware_deployment_tool/utils/di.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();
  final ProductionService _productionService = getIt<ProductionService>();
  final CameraService _cameraService = getIt<CameraService>();

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      try {
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
            'actions': const ['submit', 'retry'],
          }));
          return;
        }

        // Handle other purposes (to be implemented later)
        await _cameraService.stop();
        emit(const ScannerFailure(error: {
          'title': 'Chức năng chưa hỗ trợ',
          'message': 'Chức năng này đang được phát triển.',
          'details': {'errorCode': 'FUNC-001', 'reason': 'Not implemented'},
        }));
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện ScanQR', e, stackTrace);
        await _cameraService.stop();
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi khi xử lý quét mã QR.',
          'details': {'errorCode': 'SYS-001', 'reason': e.toString()},
        }));
      }
    });

    on<SubmitScan>((event, emit) async {
      try {
        if (event.serialNumber.isEmpty) {
          emit(const ScannerFailure(error: {
            'title': 'Lỗi dữ liệu',
            'message': 'Không có thông tin thiết bị để gửi.',
            'details': {'errorCode': 'DATA-001', 'reason': 'Empty serial number'},
          }));
          return;
        }

        final result = await _productionService.updateDeviceStage(
          event.serialNumber,
          'assembly',
          'in_progress',
        );

        if (result['success']) {
          emit(ScannerSuccess(result: {
            'title': 'Thành công',
            'message': 'Đã cập nhật thông tin thiết bị thành công',
            'details': {
              'device_serial': event.serialNumber,
              'stage': 'assembly',
              'status': 'in_progress'
            },
            'actions': const ['scan_more', 'dashboard'],
          }));
        } else {
          emit(ScannerFailure(error: {
            'title': 'Lỗi cập nhật',
            'message': result['message'],
            'details': {
              'errorCode': result['errorCode'],
              'reason': result['message'],
            },
            'actions': const ['retry', 'dashboard'],
          }));
        }
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện SubmitScan', e, stackTrace);
        emit(ScannerFailure(error: {
          'title': 'Lỗi hệ thống',
          'message': 'Đã xảy ra lỗi khi cập nhật thông tin thiết bị.',
          'details': {'errorCode': 'SYS-002', 'reason': e.toString()},
        }));
      }
    });

    on<RetryScan>((event, emit) async {
      await _cameraService.restart();
      emit(const ScannerInitial());
    });
  }

  @override
  Future<void> close() {
    _cameraService.dispose();
    return super.close();
  }
}
