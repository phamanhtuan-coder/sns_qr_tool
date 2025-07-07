// Update the StockExportLoaded state in stock_state.dart

import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
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

// Enhanced state for export warehouse with detailed item tracking
class StockExportLoaded extends StockState {
  final List<ExportOrder> exportOrders;
  final ExportOrder? selectedExportOrder;
  final List<EnhancedExportItem> scannedExportItems; // Changed to EnhancedExportItem
  final Map<String, int> scannedItemsCounts; // Track counts by template_id
  final Map<String, List<EnhancedExportItem>> groupedScannedItems; // Group by device type

  const StockExportLoaded({
    required this.exportOrders,
    this.selectedExportOrder,
    this.scannedExportItems = const [],
    this.scannedItemsCounts = const {},
    this.groupedScannedItems = const {},
  });

  StockExportLoaded copyWith({
    List<ExportOrder>? exportOrders,
    ExportOrder? selectedExportOrder,
    List<EnhancedExportItem>? scannedExportItems,
    Map<String, int>? scannedItemsCounts,
    Map<String, List<EnhancedExportItem>>? groupedScannedItems,
  }) {
    // Auto-calculate counts and grouping when items change
    if (scannedExportItems != null) {
      final newCounts = <String, int>{};
      final newGrouped = <String, List<EnhancedExportItem>>{};

      for (final item in scannedExportItems) {
        // Count by template_id
        newCounts[item.templateId] = (newCounts[item.templateId] ?? 0) + 1;

        // Group by device type
        newGrouped.putIfAbsent(item.deviceType, () => []).add(item);
      }

      return StockExportLoaded(
        exportOrders: exportOrders ?? this.exportOrders,
        selectedExportOrder: selectedExportOrder,
        scannedExportItems: scannedExportItems,
        scannedItemsCounts: newCounts,
        groupedScannedItems: newGrouped,
      );
    }

    return StockExportLoaded(
      exportOrders: exportOrders ?? this.exportOrders,
      selectedExportOrder: selectedExportOrder,
      scannedExportItems: scannedExportItems ?? this.scannedExportItems,
      scannedItemsCounts: scannedItemsCounts ?? this.scannedItemsCounts,
      groupedScannedItems: groupedScannedItems ?? this.groupedScannedItems,
    );
  }

  // Helper methods
  int getTotalScannedCount() => scannedExportItems.length;

  int getScannedCountForTemplate(String templateId) =>
      scannedItemsCounts[templateId] ?? 0;

  List<EnhancedExportItem> getItemsForDeviceType(String deviceType) =>
      groupedScannedItems[deviceType] ?? [];

  List<String> getScannedDeviceTypes() => groupedScannedItems.keys.toList();

  // Convert enhanced items back to original format for API calls
  List<ExportItem> toOriginalExportItems() {
    return scannedExportItems.map((item) => item.toExportItem()).toList();
  }

  @override
  List<Object?> get props => [
    exportOrders,
    selectedExportOrder,
    scannedExportItems,
    scannedItemsCounts,
    groupedScannedItems,
  ];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}