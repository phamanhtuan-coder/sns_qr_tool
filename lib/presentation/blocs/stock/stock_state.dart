import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_detail.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_process.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/models/enhanced_export_item.dart';

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

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}

// Import States
class StockImportLoaded extends StockState {
  final List<ImportOrder> importOrders;

  const StockImportLoaded({
    required this.importOrders,
  });

  @override
  List<Object?> get props => [importOrders];
}

class StockImportOrderNotStarted extends StockState {
  final String importId;
  final Map<String, dynamic> orderDetails;

  const StockImportOrderNotStarted({
    required this.importId,
    required this.orderDetails,
  });

  @override
  List<Object?> get props => [importId, orderDetails];
}

class StockImportInProgress extends StockState {
  final List<ImportOrderProcess> items;
  final String orderId;

  const StockImportInProgress({
    required this.items,
    required this.orderId,
  });

  bool get isComplete => items.every((item) => item.isCompleted);
  int get totalScanned => items.fold(0, (sum, item) => sum + item.totalSerialImported);
  int get totalNeeded => items.fold(0, (sum, item) => sum + item.totalSerialNeed);
  double get progress => totalNeeded > 0 ? totalScanned / totalNeeded : 0.0;

  // Get detailed device information for display
  String getDeviceListDisplay() {
    if (items.isEmpty) return 'Không có thiết bị cần nhập';

    return items.map((item) {
      final progress = '${item.totalSerialImported}/${item.totalSerialNeed}';
      final status = item.isCompleted ? '✓' : '○';
      return '$status ${item.productName} ($progress)';
    }).join('\n');
  }

  List<String> getIncompleteDevices() {
    return items
        .where((item) => !item.isCompleted)
        .map((item) => item.productName)
        .toList();
  }

  @override
  List<Object> get props => [items, orderId];
}

// Export States
class StockExportLoaded extends StockState {
  final List<ExportOrder> exportOrders;
  final ExportOrder? selectedExportOrder;
  final List<EnhancedExportItem> scannedExportItems;
  final Map<String, int> scannedItemsCounts;
  final Map<String, List<EnhancedExportItem>> groupedScannedItems;
  final bool isLoadingDetails;
  final dynamic exportOrderDetail;
  final dynamic exportProcessItems;

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

class StockExportOrderNotStarted extends StockState {
  final String exportId;
  final Map<String, dynamic> orderDetails;

  const StockExportOrderNotStarted({
    required this.exportId,
    required this.orderDetails,
  });

  @override
  List<Object?> get props => [exportId, orderDetails];
}

class StockExportOrderStarted extends StockState {
  final String exportId;
  final Map<String, dynamic> orderDetails;

  const StockExportOrderStarted({
    required this.exportId,
    required this.orderDetails,
  });

  @override
  List<Object?> get props => [exportId, orderDetails];
}

// Common States
class StockProgressLoaded extends StockState {
  final String orderId;
  final Map<String, dynamic> progressData;
  final int scannedCount;
  final int totalCount;
  final bool canComplete;

  const StockProgressLoaded({
    required this.orderId,
    required this.progressData,
    required this.scannedCount,
    required this.totalCount,
    required this.canComplete,
  });

  @override
  List<Object?> get props => [orderId, progressData, scannedCount, totalCount, canComplete];
}

class StockItemProcessed extends StockState {
  final String orderId;
  final String serialNumber;
  final Map<String, dynamic> itemData;
  final Map<String, dynamic> progress;

  const StockItemProcessed({
    required this.orderId,
    required this.serialNumber,
    required this.itemData,
    required this.progress,
  });

  @override
  List<Object?> get props => [orderId, serialNumber, itemData, progress];
}

// Legacy States (kept for compatibility)
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