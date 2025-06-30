part of 'delivery_bloc.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

class DeliveryLoaded extends DeliveryState {
  final List<DeliveryOrder> orders;
  final DeliveryOrder? selectedOrder;
  final Position? currentLocation;
  final bool isLoading;

  const DeliveryLoaded({
    required this.orders,
    this.selectedOrder,
    this.currentLocation,
    this.isLoading = false,
  });

  DeliveryLoaded copyWith({
    List<DeliveryOrder>? orders,
    DeliveryOrder? selectedOrder,
    Position? currentLocation,
    bool? isLoading,
  }) {
    return DeliveryLoaded(
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [orders, selectedOrder, currentLocation, isLoading];
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}
