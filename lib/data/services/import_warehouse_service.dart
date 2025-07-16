import 'api_client.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';

class ImportWarehouseService {
  final ApiClient _apiClient;

  ImportWarehouseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get list of import orders with status 0 (not started) and 1 (in progress)
  Future<Map<String, dynamic>> getImportWarehouseNotFinish() async {
    try {
      final result = await _apiClient.get('/import-warehouse/invoice-not-finish');

      if (result['success'] == true) {
        final responseData = result['data'];

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          if (responseData['status_code'] == 200) {
            final orders = responseData['data'] ?? [];
            // Filter to include only status 0 and 1 orders
            final filteredOrders = (orders as List).where((order) {
              final status = order['status'] ?? 0;
              return status == 0 || status == 1;
            }).toList();

            return {
              'success': true,
              'data': filteredOrders,
            };
          }
        } else if (responseData is List) {
          // Filter direct list response
          final filteredOrders = responseData.where((order) {
            final status = order['status'] ?? 0;
            return status == 0 || status == 1;
          }).toList();

          return {
            'success': true,
            'data': filteredOrders,
          };
        }

        return {
          'success': true,
          'data': responseData ?? [],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể tải danh sách đơn nhập',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get import process details with device information
  Future<Map<String, dynamic>> getProcessImportWarehouse(String id) async {
    try {
      final result = await _apiClient.get('/import-warehouse/process/$id');

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể tải chi tiết đơn nhập',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Start import order - only for status 0 orders
  Future<Map<String, dynamic>> startImportOrder(String importId) async {
    try {
      final result = await _apiClient.patch(
        '/import-warehouse/start',
        {
          'import_id': importId,
        },
      );

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể bắt đầu đơn nhập',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get import order details
  Future<Map<String, dynamic>> getImportOrderDetails(String importId) async {
    try {
      print('DEBUG: Getting import order details for: $importId');
      final result = await _apiClient.get('/import-warehouse/detail/$importId');
      print('DEBUG: Import order details response: $result');

      if (result['success'] == true && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể tải thông tin đơn nhập',
        };
      }
    } catch (e) {
      print('DEBUG: Error in getImportOrderDetails: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get import order process details (devices to scan)
  Future<Map<String, dynamic>> getImportOrderProcess(String importId) async {
    try {
      print('DEBUG: Getting import order process for: $importId');
      final result = await _apiClient.get('/import-warehouse/process/$importId');
      print('DEBUG: Import order process response: $result');

      if (result['success'] == true && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể tải quy trình nhập kho',
        };
      }
    } catch (e) {
      print('DEBUG: Error in getImportOrderProcess: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Import order item using QR data
  Future<Map<String, dynamic>> importOrderItemFromQr({
    required String importId,
    required QrData qrData,
  }) async {
    try {
      print('DEBUG: Importing order item from QR - ImportID: $importId, QR Data: $qrData');
      final result = await _apiClient.post(
        '/import-warehouse/import-order',
        {
          'import_id': importId,
          'serial_number': qrData.serialNumber,
          'batch_production_id': qrData.batchProductionId,
          'template_id': qrData.templateId,
        },
      );

      print('DEBUG: Import order item response: $result');

      if (result['success'] == true) {
        // After successful import, get updated process
        final processResult = await getImportOrderProcess(importId);
        return {
          'success': true,
          'data': result['data'],
          'process': processResult['data'], // Include current process data
        };
      }

      return {
        'success': false,
        'message': result['message'] ?? 'Không thể nhập thiết bị',
      };
    } catch (e) {
      print('DEBUG: Error in importOrderItemFromQr: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Import order item (legacy method - for backward compatibility)
  Future<Map<String, dynamic>> importOrderItem({
    required String importId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    final qrData = QrData(
      serialNumber: serialNumber,
      batchProductionId: batchProductionId,
      templateId: templateId,
    );
    return importOrderItemFromQr(importId: importId, qrData: qrData);
  }

  /// Process import item (similar to export process)
  Future<Map<String, dynamic>> processImportItem({
    required String importId,
    required String serialNumber,
    String? batchProductionId,
    String? templateId,
  }) async {
    try {
      print('DEBUG: Processing import item - ImportID: $importId, Serial: $serialNumber');
      final result = await _apiClient.post(
        '/import-warehouse/process',
        {
          'import_id': importId,
          'serial_number': serialNumber,
          'batch_production_id': batchProductionId,
          'template_id': templateId,
        },
      );

      print('DEBUG: Process import item response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Xử lý thiết bị nhập kho thành công',
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể xử lý thiết bị',
        };
      }
    } catch (e) {
      print('DEBUG: Error in processImportItem: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get import progress for tracking
  Future<Map<String, dynamic>> getImportProgress(String importId) async {
    try {
      final response = await _apiClient.get('/import-warehouse/process/$importId');

      // Handle response format from logs
      if (response['data'] != null) {
        final responseData = response['data'];

        // Handle nested response structure
        if (responseData['status_code'] == 200) {
          if (responseData['data'] is List) {
            return {
              'success': true,
              'data': responseData['data'],
            };
          }
        }

        // Handle direct data
        if (responseData is List) {
          return {
            'success': true,
            'data': responseData,
          };
        }
      }

      // Handle legacy response format
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Không thể tải tiến độ nhập kho',
      };
    } catch (e) {
      print('DEBUG: Error in getImportProgress: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Check if order can be started or get current progress
  Future<Map<String, dynamic>> getOrderStatusAndProgress(String importId) async {
    try {
      // First get order details to check status
      final orderResult = await getImportOrderDetails(importId);

      if (!orderResult['success']) {
        return orderResult;
      }

      final orderData = orderResult['data'];
      final orderStatus = orderData?['status'] ?? 0;

      // Get current progress regardless of status
      final progressResult = await getImportProgress(importId);

      return {
        'success': true,
        'data': {
          'order_status': orderStatus,
          'order_details': orderData,
          'progress': progressResult['success'] ? progressResult['data'] : [],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}