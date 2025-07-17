import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/services/scanner_service.dart';
import 'package:smart_net_qr_scanner/data/services/production_service.dart';
import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/export_warehouse_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerService _scannerService = getIt<ScannerService>();
  final ProductionService _productionService = getIt<ProductionService>();
  final CameraService _cameraService = getIt<CameraService>();
  final ImportWarehouseService _importWarehouseService = getIt<ImportWarehouseService>();
  final ExportWarehouseService _exportWarehouseService = getIt<ExportWarehouseService>();
  String _currentFunctionId = '';
  String? _currentOrderId; // Store current import/export order ID
  String? _currentExportId; // Store current export ID

  ScannerBloc() : super(const ScannerInitial()) {
    on<ScanQR>((event, emit) async {
      try {
        _currentFunctionId = event.purpose;

        if (event.error != null) {
          emit(ScannerFailure(error: event.error!));
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

        // Parse QR data for all purposes
        final qrData = QrData.fromJsonString(event.data);
        print('DEBUG: Parsed QR data: $qrData');

        // Handle stockin
        if (event.purpose == 'stockin') {
          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét mã QR cho nhập kho',
            'details': {
              'serial_number': qrData.serialNumber,
              'batch_production_id': qrData.batchProductionId,
              'template_id': qrData.templateId,
              if (qrData.templateName != null && qrData.templateName!.isNotEmpty)
                'template_name': qrData.templateName!,
            },
            'actions': const ['retry', 'submit', 'dashboard'],
          }));
          return;
        }

        // Handle stockout
        if (event.purpose == 'stockout') {
          emit(ScannerSuccess(result: {
            'title': 'Quét thành công',
            'message': 'Đã quét mã QR cho xuất kho',
            'details': {
              'serial_number': qrData.serialNumber,
              'batch_production_id': qrData.batchProductionId,
              'template_id': qrData.templateId,
              if (qrData.templateName != null && qrData.templateName!.isNotEmpty)
                'template_name': qrData.templateName!,
            },
            'actions': const ['retry', 'submit', 'dashboard'],
          }));
          return;
        }

        // Handle production purposes (identify, firmware, testing, packaging)
        emit(ScannerSuccess(result: {
          'title': 'Quét thành công',
          'message': 'Đã quét thiết bị thành công',
          'details': {
            'device_serial': event.data,
            'serial_number': qrData.serialNumber,
            'batch_production_id': qrData.batchProductionId,
            'template_id': qrData.templateId,
            if (qrData.templateName != null && qrData.templateName!.isNotEmpty)
              'template_name': qrData.templateName!,
          },
          'actions': const ['retry', 'submit'],
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

    on<SetOrderId>((event, emit) {
      _currentOrderId = event.orderId;
    });

    on<SetExportId>((event, emit) {
      _currentExportId = event.exportId;
      _currentOrderId = event.orderId;
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
      // Parse QR data from the current state details
      final qrData = QrData(
        serialNumber: currentState.result['details']['serial_number'] ?? serialNumber,
        batchProductionId: currentState.result['details']['batch_production_id'] ?? '',
        templateId: currentState.result['details']['template_id'] ?? '',
        templateName: currentState.result['details']['template_name'],
      );

      // Handle stockin
      if (functionId == 'stockin') {
        if (_currentOrderId == null) {
          emit(ScannerFailure(error: {
            'title': 'Lỗi dữ liệu',
            'message': 'Không tìm thấy thông tin đơn nhập.',
            'details': {'errorCode': 'DATA-002', 'actions': const ['dashboard']},
          }));
          return;
        }

        emit(currentState.copyWith(isApiLoading: true));

        final result = await _importWarehouseService.importOrderItemFromQr(
          importId: _currentOrderId!,
          qrData: qrData,
        );

        if (result['success'] == true) {
          // Trigger refresh of import progress in StockBloc
          final stockBloc = getIt<StockBloc>();
          stockBloc.add(LoadImportProgress(_currentOrderId!));

          emit(ScannerSuccess(
            result: {
              'title': 'Nhập kho thành công',
              'message': 'Đã nhập thiết bị vào kho thành công',
              'details': {
                'serial_number': qrData.serialNumber,
                'batch_production_id': qrData.batchProductionId,
                'template_id': qrData.templateId,
                if (qrData.templateName != null) 'template_name': qrData.templateName!,
                'status': 'Đã nhập kho',
              },
              'actions': const ['retry', 'dashboard'],
            },
            isApiLoading: false,
          ));
        } else {
          emit(currentState.copyWith(
            isApiLoading: false,
            apiError: result['message'] ?? 'Không thể nhập thiết bị vào kho',
          ));
        }
        return;
      }

      // Handle stockout
      if (functionId == 'stockout') {
        if (_currentExportId == null || _currentOrderId == null) {
          emit(ScannerFailure(error: {
            'title': 'Lỗi dữ liệu',
            'message': 'Không tìm thấy thông tin đơn xuất hoặc đơn đặt hàng.',
            'details': {'errorCode': 'DATA-003', 'actions': const ['dashboard']},
          }));
          return;
        }

        emit(currentState.copyWith(isApiLoading: true));

        final result = await _exportWarehouseService.processExportItem(
          exportId: _currentExportId!,
          orderId: _currentOrderId!,
          serialNumber: qrData.serialNumber,
          batchProductionId: qrData.batchProductionId,
          templateId: qrData.templateId,
        );

        if (result['success'] == true) {
          // Trigger refresh of export progress in StockBloc
          final stockBloc = getIt<StockBloc>();
          stockBloc.add(LoadExportProgress(_currentExportId!));

          emit(ScannerSuccess(
            result: {
              'title': 'Xuất kho thành công',
              'message': 'Đã xuất thiết bị khỏi kho thành công',
              'details': {
                'serial_number': qrData.serialNumber,
                'batch_production_id': qrData.batchProductionId,
                'template_id': qrData.templateId,
                if (qrData.templateName != null) 'template_name': qrData.templateName!,
                'status': 'Đã xuất kho',
              },
              'actions': const ['retry', 'dashboard'],
            },
            isApiLoading: false,
          ));
        } else {
          emit(currentState.copyWith(
            isApiLoading: false,
            apiError: result['message'] ?? 'Không thể xuất thiết bị khỏi kho',
          ));
        }
        return;
      }

      // Handle production purposes (existing logic)
      emit(currentState.copyWith(isApiLoading: true));

      final apiResult = await _productionService.processScannedSerial(
        serialNumber,
        functionId: functionId,
      );

      if (apiResult['success']) {
        emit(ScannerSuccess(
          result: {
            'title': 'Thành công',
            'message': 'Đã cập nhật thông tin thiết bị thành công',
            'details': {
              'device_serial': serialNumber,
              'serial_number': apiResult['data']?['serial_number'] ?? qrData.serialNumber,
              'batch_production_id': apiResult['data']?['batch_production_id'] ?? qrData.batchProductionId,
              'template_id': apiResult['data']?['template_id'] ?? qrData.templateId,
              'template_name': apiResult['data']?['template_name'] ?? qrData.templateName ?? '',
              'stage': apiResult['data']?['stage'] ?? 'assembly',
              'status': apiResult['data']?['status'] ?? 'in_progress',
              'api_status': 'Thành công',
            },
            'actions': const ['retry', 'dashboard'],
          },
          isApiLoading: false,
        ));
      } else {
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