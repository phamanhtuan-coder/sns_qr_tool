import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/services/stock_service.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/export_warehouse_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_state.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'stock_event.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockService _stockService;
  final ImportWarehouseService _importWarehouseService;
  final ExportWarehouseService _exportWarehouseService;

  StockBloc(this._stockService, this._importWarehouseService, this._exportWarehouseService) : super(const StockInitial()) {
    on<LoadStockOrders>(_onLoadStockOrders);
    on<SelectOrder>(_onSelectOrder);
    on<ScanDevice>(_onScanDevice);
    on<CompleteOrder>(_onCompleteOrder);
    on<ResetStock>(_onResetStock);
    on<StartImportOrder>(_onStartImportOrder);
    on<LoadImportOrders>(_onLoadImportOrders);
    on<SelectImportOrder>(_onSelectImportOrder);
    on<ScanImportDevice>(_onScanImportDevice);
    on<StartExportOrder>(_onStartExportOrder);
    on<LoadExportOrders>(_onLoadExportOrders);
    on<SelectExportOrder>(_onSelectExportOrder);
    on<ScanExportDevice>(_onScanExportDevice);
    on<CompleteExportOrder>(_onCompleteExportOrder);
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
    try {
      emit(const StockLoading());

      final result = await _importWarehouseService.startImportOrder(event.importId);

      if (result['success']) {
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

        if (data is List) {
          for (final item in data) {
            importOrders.add(ImportOrder.fromJson(item));
          }
        }

        emit(StockImportLoaded(importOrders: importOrders));
      } else {
        final errorMessage = result['message'] ?? 'Không thể tải danh sách đơn nhập';
        print('DEBUG: LoadImportOrders failed: $errorMessage');
        emit(const StockInitial());
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn nhập', e, stackTrace);
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
      final deviceInfo = _parseQRData(event.qrData);

      if (deviceInfo == null) {
        emit(const StockError('Mã QR không hợp lệ'));
        return;
      }

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
        emit(StockError(result['message'] ?? 'Lỗi nhập thiết bị'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị nhập kho', e, stackTrace);
      emit(StockError('Không thể quét thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onStartExportOrder(
    StartExportOrder event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(const StockLoading());

      final result = await _exportWarehouseService.startExportOrder(event.exportId);

      if (result['success']) {
        add(const LoadExportOrders());
      } else {
        emit(StockError(result['message'] ?? 'Không thể bắt đầu đơn xuất'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu đơn xuất', e, stackTrace);
      emit(StockError('Không thể bắt đầu đơn xuất: ${e.toString()}'));
    }
  }

  Future<void> _onLoadExportOrders(
    LoadExportOrders event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(const StockLoading());

      final result = await _exportWarehouseService.getUnfinishedExportOrders();

      if (result['success'] == true) {
        final data = result['data'];
        final List<ExportOrder> exportOrders = [];

        if (data is List) {
          for (final item in data) {
            exportOrders.add(ExportOrder.fromJson(item));
          }
        }

        emit(StockExportLoaded(exportOrders: exportOrders));
      } else {
        final errorMessage = result['message'] ?? 'Không thể tải danh sách đơn xuất';
        print('DEBUG: LoadExportOrders failed: $errorMessage');
        emit(const StockInitial());
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn xuất', e, stackTrace);
      emit(const StockInitial());
    }
  }

  Future<void> _onSelectExportOrder(
    SelectExportOrder event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockExportLoaded) return;

    final currentState = state as StockExportLoaded;

    try {
      final selectedOrder = currentState.exportOrders
          .firstWhere((order) => order.id == event.exportId);

      emit(currentState.copyWith(
        selectedExportOrder: selectedOrder,
        scannedExportItems: [],
      ));
    } catch (e, stackTrace) {
      logError('Lỗi chọn đơn xuất', e, stackTrace);
      emit(StockError('Không thể chọn đơn xuất: ${e.toString()}'));
    }
  }

  Future<void> _onScanExportDevice(
    ScanExportDevice event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockExportLoaded) return;

    final currentState = state as StockExportLoaded;
    final selectedOrder = currentState.selectedExportOrder;

    if (selectedOrder == null) {
      emit(const StockError('Chưa chọn đơn xuất'));
      return;
    }

    try {
      final deviceInfo = _parseQRData(event.qrData);

      if (deviceInfo == null) {
        emit(const StockError('Mã QR không hợp lệ'));
        return;
      }

      final result = await _exportWarehouseService.scanExportDevice(
        selectedOrder.id,
        deviceInfo['serial_number']!,
      );

      if (result['success']) {
        final newScannedItems = List<ExportItem>.from(currentState.scannedExportItems);
        newScannedItems.add(ExportItem(
          serialNumber: deviceInfo['serial_number']!,
          templateId: deviceInfo['template_id']!,
          batchProductionId: deviceInfo['batch_production_id']!,
        ));

        emit(currentState.copyWith(
          scannedExportItems: newScannedItems,
        ));
      } else {
        emit(StockError(result['message'] ?? 'Lỗi quét thiết bị xuất'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị xuất kho', e, stackTrace);
      emit(StockError('Không thể quét thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteExportOrder(
    CompleteExportOrder event,
    Emitter<StockState> emit,
  ) async {
    if (state is! StockExportLoaded) return;

    final currentState = state as StockExportLoaded;
    final selectedOrder = currentState.selectedExportOrder;

    if (selectedOrder == null) {
      emit(const StockError('Chưa chọn đơn xuất'));
      return;
    }

    if (currentState.scannedExportItems.isEmpty) {
      emit(const StockError('Chưa quét thiết bị nào'));
      return;
    }

    try {
      emit(const StockLoading());

      final Map<String, List<ExportItem>> groupedItems = {};
      for (final item in currentState.scannedExportItems) {
        groupedItems.putIfAbsent(item.templateId, () => []).add(item);
      }

      final List<Map<String, dynamic>> listProduct = [];
      groupedItems.forEach((templateId, items) {
        listProduct.add({
          'template_id': templateId,
          'list_serial': items.map((item) => {
            'batch_production_id': item.batchProductionId,
            'serial_number': item.serialNumber,
          }).toList(),
          'quantity': items.length,
        });
      });

      final result = await _exportWarehouseService.completeExportOrder(
        exportId: selectedOrder.exportNumber,
        orderId: selectedOrder.id,
        listProduct: listProduct,
      );

      if (result['success']) {
        emit(const StockExportLoaded(exportOrders: []));
      } else {
        emit(StockError(result['message'] ?? 'Không thể hoàn thành đơn xuất'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi ho��n thành đơn xuất', e, stackTrace);
      emit(StockError('Không thể hoàn thành đơn xuất: ${e.toString()}'));
    }
  }

  Map<String, String>? _parseQRData(String qrData) {
    try {
      if (qrData.contains('|')) {
        final parts = qrData.split('|');
        if (parts.length >= 3) {
          return {
            'serial_number': parts[0],
            'template_id': parts[1],
            'batch_production_id': parts[2],
          };
        }
      }
      return null;
    } catch (e) {
      logError('Lỗi phân tích mã QR', e, null);
      return null;
    }
  }

  bool _checkOrderComplete(
      StockOrder order,
      Map<String, bool> scannedItems,
      Map<String, int> scannedCounts,
      ) {
    if (order.type == 'stockIn') {
      int totalDevices = 0;
      for (final deviceType in order.deviceTypes) {
        totalDevices += deviceType.devices?.length ?? 0;
      }
      return scannedItems.length >= totalDevices;
    } else {
      for (final deviceType in order.deviceTypes) {
        final scannedCount = scannedCounts[deviceType.type] ?? 0;
        if (scannedCount < deviceType.quantity) {
          return false;
        }
      }
      return true;
    }
  }
}
