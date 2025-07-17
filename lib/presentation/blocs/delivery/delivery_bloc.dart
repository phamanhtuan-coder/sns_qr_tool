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
    print('DEBUG: DeliveryBloc constructor - DeliveryService: $_deliveryService');

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
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Starting');
      emit(const DeliveryLoading());

      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Calling _deliveryService.getAssignedOrders()');
      final orders = await _deliveryService.getAssignedOrders();
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Received ${orders.length} orders');

      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Getting current location');
      final currentLocation = await _deliveryService.getCurrentLocation();
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Current location: $currentLocation');

      emit(DeliveryLoaded(
        orders: orders,
        currentLocation: currentLocation,
      ));
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Emitted DeliveryLoaded state');
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Error: $e');
      print('DEBUG: DeliveryBloc._onLoadDeliveryOrders() - Stack trace: $stackTrace');
      logError('Lỗi tải danh sách đơn giao hàng', e, stackTrace);
      emit(DeliveryError('Không thể tải danh sách đơn giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onSelectDeliveryOrder(
      SelectDeliveryOrder event,
      Emitter<DeliveryState> emit,
      ) async {
    print('DEBUG: DeliveryBloc._onSelectDeliveryOrder() - OrderId: ${event.orderId}');

    if (state is! DeliveryLoaded) {
      print('DEBUG: DeliveryBloc._onSelectDeliveryOrder() - State is not DeliveryLoaded, returning');
      return;
    }

    final currentState = state as DeliveryLoaded;

    try {
      final selectedOrder = currentState.orders
          .firstWhere((order) => order.id == event.orderId);
      print('DEBUG: DeliveryBloc._onSelectDeliveryOrder() - Found order: ${selectedOrder.id}');

      emit(currentState.copyWith(
        selectedOrder: selectedOrder,
      ));
      print('DEBUG: DeliveryBloc._onSelectDeliveryOrder() - Emitted updated state');
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onSelectDeliveryOrder() - Error: $e');
      logError('Lỗi chọn đơn giao hàng', e, stackTrace);
      emit(DeliveryError('Không thể chọn đơn giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onStartDeliveryOrder(
      StartDeliveryOrder event,
      Emitter<DeliveryState> emit,
      ) async {
    print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - OrderId: ${event.orderId}');

    if (state is! DeliveryLoaded) {
      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - State is not DeliveryLoaded, returning');
      return;
    }

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));
      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Set loading to true');

      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Calling _deliveryService.startDelivery()');
      final result = await _deliveryService.startDelivery(event.orderId);
      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Service result: $result');

      if (result['success']) {
        print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Success, updating order status');

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
        print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Emitted updated state');
      } else {
        print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Failed: ${result['message']}');
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể bắt đầu giao hàng'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Error: $e');
      print('DEBUG: DeliveryBloc._onStartDeliveryOrder() - Stack trace: $stackTrace');
      logError('Lỗi bắt đầu giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Không thể bắt đầu giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteDeliveryOrder(
      CompleteDeliveryOrder event,
      Emitter<DeliveryState> emit,
      ) async {
    print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - OrderId: ${event.orderId}');

    if (state is! DeliveryLoaded) {
      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - State is not DeliveryLoaded, returning');
      return;
    }

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));
      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Set loading to true');

      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Calling _deliveryService.completeDelivery()');
      final result = await _deliveryService.completeDelivery(
        orderId: event.orderId,
        photoPath: event.photoPath,
        note: event.note,
        isSuccessful: event.isSuccessful,
      );
      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Service result: $result');

      if (result['success']) {
        print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Success, updating order status');

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
        print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Emitted updated state');
      } else {
        print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Failed: ${result['message']}');
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể hoàn thành giao hàng'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Error: $e');
      print('DEBUG: DeliveryBloc._onCompleteDeliveryOrder() - Stack trace: $stackTrace');
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
    print('DEBUG: DeliveryBloc._onResetDelivery() - Resetting state');
    emit(const DeliveryInitial());
  }

  Future<void> _onStartShippingOrder(
      StartShippingOrder event,
      Emitter<DeliveryState> emit,
      ) async {
    print('DEBUG: DeliveryBloc._onStartShippingOrder() - OrderId: ${event.orderId}');

    if (state is! DeliveryLoaded) {
      print('DEBUG: DeliveryBloc._onStartShippingOrder() - State is not DeliveryLoaded, returning');
      return;
    }

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));
      print('DEBUG: DeliveryBloc._onStartShippingOrder() - Set loading to true');

      print('DEBUG: DeliveryBloc._onStartShippingOrder() - Calling _deliveryService.startShippingOrder()');
      final result = await _deliveryService.startShippingOrder(event.orderId);
      print('DEBUG: DeliveryBloc._onStartShippingOrder() - Service result: $result');

      if (result['success'] == true) {
        print('DEBUG: DeliveryBloc._onStartShippingOrder() - Success, reloading orders');

        // Reload orders to get updated status
        final orders = await _deliveryService.getAssignedOrders();
        emit(currentState.copyWith(
          orders: orders,
          isLoading: false,
        ));
        print('DEBUG: DeliveryBloc._onStartShippingOrder() - Emitted updated state with ${orders.length} orders');
      } else {
        print('DEBUG: DeliveryBloc._onStartShippingOrder() - Failed: ${result['message']}');
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể bắt đầu giao hàng'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onStartShippingOrder() - Error: $e');
      print('DEBUG: DeliveryBloc._onStartShippingOrder() - Stack trace: $stackTrace');
      logError('Lỗi bắt đầu giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Lỗi bắt đầu giao hàng: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmShippingOrder(
      ConfirmShippingOrder event,
      Emitter<DeliveryState> emit,
      ) async {
    print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - OrderId: ${event.orderId}');
    print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Image proof length: ${event.imageProofBase64.length}');

    if (state is! DeliveryLoaded) {
      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - State is not DeliveryLoaded, returning');
      return;
    }

    final currentState = state as DeliveryLoaded;

    try {
      emit(currentState.copyWith(isLoading: true));
      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Set loading to true');

      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Calling _deliveryService.confirmShippingOrder()');
      final result = await _deliveryService.confirmShippingOrder(
        orderId: event.orderId,
        imageProofBase64: event.imageProofBase64,
      );
      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Service result: $result');

      if (result['success'] == true) {
        print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Success, reloading orders');

        // Reload orders to get updated status
        final orders = await _deliveryService.getAssignedOrders();
        emit(currentState.copyWith(
          orders: orders,
          isLoading: false,
        ));
        print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Emitted updated state with ${orders.length} orders');
      } else {
        print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Failed: ${result['message']}');
        emit(currentState.copyWith(isLoading: false));
        emit(DeliveryError(result['message'] ?? 'Không thể xác nhận hoàn thành giao hàng'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Error: $e');
      print('DEBUG: DeliveryBloc._onConfirmShippingOrder() - Stack trace: $stackTrace');
      logError('Lỗi xác nhận hoàn thành giao hàng', e, stackTrace);
      emit(currentState.copyWith(isLoading: false));
      emit(DeliveryError('Lỗi xác nhận hoàn thành giao hàng: ${e.toString()}'));
    }
  }
}