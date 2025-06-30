import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/services/stock_service.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockService _stockService;
  final ImportWarehouseService _importWarehouseService;

  StockBloc(this._stockService, this._importWarehouseService) : super(const StockInitial()) {
    on<LoadStockOrders>(_onLoadStockOrders);
    on<SelectOrder>(_onSelectOrder);
    on<ScanDevice>(_onScanDevice);
    on<CompleteOrder>(_onCompleteOrder);
    on<ResetStock>(_onResetStock);
    on<StartImportOrder>(_onStartImportOrder);
    on<LoadImportOrders>(_onLoadImportOrders);
    on<SelectImportOrder>(_onSelectImportOrder);
    on<ScanImportDevice>(_onScanImportDevice);
  }

  Future<void> _onLoadStockOrders(
      LoadStockOrders event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());

      final orders = await _stockService.getOrdersByType(event.type);

      emit(StockLoaded(orders: orders));
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn hàng', e, stackTrace);
      emit(StockError('Không thể tải danh sách đơn hàng: ${e.toString()}'));
    }
  }

  Future<void> _onSelectOrder(
      SelectOrder event,
      Emitter<StockState> emit,
      ) async {
    if (state is! StockLoaded) return;

    final currentState = state as StockLoaded;

    try {
      final selectedOrder = currentState.orders
          .firstWhere((order) => order.id == event.orderId);

      emit(currentState.copyWith(
        selectedOrder: selectedOrder,
        scannedItems: {},
        scannedCounts: {},
        scannedDevices: [],
        isOrderComplete: false,
      ));
    } catch (e, stackTrace) {
      logError('Lỗi chọn đơn hàng', e, stackTrace);
      emit(StockError('Không thể chọn đơn hàng: ${e.toString()}'));
    }
  }

  Future<void> _onScanDevice(
      ScanDevice event,
      Emitter<StockState> emit,
      ) async {
    if (state is! StockLoaded) return;

    final currentState = state as StockLoaded;
    final selectedOrder = currentState.selectedOrder;

    if (selectedOrder == null) {
      emit(const StockError('Chưa chọn đơn hàng'));
      return;
    }

    try {
      final result = await _stockService.scanDevice(
        event.deviceId,
        selectedOrder,
        currentState.scannedItems,
        currentState.scannedCounts,
        currentState.scannedDevices,
      );

      if (result['success']) {
        final newScannedItems = Map<String, bool>.from(currentState.scannedItems);
        final newScannedCounts = Map<String, int>.from(currentState.scannedCounts);
        final newScannedDevices = List<Device>.from(currentState.scannedDevices);

        if (selectedOrder.type == 'stockIn') {
          newScannedItems[event.deviceId] = true;
        } else {
          final device = result['device'] as Device;
          // Use modelType instead of type, with fallback to prevent null issues
          final deviceType = device.modelType ?? 'unknown';
          newScannedCounts[deviceType] = (newScannedCounts[deviceType] ?? 0) + 1;
          newScannedDevices.add(device);
        }

        final isComplete = _checkOrderComplete(selectedOrder, newScannedItems, newScannedCounts);

        emit(currentState.copyWith(
          scannedItems: newScannedItems,
          scannedCounts: newScannedCounts,
          scannedDevices: newScannedDevices,
          isOrderComplete: isComplete,
        ));
      } else {
        emit(StockError(result['message'] ?? 'Lỗi quét thiết bị'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị', e, stackTrace);
      emit(StockError('Không thể quét thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteOrder(
      CompleteOrder event,
      Emitter<StockState> emit,
      ) async {
    if (state is! StockLoaded) return;

    final currentState = state as StockLoaded;

    try {
      // Simulate API call to complete order
      await Future.delayed(const Duration(seconds: 1));

      emit(currentState.copyWith(
        selectedOrder: null,
        scannedItems: {},
        scannedCounts: {},
        scannedDevices: [],
        isOrderComplete: false,
      ));
    } catch (e, stackTrace) {
      logError('Lỗi hoàn thành đơn hàng', e, stackTrace);
      emit(StockError('Không thể hoàn thành đơn hàng: ${e.toString()}'));
    }
  }

  Future<void> _onResetStock(
      ResetStock event,
      Emitter<StockState> emit,
      ) async {
    emit(const StockInitial());
  }

  Future<void> _onStartImportOrder(
    StartImportOrder event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockLoaded) return;

    final currentState = state as StockLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));

      final result = await _importWarehouseService.startImportOrder(event.importId);

      if (result['success']) {
        // After starting, load the unfinished invoices
        add(const LoadImportOrders());
      } else {
        emit(StockError(result['message'] ?? 'Không thể bắt đầu đơn nhập'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu đơn nhập', e, stackTrace);
      emit(StockError('Không thể bắt đầu đơn nhập: ${e.toString()}'));
    }
  }

  Future<void> _onLoadImportOrders(
    LoadImportOrders event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(const StockLoading());

      final result = await _importWarehouseService.getUnfinishedInvoices();

      if (result['success'] == true) {
        final data = result['data'];
        final List<ImportOrder> importOrders = [];

        if (data is Map && data['data'] is List) {
          for (final item in data['data']) {
            importOrders.add(ImportOrder.fromJson(item));
          }
        } else if (data is List) {
          for (final item in data) {
            importOrders.add(ImportOrder.fromJson(item));
          }
        }

        emit(StockImportLoaded(importOrders: importOrders));
      } else {
        // If API fails, show a helpful error message with manual input option
        final errorMessage = result['message'] ?? 'Không thể tải danh sách đơn nhập';
        print('DEBUG: LoadImportOrders failed: $errorMessage');

        // For now, emit initial state so user can manually start import
        emit(const StockInitial());
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn nhập', e, stackTrace);
      // On error, go back to initial state so user can manually start import
      emit(const StockInitial());
    }
  }

  Future<void> _onSelectImportOrder(
    SelectImportOrder event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockImportLoaded) return;

    final currentState = state as StockImportLoaded;

    try {
      final selectedOrder = currentState.importOrders
          .firstWhere((order) => order.id == event.importId);

      emit(currentState.copyWith(
        selectedImportOrder: selectedOrder,
        scannedImportItems: [],
      ));
    } catch (e, stackTrace) {
      logError('Lỗi chọn đơn nhập', e, stackTrace);
      emit(StockError('Không thể chọn đơn nhập: ${e.toString()}'));
    }
  }

  Future<void> _onScanImportDevice(
    ScanImportDevice event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockImportLoaded) return;

    final currentState = state as StockImportLoaded;
    final selectedOrder = currentState.selectedImportOrder;

    if (selectedOrder == null) {
      emit(const StockError('Chưa chọn đơn nhập'));
      return;
    }

    try {
      // Parse QR data to get device info
      final deviceInfo = _parseQRData(event.qrData);

      if (deviceInfo == null) {
        emit(const StockError('Mã QR không hợp lệ'));
        return;
      }

      // Call import API
      final result = await _importWarehouseService.importOrderItem(
        importId: selectedOrder.id,
        serialNumber: deviceInfo['serial_number']!,
        batchProductionId: deviceInfo['batch_production_id']!,
        templateId: deviceInfo['template_id']!,
      );

      if (result['success']) {
        final newScannedItems = List<ImportOrderItem>.from(currentState.scannedImportItems);
        newScannedItems.add(ImportOrderItem(
          importId: selectedOrder.id,
          serialNumber: deviceInfo['serial_number']!,
          batchProductionId: deviceInfo['batch_production_id']!,
          templateId: deviceInfo['template_id']!,
        ));

        emit(currentState.copyWith(
          scannedImportItems: newScannedItems,
        ));
      } else {
        // Handle API errors
        final errorData = result['data'];
        String errorMessage = result['message'] ?? 'Lỗi không xác định';

        if (errorData is Map && errorData['errors'] is List) {
          final errors = errorData['errors'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors[0]['message'] ?? errorMessage;
          }
        }

        emit(StockError(errorMessage));
      }
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị nhập kho', e, stackTrace);
      emit(StockError('Không thể quét thiết bị: ${e.toString()}'));
    }
  }

  Map<String, String>? _parseQRData(String qrData) {
    try {
      // Assuming QR data contains device information
      // This might need to be adjusted based on actual QR format
      if (qrData.isEmpty) return null;

      return {
        'serial_number': qrData,
        'batch_production_id': 'BTCH12JUN2501JXHMC1K08JPX24K0TDV', // Default or extracted
        'template_id': '1', // Default or extracted
      };
    } catch (e) {
      return null;
    }
  }

  bool _checkOrderComplete(
      StockOrder order,
      Map<String, bool> scannedItems,
      Map<String, int> scannedCounts,
      ) {
    if (order.type == 'stockIn') {
      return order.deviceTypes.every((deviceType) =>
      deviceType.devices?.every((device) => scannedItems[device.id] ?? false) ?? false);
    } else {
      return order.deviceTypes.every((deviceType) =>
      (scannedCounts[deviceType.type] ?? 0) >= deviceType.quantity);
    }
  }
}