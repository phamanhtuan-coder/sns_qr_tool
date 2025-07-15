// Update the StockExportLoaded state in stock_state.dart

import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_detail.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_process.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/models/enhanced_export_item.dart'; // Add this import

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
  final ImportOrderDetail? importOrderDetail; // Add detailed order info
  final List<ImportOrderProcess> processItems; // Process items that need to be scanned
  final ImportOrder? selectedImportOrder;
  final bool isLoadingDetails; // Loading state for order details
  final List<ImportOrderItem> scannedImportItems;

  const StockImportLoaded({
    required this.importOrders,
    this.importOrderDetail,
    this.processItems = const [],
    this.selectedImportOrder,
    this.isLoadingDetails = false,
    this.scannedImportItems = const [],
  });

  StockImportLoaded copyWith({
    List<ImportOrder>? importOrders,
    ImportOrderDetail? importOrderDetail,
    List<ImportOrderProcess>? processItems,
    ImportOrder? selectedImportOrder,
    bool? isLoadingDetails,
    List<ImportOrderItem>? scannedImportItems,
  }) {
    return StockImportLoaded(
      importOrders: importOrders ?? this.importOrders,
      importOrderDetail: importOrderDetail ?? this.importOrderDetail,
      processItems: processItems ?? this.processItems,
      selectedImportOrder: selectedImportOrder,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      scannedImportItems: scannedImportItems ?? this.scannedImportItems,
    );
  }

  // Helper methods
  int getTotalDevicesToScan() => processItems.fold(0, (sum, item) => sum + item.totalSerialNeed);

  int getTotalScannedDevices() => processItems.fold(0, (sum, item) => sum + item.totalSerialImported);

  bool isOrderComplete() => processItems.every((item) => item.isCompleted);

  double getProgressPercentage() {
    final total = getTotalDevicesToScan();
    if (total == 0) return 0.0;
    return getTotalScannedDevices() / total;
  }

  @override
  List<Object?> get props => [
    importOrders,
    importOrderDetail,
    processItems,
    selectedImportOrder,
    isLoadingDetails,
    scannedImportItems,
  ];
}

// Enhanced state for export warehouse with detailed item tracking
class StockExportLoaded extends StockState {
  final List<ExportOrder> exportOrders;
  final ExportOrder? selectedExportOrder;
  final List<EnhancedExportItem> scannedExportItems; // Changed to EnhancedExportItem
  final Map<String, int> scannedItemsCounts; // Track counts by template_id
  final Map<String, List<EnhancedExportItem>> groupedScannedItems; // Group by device type
  final bool isLoadingDetails; // Loading state for details
  final dynamic exportOrderDetail; // Export order detail data
  final dynamic exportProcessItems; // Export process/progress data

  const StockExportLoaded({
    required this.exportOrders,
    this.selectedExportOrder,
    this.scannedExportItems = const [],
    this.scannedItemsCounts = const {},
    this.groupedScannedItems = const {},
    this.isLoadingDetails = false,
    this.exportOrderDetail,
    this.exportProcessItems,
  });

  StockExportLoaded copyWith({
    List<ExportOrder>? exportOrders,
    ExportOrder? selectedExportOrder,
    List<EnhancedExportItem>? scannedExportItems,
    Map<String, int>? scannedItemsCounts,
    Map<String, List<EnhancedExportItem>>? groupedScannedItems,
    bool? isLoadingDetails,
    dynamic exportOrderDetail,
    dynamic exportProcessItems,
  }) {
    return StockExportLoaded(
      exportOrders: exportOrders ?? this.exportOrders,
      selectedExportOrder: selectedExportOrder,
      scannedExportItems: scannedExportItems ?? this.scannedExportItems,
      scannedItemsCounts: scannedItemsCounts ?? this.scannedItemsCounts,
      groupedScannedItems: groupedScannedItems ?? this.groupedScannedItems,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      exportOrderDetail: exportOrderDetail ?? this.exportOrderDetail,
      exportProcessItems: exportProcessItems ?? this.exportProcessItems,
    );
  }

  @override
  List<Object?> get props => [
    exportOrders,
    selectedExportOrder,
    scannedExportItems,
    scannedItemsCounts,
    groupedScannedItems,
    isLoadingDetails,
    exportOrderDetail,
    exportProcessItems,
  ];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}