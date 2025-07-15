import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';
import 'package:smart_net_qr_scanner/data/services/local_export_storage.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class ExportWarehouseService {
  final ApiClient _apiClient = ApiClient();
  final LocalExportStorage _localStorage = LocalExportStorage();

  /// Get list of unfinished export orders for the current employee
  Future<Map<String, dynamic>> getUnfinishedExportOrders() async {
    try {
      final response = await _apiClient.get('/export-warehouse/invoice-not-finish');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải danh sách đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Start a new export order
  Future<Map<String, dynamic>> startExportOrder(String exportId) async {
    try {
      final response = await _apiClient.patch('/export-warehouse/start', {
        'export_id': exportId,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Bắt đầu đơn xuất thành công',
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'message': 'Bắt đầu đơn xuất thành công',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể bắt đầu đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Scan device for export - Enhanced to return device details
  Future<Map<String, dynamic>> scanExportDevice(String exportId, String serialNumber) async {
    try {
      // First, validate the device can be exported
      final validationResponse = await _validateExportDevice(exportId, serialNumber);

      if (validationResponse['success'] != true) {
        return validationResponse;
      }

      // Get device details from production tracking
      final deviceDetails = await _getDeviceDetails(serialNumber);

      if (deviceDetails['success'] != true) {
        return deviceDetails;
      }

      // Return success with device details
      return {
        'success': true,
        'message': 'Quét thiết bị thành công',
        'data': {
          'serial_number': serialNumber,
          'device_details': deviceDetails['data'],
          'export_id': exportId,
        },
      };
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị xuất kho', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Validate if device can be exported
  Future<Map<String, dynamic>> _validateExportDevice(String exportId, String serialNumber) async {
    try {
      // This would typically check:
      // 1. If device exists and is in stock
      // 2. If device belongs to the export order
      // 3. If device hasn't been exported already

      final response = await _apiClient.post('/export-warehouse/validate-device', {
        'export_id': exportId,
        'serial_number': serialNumber,
      });

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể xác thực thiết bị: ${e.toString()}',
      };
    }
  }

  /// Get device details from production tracking
  Future<Map<String, dynamic>> _getDeviceDetails(String serialNumber) async {
    try {
      final response = await _apiClient.get('/production-tracking/device-details?serial_number=$serialNumber');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      }

      // Mock device details if API is not available
      return {
        'success': true,
        'data': {
          'serial_number': serialNumber,
          'template_id': _extractTemplateId(serialNumber),
          'batch_production_id': _extractBatchId(serialNumber),
          'status': 'in_stock',
          'device_type': _getDeviceType(serialNumber),
          'production_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      };
    } catch (e) {
      // Return mock data if API fails
      return {
        'success': true,
        'data': {
          'serial_number': serialNumber,
          'template_id': _extractTemplateId(serialNumber),
          'batch_production_id': _extractBatchId(serialNumber),
          'status': 'in_stock',
          'device_type': _getDeviceType(serialNumber),
          'production_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      };
    }
  }

  /// Extract template ID from QR data or serial number
  String _extractTemplateId(String serialNumber) {
    // This should match your QR code format: serial|template|batch
    if (serialNumber.contains('|')) {
      final parts = serialNumber.split('|');
      if (parts.length >= 2) {
        return parts[1];
      }
    }

    // Fallback: extract from serial number pattern
    if (serialNumber.startsWith('SERL')) {
      // Extract template from serial pattern
      final match = RegExp(r'[A-Z]+(\d+)').firstMatch(serialNumber);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '1') ?? 1;
        return ((number % 5) + 1).toString(); // Map to template 1-5
      }
    }

    return '1'; // Default template
  }

  /// Extract batch production ID from QR data or serial number
  String _extractBatchId(String serialNumber) {
    // This should match your QR code format: serial|template|batch
    if (serialNumber.contains('|')) {
      final parts = serialNumber.split('|');
      if (parts.length >= 3) {
        return parts[2];
      }
    }

    // Generate mock batch ID
    return 'BTCH${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().year.toString().substring(2)}${serialNumber.substring(serialNumber.length - 8)}';
  }

  /// Get device type name from template ID
  String _getDeviceType(String serialNumber) {
    final templateId = _extractTemplateId(serialNumber);
    switch (templateId) {
      case '1':
        return 'Smart Sensor';
      case '2':
        return 'Control Unit';
      case '3':
        return 'Gateway Device';
      case '4':
        return 'Communication Module';
      case '5':
        return 'Power Module';
      default:
        return 'Unknown Device';
    }
  }

  /// Complete export order with all scanned items
  Future<Map<String, dynamic>> completeExportOrder({
    required int exportId,
    required String orderId,
    required List<Map<String, dynamic>> listProduct,
  }) async {
    try {
      final requestBody = {
        'export_id': exportId,
        'order_id': orderId,
        'list_product': listProduct,
      };

      print('DEBUG: Completing export order with body: $requestBody');

      final response = await _apiClient.patch('/export-warehouse/export-order', requestBody);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Hoàn thành đơn xuất thành công',
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'message': 'Hoàn thành đơn xuất thành công',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể hoàn thành đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi hoàn thành đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get export order details
  Future<Map<String, dynamic>> getExportOrderDetails(String exportId) async {
    try {
      final response = await _apiClient.get('/export-warehouse/detail/$exportId');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải thông tin đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải thông tin đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get export order details by ID
  Future<Map<String, dynamic>> getExportOrderDetail(String exportId) async {
    try {
      print('DEBUG: Getting export order detail for: $exportId');
      final response = await _apiClient.get('/export-warehouse/detail/$exportId');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải chi tiết đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải chi tiết đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get export progress for tracking
  Future<Map<String, dynamic>> getExportProgress(String exportId) async {
    try {
      final response = await _apiClient.get('/export-warehouse/process/$exportId');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải tiến độ xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải tiến độ xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get orders for a specific shipper
  Future<Map<String, dynamic>> getOrdersForShipper(String shipperId) async {
    try {
      // Use the correct shipper endpoint as specified in your router setup
      // Changed from '/shipper/$shipperId' to '/api/order/shipper/$shipperId' to match router configuration
      final response = await _apiClient.get('/api/order/shipper/$shipperId');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải đơn hàng của shipper',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải đơn hàng của shipper', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Export order item using QR data
  Future<Map<String, dynamic>> exportOrderItemFromQr({
    required String exportId,
    required QrData qrData,
  }) async {
    try {
      print('DEBUG: Exporting order item from QR - ExportID: $exportId, QR Data: $qrData');
      final result = await _apiClient.post(
        '/export-warehouse/export-order',
        {
          'export_id': exportId,
          'serial_number': qrData.serialNumber,
          'batch_production_id': qrData.batchProductionId,
          'template_id': qrData.templateId,
        },
      );

      print('DEBUG: Export order item response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không th�� xuất thiết bị',
        };
      }
    } catch (e) {
      print('DEBUG: Error in exportOrderItemFromQr: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Export order item (legacy method - for backward compatibility)
  Future<Map<String, dynamic>> exportOrderItem({
    required String exportId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    final qrData = QrData(
      serialNumber: serialNumber,
      batchProductionId: batchProductionId,
      templateId: templateId,
    );
    return exportOrderItemFromQr(exportId: exportId, qrData: qrData);
  }

  /// Initialize local export process (offline)
  Future<Map<String, dynamic>> initializeLocalExport({
    required String exportId,
    required String orderId,
    required Map<String, int> expectedQuantities,
  }) async {
    try {
      final totalExpectedItems = expectedQuantities.values.fold(0, (sum, qty) => sum + qty);

      final progress = LocalExportProgress(
        exportId: exportId,
        orderId: orderId,
        startedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        scannedProducts: [],
        expectedQuantities: expectedQuantities,
        isCompleted: false,
        totalExpectedItems: totalExpectedItems,
        totalScannedItems: 0,
      );

      final success = await _localStorage.saveExportProgress(exportId, progress);

      if (success) {
        return {
          'success': true,
          'message': 'Khởi tạo quá trình xuất kho thành công',
          'data': progress.toJson(),
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể khởi tạo quá trình xuất kho',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi khởi tạo quá trình xuất kho local', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi khởi tạo: ${e.toString()}',
      };
    }
  }

  /// Scan device for export - LOCAL VERSION (no immediate API call)
  Future<Map<String, dynamic>> scanExportDeviceLocal(String exportId, String serialNumber) async {
    try {
      // Get current progress from local storage
      final currentProgress = await _localStorage.getExportProgress(exportId);
      if (currentProgress == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy tiến trình xuất kho. Vui lòng bắt đầu lại.',
        };
      }

      // Extract product information from serial number
      final templateId = _extractTemplateId(serialNumber);
      final batchProductionId = _extractBatchId(serialNumber);
      final productId = templateId; // Assuming template ID maps to product ID

      // Check if this product is expected in the export order
      if (!currentProgress.expectedQuantities.containsKey(productId)) {
        return {
          'success': false,
          'message': 'Sản phẩm này không có trong đơn xuất kho',
        };
      }

      // Check if we've already scanned enough of this product type
      final alreadyScanned = currentProgress.scannedProducts
          .where((p) => p.productId == productId)
          .length;
      final expectedQty = currentProgress.expectedQuantities[productId]!;

      if (alreadyScanned >= expectedQty) {
        return {
          'success': false,
          'message': 'Đã quét đủ số lượng sản phẩm loại này ($expectedQty)',
        };
      }

      // Check for duplicate serial numbers
      final isDuplicate = currentProgress.scannedProducts
          .any((p) => p.serialNumber == serialNumber);

      if (isDuplicate) {
        return {
          'success': false,
          'message': 'Mã serial này đã được quét trước đó',
        };
      }

      // Create scanned product record
      final scannedProduct = LocalScannedProduct(
        serialNumber: serialNumber,
        productId: productId,
        templateId: templateId,
        batchProductionId: batchProductionId,
        scannedAt: DateTime.now(),
        deviceDetails: {
          'device_type': _getDeviceType(serialNumber),
          'status': 'scanned_for_export',
        },
      );

      // Update progress
      final updatedProgress = currentProgress.addScannedProduct(scannedProduct);

      // Save updated progress
      await _localStorage.saveExportProgress(exportId, updatedProgress);

      return {
        'success': true,
        'message': 'Quét thiết bị thành công',
        'data': {
          'serial_number': serialNumber,
          'product_id': productId,
          'template_id': templateId,
          'batch_production_id': batchProductionId,
          'progress': {
            'current_scanned': updatedProgress.totalScannedItems,
            'total_expected': updatedProgress.totalExpectedItems,
            'percentage': updatedProgress.completionPercentage,
            'can_complete': updatedProgress.canComplete,
          },
          'product_progress': {
            'product_id': productId,
            'scanned': alreadyScanned + 1,
            'expected': expectedQty,
          },
        },
      };
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị xuất kho local', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi quét thiết bị: ${e.toString()}',
      };
    }
  }

  /// Get local export progress
  Future<Map<String, dynamic>> getLocalExportProgress(String exportId) async {
    try {
      final progress = await _localStorage.getExportProgress(exportId);
      if (progress == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy tiến trình xuất kho',
        };
      }

      return {
        'success': true,
        'data': progress.toJson(),
      };
    } catch (e, stackTrace) {
      logError('Lỗi lấy tiến trình xuất kho local', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi lấy tiến trình: ${e.toString()}',
      };
    }
  }

  /// Get all active local exports
  Future<Map<String, dynamic>> getActiveLocalExports() async {
    try {
      final activeExportIds = await _localStorage.getActiveExports();
      final activeExports = <String, LocalExportProgress>{};

      for (final exportId in activeExportIds) {
        final progress = await _localStorage.getExportProgress(exportId);
        if (progress != null) {
          activeExports[exportId] = progress;
        }
      }

      return {
        'success': true,
        'data': activeExports.map((key, value) => MapEntry(key, value.toJson())),
      };
    } catch (e, stackTrace) {
      logError('Lỗi lấy danh sách xuất kho đang hoạt động', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi lấy danh sách: ${e.toString()}',
      };
    }
  }

  /// Complete local export and sync to server
  Future<Map<String, dynamic>> completeLocalExportAndSync(String exportId) async {
    try {
      // Get current progress
      final progress = await _localStorage.getExportProgress(exportId);
      if (progress == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy tiến trình xuất kho',
        };
      }

      // Check if export can be completed
      if (!progress.canComplete) {
        return {
          'success': false,
          'message': 'Chưa quét đủ số lượng sản phẩm theo yêu cầu',
        };
      }

      // Prepare list of products for API
      final listProduct = progress.scannedProducts.map((product) => {
        'serial_number': product.serialNumber,
        'product_id': product.productId,
        'template_id': product.templateId,
        'batch_production_id': product.batchProductionId,
        'scanned_at': product.scannedAt.toIso8601String(),
      }).toList();

      // Call API to complete export
      final apiResponse = await completeExportOrder(
        exportId: int.parse(exportId),
        orderId: progress.orderId,
        listProduct: listProduct,
      );

      if (apiResponse['success'] == true) {
        // Mark as completed and remove from active exports
        await _localStorage.markExportCompleted(exportId, progress.markCompleted());

        return {
          'success': true,
          'message': 'Hoàn thành đơn xuất kho thành công',
          'data': apiResponse['data'],
        };
      } else {
        // API failed, but keep local data
        return {
          'success': false,
          'message': 'Lỗi đồng bộ với server: ${apiResponse['message']}',
          'local_data_preserved': true,
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi hoàn thành và đồng bộ xuất kho', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi hoàn thành: ${e.toString()}',
        'local_data_preserved': true,
      };
    }
  }

  /// Sync all completed exports to server
  Future<Map<String, dynamic>> syncCompletedExports() async {
    try {
      final completedExports = await _localStorage.getCompletedExports();

      if (completedExports.isEmpty) {
        return {
          'success': true,
          'message': 'Không có đơn xuất nào cần đồng bộ',
          'synced_count': 0,
        };
      }

      int syncedCount = 0;
      int failedCount = 0;
      final List<String> failedExports = [];

      for (final entry in completedExports.entries) {
        final exportId = entry.key;
        final progress = entry.value;

        try {
          // Prepare list of products for API
          final listProduct = progress.scannedProducts.map((product) => {
            'serial_number': product.serialNumber,
            'product_id': product.productId,
            'template_id': product.templateId,
            'batch_production_id': product.batchProductionId,
            'scanned_at': product.scannedAt.toIso8601String(),
          }).toList();

          // Call API to complete export
          final apiResponse = await completeExportOrder(
            exportId: int.parse(exportId),
            orderId: progress.orderId,
            listProduct: listProduct,
          );

          if (apiResponse['success'] == true) {
            await _localStorage.removeCompletedExport(exportId);
            syncedCount++;
            logInfo('Successfully synced export $exportId');
          } else {
            failedCount++;
            failedExports.add(exportId);
            logError('Failed to sync export $exportId', apiResponse['message']);
          }
        } catch (e) {
          failedCount++;
          failedExports.add(exportId);
          logError('Error syncing export $exportId', e);
        }
      }

      return {
        'success': failedCount == 0,
        'message': failedCount == 0
            ? 'Đồng bộ tất cả đơn xuất thành công'
            : 'Đồng bộ một phần thành công. $failedCount đơn bị lỗi.',
        'synced_count': syncedCount,
        'failed_count': failedCount,
        'failed_exports': failedExports,
      };
    } catch (e, stackTrace) {
      logError('Lỗi đồng bộ đơn xuất đã hoàn thành', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi đồng bộ: ${e.toString()}',
      };
    }
  }

  /// Cancel local export
  Future<Map<String, dynamic>> cancelLocalExport(String exportId) async {
    try {
      await _localStorage.removeFromActiveExports(exportId);
      return {
        'success': true,
        'message': 'Hủy đơn xuất thành công',
      };
    } catch (e, stackTrace) {
      logError('Lỗi hủy đơn xuất local', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi hủy đơn xuất: ${e.toString()}',
      };
    }
  }

  /// Process export item (similar to import but with local storage)
  Future<Map<String, dynamic>> processExportItem({
    required String exportId,
    required String serialNumber,
    required String templateId,
    required String batchProductionId,
  }) async {
    try {
      // First save to local storage
      final localResult = await scanExportDeviceLocal(exportId, serialNumber);

      if (localResult['success'] != true) {
        return localResult; // Return validation error from local storage
      }

      // Then call process API (similar to import)
      print('DEBUG: Processing export item - ExportID: $exportId, Serial: $serialNumber');
      final result = await _apiClient.post(
        '/export-warehouse/process',
        {
          'export_id': exportId,
          'serial_number': serialNumber,
          'batch_production_id': batchProductionId,
          'template_id': templateId,
        },
      );

      print('DEBUG: Process export item response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Xử lý thiết bị xuất kho thành công',
          'data': {
            ...result['data'],
            'local_progress': localResult['data'], // Include local progress
          },
        };
      } else {
        // If API fails, we still have local data saved
        return {
          'success': true, // Consider success since local save worked
          'message': 'Đã lưu local, sẽ đồng bộ sau: ${result['message'] ?? ''}',
          'data': localResult['data'],
          'api_failed': true,
        };
      }
    } catch (e) {
      print('DEBUG: Error in processExportItem: $e');
      // If API call fails, we still have local data - but we need to get localResult first
      final localResult = await scanExportDeviceLocal(exportId, serialNumber);
      return {
        'success': localResult['success'] == true, // Only success if local save worked
        'message': localResult['success'] == true
            ? 'Đã lưu local, sẽ đồng bộ sau khi có kết nối'
            : localResult['message'] ?? 'Lỗi xử lý thiết bị',
        'data': localResult['data'] ?? {},
        'api_failed': true,
        'error': e.toString(),
      };
    }
  }

  /// Process export item using QR data
  Future<Map<String, dynamic>> processExportItemFromQr({
    required String exportId,
    required QrData qrData,
  }) async {
    return processExportItem(
      exportId: exportId,
      serialNumber: qrData.serialNumber,
      templateId: qrData.templateId,
      batchProductionId: qrData.batchProductionId,
    );
  }
}

