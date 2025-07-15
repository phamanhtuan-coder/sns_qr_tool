import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service_extension.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'delivery_event.dart';
part 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryBloc(this._deliveryService) : super(const DeliveryInitial()) {
    on<LoadDeliveryOrders>(_onLoadDeliveryOrders);
    on<SelectDeliveryOrder>(_onSelectDeliveryOrder);
    on<StartDeliveryOrder>(_onStartDeliveryOrder);
    on<CompleteDeliveryOrder>(_onCompleteDeliveryOrder);
    on<UpdateLocation>(_onUpdateLocation);
    on<ResetDelivery>(_onResetDelivery);
    on<StartShippingOrder>(_onStartShippingOrder);
    on<ConfirmShippingOrder>(_onConfirmShippingOrder);
  }

  Future<void> _onLoadDeliveryOrders(
    LoadDeliveryOrders event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      emit(const DeliveryLoading());

      final orders = await _deliveryService.getAssignedOrders();
      final currentLocation = await _deliveryService.getCurrentLocation();

      emit(DeliveryLoaded(
        orders: orders,
        currentLocation: currentLocation,
      ));
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn giao hàng', e, stackTrace);
      emit(DeliveryError('Không thể tải danh sách đơn giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onSelectDeliveryOrder(
    SelectDeliveryOrder event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    try {
      final selectedOrder = currentState.orders
          .firstWhere((order) => order.id == event.orderId);

      emit(currentState.copyWith(
        selectedOrder: selectedOrder,
      ));
    } catch (e, stackTrace) {
      logError('Lỗi chọn đơn giao hàng', e, stackTrace);
      emit(DeliveryError('Không thể chọn đơn giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onStartDeliveryOrder(
    StartDeliveryOrder event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));

      final result = await _deliveryService.startDelivery(event.orderId);

      if (result['success']) {
        // Update the order status in the list
        final updatedOrders = currentState.orders.map((order) {
          if (order.id == event.orderId) {
            return order.copyWith(
              status: DeliveryStatus.started,
              startedAt: DateTime.now(),
            );
          }
          return order;
        }).toList();

        final updatedSelectedOrder = currentState.selectedOrder?.id == event.orderId
            ? currentState.selectedOrder?.copyWith(
                status: DeliveryStatus.started,
                startedAt: DateTime.now(),
              )
            : currentState.selectedOrder;

        emit(currentState.copyWith(
          orders: updatedOrders,
          selectedOrder: updatedSelectedOrder,
          isLoading: false,
        ));
      } else {
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể bắt đầu giao hàng'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Không thể bắt đầu giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteDeliveryOrder(
    CompleteDeliveryOrder event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));

      final result = await _deliveryService.completeDelivery(
        orderId: event.orderId,
        photoPath: event.photoPath,
        note: event.note,
        isSuccessful: event.isSuccessful,
      );

      if (result['success']) {
        final newStatus = event.isSuccessful
            ? DeliveryStatus.delivered
            : DeliveryStatus.failed;

        // Update the order status in the list
        final updatedOrders = currentState.orders.map((order) {
          if (order.id == event.orderId) {
            return order.copyWith(
              status: newStatus,
              deliveredAt: DateTime.now(),
              deliveryPhoto: event.photoPath,
              deliveryNote: event.note,
            );
          }
          return order;
        }).toList();

        final updatedSelectedOrder = currentState.selectedOrder?.id == event.orderId
            ? currentState.selectedOrder?.copyWith(
                status: newStatus,
                deliveredAt: DateTime.now(),
                deliveryPhoto: event.photoPath,
                deliveryNote: event.note,
              )
            : currentState.selectedOrder;

        emit(currentState.copyWith(
          orders: updatedOrders,
          selectedOrder: updatedSelectedOrder,
          isLoading: false,
        ));
      } else {
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể hoàn thành giao hàng'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi hoàn thành giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Không thể hoàn thành giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    emit(currentState.copyWith(
      currentLocation: event.position,
    ));
  }

  Future<void> _onResetDelivery(
    ResetDelivery event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryInitial());
  }

  Future<void> _onStartShippingOrder(
    StartShippingOrder event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));

      final result = await _deliveryService.startShippingOrder(event.orderId);

      if (result['success'] == true) {
        // Reload orders to get updated status
        final orders = await _deliveryService.getAssignedOrders();
        emit(currentState.copyWith(
          orders: orders,
          isLoading: false,
        ));
      } else {
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể bắt đầu giao hàng'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Lỗi bắt đầu giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmShippingOrder(
    ConfirmShippingOrder event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoaded) return;

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));

      final result = await _deliveryService.confirmShippingOrder(
        orderId: event.orderId,
        imageProofBase64: event.imageProofBase64,
      );

      if (result['success'] == true) {
        // Reload orders to get updated status
        final orders = await _deliveryService.getAssignedOrders();
        emit(currentState.copyWith(
          orders: orders,
          isLoading: false,
        ));
      } else {
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể xác nhận hoàn thành giao hàng'));
      }
    } catch (e, stackTrace) {
      logError('Lỗi xác nhận hoàn thành giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Lỗi xác nhận hoàn thành giao hàng: ${e.toString()}'));
    }
  }
}
