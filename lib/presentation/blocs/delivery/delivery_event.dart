part of 'delivery_bloc.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryOrders extends DeliveryEvent {
  const LoadDeliveryOrders();
}

class SelectDeliveryOrder extends DeliveryEvent {
  final String orderId;

  const SelectDeliveryOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class StartDeliveryOrder extends DeliveryEvent {
  final String orderId;

  const StartDeliveryOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CompleteDeliveryOrder extends DeliveryEvent {
  final String orderId;
  final String photoPath;
  final String note;
  final bool isSuccessful;

  const CompleteDeliveryOrder({
    required this.orderId,
    required this.photoPath,
    required this.note,
    required this.isSuccessful,
  });

  @override
  List<Object?> get props => [orderId, photoPath, note, isSuccessful];
}

class UpdateLocation extends DeliveryEvent {
  final Position position;

  const UpdateLocation(this.position);

  @override
  List<Object?> get props => [position];
}

class ResetDelivery extends DeliveryEvent {
  const ResetDelivery();
}
