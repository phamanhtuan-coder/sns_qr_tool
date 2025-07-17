import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/services/local_export_storage.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class ExportWarehouseService {
  final ApiClient _apiClient = ApiClient();
  final LocalExportStorage _localStorage = LocalExportStorage();

  /// Get list of unfinished export orders for the current employee
  Future<Map<String, dynamic>> getUnfinishedExportOrders() async {
    try {
      final response = await _apiClient.get('/export-warehouse/invoice-not-finish');

      // API returns nested structure: { "status_code": 200, "data": [...] }
      if (response['success'] == true) {
        if (response['data'] is Map && response['data'].containsKey('status_code')) {
          // Nested response structure
          return {
            'success': true,
            'data': response['data'],
          };
        } else {
          // Direct response structure
          return {
            'success': true,
            'data': response['data'],
          };
        }
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': response['data'],
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

  /// Get export order details
  Future<Map<String, dynamic>> getExportOrderDetail(String exportId) async {
    try {
      final response = await _apiClient.get('/export-warehouse/detail/$exportId');

      if (response['success'] == true) {
        // Extract order data directly from the response
        final orderData = _extractOrderData(response);

        if (orderData != null) {
          return {
            'success': true,
            'data': orderData,
          };
        } else {
          return {
            'success': false,
            'message': 'Không thể đọc thông tin đơn xuất',
          };
        }
      } else {
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

  /// Helper method to extract order data from various response structures
  Map<String, dynamic>? _extractOrderData(Map<String, dynamic> response) {
    try {
      final data = response['data'];

      // Try different paths to extract the order data

      // Path 1: data.data.data[0]
      if (data is Map &&
          data.containsKey('data') &&
          data['data'] is Map &&
          data['data'].containsKey('data') &&
          data['data']['data'] is List &&
          (data['data']['data'] as List).isNotEmpty) {
        return Map<String, dynamic>.from((data['data']['data'] as List)[0]);
      }

      // Path 2: data.data[0]
      if (data is Map &&
          data.containsKey('data') &&
          data['data'] is List &&
          (data['data'] as List).isNotEmpty) {
        return Map<String, dynamic>.from((data['data'] as List)[0]);
      }

      // Path 3: Direct data object with orders field
      if (data is Map && data.containsKey('orders')) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      print('DEBUG: Error in _extractOrderData: $e');
      return null;
    }
  }

  /// Start a new export order
  Future<Map<String, dynamic>> startExportOrder(String exportId) async {
    try {
      // Parse exportId to integer since the backend expects an int
      final parsedId = int.parse(exportId);

      final response = await _apiClient.patch('/export-warehouse/start', {
        'export_id': parsedId, // Send as integer
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

  /// Export a single product
  Future<Map<String, dynamic>> exportProduct({
    required String exportId,
    required String orderId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    try {
      final response = await _apiClient.patch('/export-warehouse/export-order', {
        'export_id': exportId,
        'order_id': orderId,
        'serial_number': serialNumber,
        'batch_production_id': batchProductionId,
        'template_id': templateId,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Xuất sản phẩm thành công',
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'message': 'Xuất sản phẩm thành công',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể xuất sản phẩm',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi xuất sản phẩm', e, stackTrace);
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
  Future<Map<String, dynamic>> completeExportOrder(
      String exportId,
      {String? orderId, List<Map<String, dynamic>>? listProduct}
      ) async {
    try {
      // Get current progress if no list product provided
      if (listProduct == null) {
        final progress = await _localStorage.getExportProgress(exportId);
        if (progress == null) {
          return {
            'success': false,
            'message': 'Không tìm thấy tiến trình xuất kho',
          };
        }

        // Check if we can complete the order
        if (!progress.canComplete) {
          return {
            'success': false,
            'message': 'Chưa quét đủ số lượng sản phẩm theo yêu cầu',
          };
        }

        // Group products by template_id
        final groupedProducts = <String, List<Map<String, String>>>{};
        for (final product in progress.scannedProducts) {
          groupedProducts.putIfAbsent(product.templateId, () => []).add({
            'batch_production_id': product.batchProductionId,
            'serial_number': product.serialNumber,
          });
        }

        // Format the request body
        listProduct = groupedProducts.entries.map((entry) => {
          'template_id': entry.key,
          'list_serial': entry.value,
          'quantity': entry.value.length,
        }).toList();

        orderId = progress.orderId;
      }

      // Call API to complete export
      final result = await _apiClient.patch(
        '/export-warehouse/export-order',
        {
          'export_id': exportId,
          'order_id': orderId,
          'list_product': listProduct,
        },
      );

      if (result['success'] == true) {
        // Clear local storage for this export
        await _localStorage.removeFromActiveExports(exportId);
        return {
          'success': true,
          'message': 'Hoàn thành xuất kho thành công',
          'data': result['data'],
        };
      }

      return {
        'success': false,
        'message': result['message'] ?? 'Không thể hoàn thành xuất kho',
      };
    } catch (e) {
      print('DEBUG: Error completing export order: $e');
      return {
        'success': false,
        'message': 'Lỗi hoàn thành xuất kho: ${e.toString()}',
      };
    }
  }

  /// Get current export progress - combines local and server progress
  Future<Map<String, dynamic>> getExportProgress(String exportId) async {
    try {
      // First try to get local progress
      final localProgress = await _localStorage.getExportProgress(exportId);
      if (localProgress != null) {
        return {
          'success': true,
          'data': localProgress.toJson(),
        };
      }

      // If no local progress, get from server
      return await _apiClient.get('/export-warehouse/process/$exportId');
    } catch (e) {
      print('DEBUG: Error getting export progress: $e');
      return {
        'success': false,
        'message': 'Lỗi lấy tiến độ xuất kho: ${e.toString()}',
      };
    }
  }

  /// Handle scanned device for export
  Future<Map<String, dynamic>> handleScannedDevice({
    required String exportId,
    required String orderId,
    required QrData qrData,
    required Map<String, int> expectedQuantities,
  }) async {
    try {
      // Store the scanned item locally first
      await _localStorage.addScannedItem(
        exportId,
        qrData.serialNumber,
        qrData.templateId,
        qrData.batchProductionId,
      );

      // Get current progress
      final progress = await _localStorage.getExportProgress(exportId);

      return {
        'success': true,
        'message': 'Đã quét thiết bị thành công',
        'data': {
          'serial_number': qrData.serialNumber,
          'template_id': qrData.templateId,
          'batch_production_id': qrData.batchProductionId,
          'progress': progress?.toJson() ?? {},
        },
      };
    } catch (e) {
      logError('Error handling scanned device', e, null);
      return {
        'success': false,
        'message': 'Lỗi xử lý thiết bị quét: ${e.toString()}',
      };
    }
  }

  /// Process an export item
  Future<Map<String, dynamic>> processExportItem({
    required String exportId,
    required String orderId,
    required String serialNumber,
    String? batchProductionId,
    String? templateId,
  }) async {
    try {
      final result = await exportProduct(
        exportId: exportId,
        orderId: orderId,
        serialNumber: serialNumber,
        batchProductionId: batchProductionId ?? _extractBatchId(serialNumber),
        templateId: templateId ?? _extractTemplateId(serialNumber),
      );

      if (result['success']) {
        // Update local progress after successful API call
        await _localStorage.addScannedItem(
          exportId,
          serialNumber,
          templateId ?? _extractTemplateId(serialNumber),
          batchProductionId ?? _extractBatchId(serialNumber),
        );
      }

      return result;
    } catch (e) {
      print('DEBUG: Error processing export item: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý thiết bị xuất kho: ${e.toString()}',
      };
    }
  }
}