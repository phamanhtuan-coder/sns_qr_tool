part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockOrders extends StockEvent {
  final String type; // 'stockIn' or 'stockOut'

  const LoadStockOrders(this.type);

  @override
  List<Object?> get props => [type];
}

class SelectOrder extends StockEvent {
  final String orderId;

  const SelectOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ScanDevice extends StockEvent {
  final String deviceId;

  const ScanDevice(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class CompleteOrder extends StockEvent {
  const CompleteOrder();
}

class ResetStock extends StockEvent {
  const ResetStock();
}

// New events for import warehouse
class StartImportOrder extends StockEvent {
  final String importId;

  const StartImportOrder(this.importId);

  @override
  List<Object?> get props => [importId];
}

class LoadImportOrders extends StockEvent {
  const LoadImportOrders();
}

class SelectImportOrder extends StockEvent {
  final String importId;

  const SelectImportOrder(this.importId);

  @override
  List<Object?> get props => [importId];
}

class ScanImportDevice extends StockEvent {
  final String qrData;

  const ScanImportDevice(this.qrData);

  @override
  List<Object?> get props => [qrData];
}
