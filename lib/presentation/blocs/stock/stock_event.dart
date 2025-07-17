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

class ResetStock extends StockEvent {
  const ResetStock();
}

// Import-specific events
class LoadImportOrders extends StockEvent {
  const LoadImportOrders();
}

class SelectImportOrder extends StockEvent {
  final String importId;

  const SelectImportOrder(this.importId);

  @override
  List<Object?> get props => [importId];
}

class StartImportOrder extends StockEvent {
  final String importId;

  const StartImportOrder(this.importId);

  @override
  List<Object?> get props => [importId];
}

class LoadImportProgress extends StockEvent {
  final String importId;

  const LoadImportProgress(this.importId);

  @override
  List<Object?> get props => [importId];
}

class ProcessImportItem extends StockEvent {
  final String importId;
  final String serialNumber;
  final String? batchProductionId;
  final String? templateId;

  const ProcessImportItem({
    required this.importId,
    required this.serialNumber,
    this.batchProductionId,
    this.templateId,
  });

  @override
  List<Object?> get props => [importId, serialNumber, batchProductionId, templateId];
}

// Export-specific events
class LoadExportOrders extends StockEvent {
  const LoadExportOrders();
}

class SelectExportOrder extends StockEvent {
  final String exportId;

  const SelectExportOrder(this.exportId);

  @override
  List<Object?> get props => [exportId];
}

class StartExportOrder extends StockEvent {
  final String exportId;

  const StartExportOrder(this.exportId);

  @override
  List<Object?> get props => [exportId];
}

class LoadExportProgress extends StockEvent {
  final String exportId;

  const LoadExportProgress(this.exportId);

  @override
  List<Object?> get props => [exportId];
}

class ProcessExportItem extends StockEvent {
  final String exportId;
  final String orderId;
  final String serialNumber;
  final String? batchProductionId;
  final String? templateId;

  const ProcessExportItem({
    required this.exportId,
    required this.orderId,
    required this.serialNumber,
    this.batchProductionId,
    this.templateId,
  });

  @override
  List<Object?> get props => [exportId, orderId, serialNumber, batchProductionId, templateId];
}

class RefreshDeviceList extends StockEvent {
  const RefreshDeviceList();

  @override
  List<Object?> get props => [];
}