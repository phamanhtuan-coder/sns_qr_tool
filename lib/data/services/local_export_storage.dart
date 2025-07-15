import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class LocalExportStorage {
  static const String _keyExportProgress = 'export_progress_';
  static const String _keyActiveExports = 'active_exports';
  static const String _keyCompletedExports = 'completed_exports';

  /// Save export progress locally
  Future<bool> saveExportProgress(String exportId, LocalExportProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyExportProgress$exportId';
      final jsonString = jsonEncode(progress.toJson());

      await prefs.setString(key, jsonString);
      await _updateActiveExportsList(exportId);

      logInfo('Saved export progress locally for export ID: $exportId');
      return true;
    } catch (e) {
      logError('Failed to save export progress locally', e);
      return false;
    }
  }

  /// Get export progress from local storage
  Future<LocalExportProgress?> getExportProgress(String exportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyExportProgress$exportId';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return LocalExportProgress.fromJson(json);
      }
      return null;
    } catch (e) {
      logError('Failed to get export progress from local storage', e);
      return null;
    }
  }

  /// Get all active exports
  Future<List<String>> getActiveExports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyActiveExports);

      if (jsonString != null) {
        final List<dynamic> exportIds = jsonDecode(jsonString);
        return exportIds.cast<String>();
      }
      return [];
    } catch (e) {
      logError('Failed to get active exports from local storage', e);
      return [];
    }
  }

  /// Update active exports list
  Future<void> _updateActiveExportsList(String exportId) async {
    try {
      final activeExports = await getActiveExports();
      if (!activeExports.contains(exportId)) {
        activeExports.add(exportId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyActiveExports, jsonEncode(activeExports));
      }
    } catch (e) {
      logError('Failed to update active exports list', e);
    }
  }

  /// Remove export from active list (when completed or canceled)
  Future<void> removeFromActiveExports(String exportId) async {
    try {
      final activeExports = await getActiveExports();
      activeExports.remove(exportId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveExports, jsonEncode(activeExports));

      // Also remove the progress data
      final key = '$_keyExportProgress$exportId';
      await prefs.remove(key);

      logInfo('Removed export $exportId from active exports');
    } catch (e) {
      logError('Failed to remove export from active exports', e);
    }
  }

  /// Mark export as completed and ready for sync
  Future<bool> markExportCompleted(String exportId, LocalExportProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save to completed exports
      final completedExports = await getCompletedExports();
      completedExports[exportId] = progress;

      await prefs.setString(_keyCompletedExports, jsonEncode(
        completedExports.map((key, value) => MapEntry(key, value.toJson()))
      ));

      // Remove from active exports
      await removeFromActiveExports(exportId);

      logInfo('Marked export $exportId as completed');
      return true;
    } catch (e) {
      logError('Failed to mark export as completed', e);
      return false;
    }
  }

  /// Get completed exports waiting for sync
  Future<Map<String, LocalExportProgress>> getCompletedExports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCompletedExports);

      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return json.map((key, value) => MapEntry(
          key,
          LocalExportProgress.fromJson(value)
        ));
      }
      return {};
    } catch (e) {
      logError('Failed to get completed exports', e);
      return {};
    }
  }

  /// Remove completed export after successful sync
  Future<void> removeCompletedExport(String exportId) async {
    try {
      final completedExports = await getCompletedExports();
      completedExports.remove(exportId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCompletedExports, jsonEncode(
        completedExports.map((key, value) => MapEntry(key, value.toJson()))
      ));

      logInfo('Removed completed export $exportId after sync');
    } catch (e) {
      logError('Failed to remove completed export', e);
    }
  }

  /// Clear all local export data
  Future<void> clearAllExportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_keyExportProgress) ||
            key == _keyActiveExports ||
            key == _keyCompletedExports) {
          await prefs.remove(key);
        }
      }

      logInfo('Cleared all local export data');
    } catch (e) {
      logError('Failed to clear local export data', e);
    }
  }
}

/// Model for tracking local export progress
class LocalExportProgress {
  final String exportId;
  final String orderId;
  final DateTime startedAt;
  final DateTime lastUpdated;
  final List<LocalScannedProduct> scannedProducts;
  final Map<String, int> expectedQuantities; // productId -> expected quantity
  final bool isCompleted;
  final int totalExpectedItems;
  final int totalScannedItems;

  const LocalExportProgress({
    required this.exportId,
    required this.orderId,
    required this.startedAt,
    required this.lastUpdated,
    required this.scannedProducts,
    required this.expectedQuantities,
    required this.isCompleted,
    required this.totalExpectedItems,
    required this.totalScannedItems,
  });

  factory LocalExportProgress.fromJson(Map<String, dynamic> json) {
    return LocalExportProgress(
      exportId: json['export_id'] as String,
      orderId: json['order_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      scannedProducts: (json['scanned_products'] as List<dynamic>)
          .map((item) => LocalScannedProduct.fromJson(item))
          .toList(),
      expectedQuantities: Map<String, int>.from(json['expected_quantities']),
      isCompleted: json['is_completed'] as bool,
      totalExpectedItems: json['total_expected_items'] as int,
      totalScannedItems: json['total_scanned_items'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'export_id': exportId,
      'order_id': orderId,
      'started_at': startedAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'scanned_products': scannedProducts.map((item) => item.toJson()).toList(),
      'expected_quantities': expectedQuantities,
      'is_completed': isCompleted,
      'total_expected_items': totalExpectedItems,
      'total_scanned_items': totalScannedItems,
    };
  }

  /// Check if export is ready to be completed
  bool get canComplete {
    // Check if all expected quantities are met
    for (final entry in expectedQuantities.entries) {
      final productId = entry.key;
      final expectedQty = entry.value;
      final scannedQty = scannedProducts
          .where((p) => p.productId == productId)
          .length;

      if (scannedQty < expectedQty) {
        return false;
      }
    }
    return true;
  }

  /// Get completion percentage
  double get completionPercentage {
    if (totalExpectedItems == 0) return 0.0;
    return (totalScannedItems / totalExpectedItems * 100).clamp(0.0, 100.0);
  }

  /// Add scanned product
  LocalExportProgress addScannedProduct(LocalScannedProduct product) {
    final newScannedProducts = List<LocalScannedProduct>.from(scannedProducts);
    newScannedProducts.add(product);

    return LocalExportProgress(
      exportId: exportId,
      orderId: orderId,
      startedAt: startedAt,
      lastUpdated: DateTime.now(),
      scannedProducts: newScannedProducts,
      expectedQuantities: expectedQuantities,
      isCompleted: isCompleted,
      totalExpectedItems: totalExpectedItems,
      totalScannedItems: newScannedProducts.length,
    );
  }

  /// Mark as completed
  LocalExportProgress markCompleted() {
    return LocalExportProgress(
      exportId: exportId,
      orderId: orderId,
      startedAt: startedAt,
      lastUpdated: DateTime.now(),
      scannedProducts: scannedProducts,
      expectedQuantities: expectedQuantities,
      isCompleted: true,
      totalExpectedItems: totalExpectedItems,
      totalScannedItems: totalScannedItems,
    );
  }
}

/// Model for locally scanned products
class LocalScannedProduct {
  final String serialNumber;
  final String productId;
  final String templateId;
  final String batchProductionId;
  final DateTime scannedAt;
  final Map<String, dynamic>? deviceDetails;

  const LocalScannedProduct({
    required this.serialNumber,
    required this.productId,
    required this.templateId,
    required this.batchProductionId,
    required this.scannedAt,
    this.deviceDetails,
  });

  factory LocalScannedProduct.fromJson(Map<String, dynamic> json) {
    return LocalScannedProduct(
      serialNumber: json['serial_number'] as String,
      productId: json['product_id'] as String,
      templateId: json['template_id'] as String,
      batchProductionId: json['batch_production_id'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      deviceDetails: json['device_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'product_id': productId,
      'template_id': templateId,
      'batch_production_id': batchProductionId,
      'scanned_at': scannedAt.toIso8601String(),
      'device_details': deviceDetails,
    };
  }
}
