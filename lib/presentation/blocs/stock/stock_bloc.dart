import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/services/stock_service.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockService _stockService;

  StockBloc(this._stockService) : super(const StockInitial()) {
    on<LoadStockOrders>(_onLoadStockOrders);
    on<SelectOrder>(_onSelectOrder);
    on<ScanDevice>(_onScanDevice);
    on<CompleteOrder>(_onCompleteOrder);
    on<ResetStock>(_onResetStock);
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