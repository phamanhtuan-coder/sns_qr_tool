import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';


abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {
  const StockInitial();
}

class StockLoading extends StockState {
  const StockLoading();
}

class StockLoaded extends StockState {
  final List<StockOrder> orders;
  final StockOrder? selectedOrder;
  final Map<String, bool> scannedItems;
  final Map<String, int> scannedCounts;
  final List<Device> scannedDevices;
  final bool isOrderComplete;
  final bool isLoading;

  const StockLoaded({
    required this.orders,
    this.selectedOrder,
    this.scannedItems = const {},
    this.scannedCounts = const {},
    this.scannedDevices = const [],
    this.isOrderComplete = false,
    this.isLoading = false,
  });

  StockLoaded copyWith({
    List<StockOrder>? orders,
    StockOrder? selectedOrder,
    Map<String, bool>? scannedItems,
    Map<String, int>? scannedCounts,
    List<Device>? scannedDevices,
    bool? isOrderComplete,
    bool? isLoading,
  }) {
    return StockLoaded(
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder,
      scannedItems: scannedItems ?? this.scannedItems,
      scannedCounts: scannedCounts ?? this.scannedCounts,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      isOrderComplete: isOrderComplete ?? this.isOrderComplete,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    orders,
    selectedOrder,
    scannedItems,
    scannedCounts,
    scannedDevices,
    isOrderComplete,
    isLoading,
  ];
}

// New state for import warehouse
class StockImportLoaded extends StockState {
  final List<ImportOrder> importOrders;
  final ImportOrder? selectedImportOrder;
  final List<ImportOrderItem> scannedImportItems;

  const StockImportLoaded({
    required this.importOrders,
    this.selectedImportOrder,
    this.scannedImportItems = const [],
  });

  StockImportLoaded copyWith({
    List<ImportOrder>? importOrders,
    ImportOrder? selectedImportOrder,
    List<ImportOrderItem>? scannedImportItems,
  }) {
    return StockImportLoaded(
      importOrders: importOrders ?? this.importOrders,
      selectedImportOrder: selectedImportOrder,
      scannedImportItems: scannedImportItems ?? this.scannedImportItems,
    );
  }

  @override
  List<Object?> get props => [
    importOrders,
    selectedImportOrder,
    scannedImportItems,
  ];
}

// New state for export warehouse
class StockExportLoaded extends StockState {
  final List<ExportOrder> exportOrders;
  final ExportOrder? selectedExportOrder;
  final List<ExportItem> scannedExportItems;

  const StockExportLoaded({
    required this.exportOrders,
    this.selectedExportOrder,
    this.scannedExportItems = const [],
  });

  StockExportLoaded copyWith({
    List<ExportOrder>? exportOrders,
    ExportOrder? selectedExportOrder,
    List<ExportItem>? scannedExportItems,
  }) {
    return StockExportLoaded(
      exportOrders: exportOrders ?? this.exportOrders,
      selectedExportOrder: selectedExportOrder,
      scannedExportItems: scannedExportItems ?? this.scannedExportItems,
    );
  }

  @override
  List<Object?> get props => [
    exportOrders,
    selectedExportOrder,
    scannedExportItems,
  ];
}
class StockError extends StockState {

  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}