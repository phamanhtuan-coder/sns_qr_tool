import 'api_client.dart';

class ImportWarehouseService {
  final ApiClient _apiClient;

  ImportWarehouseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Start import order
  Future<Map<String, dynamic>> startImportOrder(String importId) async {
    try {
      print('DEBUG: Starting import order: $importId');
      final result = await _apiClient.patch(
        '/import-warehouse/start',
        {
          'import_id': importId,
        },
      );

      print('DEBUG: Start import order response: $result');

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
      print('DEBUG: Error in startImportOrder: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get unfinished invoices
  Future<Map<String, dynamic>> getUnfinishedInvoices() async {
    try {
      print('DEBUG: Getting unfinished invoices');
      final result = await _apiClient.get('/import-warehouse/invoice-not-finish');
      print('DEBUG: getUnfinishedInvoices response: $result');

      if (result['success'] == true && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể tải danh sách đơn nhập',
        };
      }
    } catch (e) {
      print('DEBUG: Error in getUnfinishedInvoices: $e');
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
      final result = await _apiClient.get('/import-warehouse/?import_id=$importId');
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

  /// Import order item
  Future<Map<String, dynamic>> importOrderItem({
    required String importId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    try {
      print('DEBUG: Importing order item - ImportID: $importId, Serial: $serialNumber');
      final result = await _apiClient.post(
        '/import-warehouse/import-order',
        {
          'import_id': importId,
          'serial_number': serialNumber,
          'batch_production_id': batchProductionId,
          'template_id': templateId,
        },
      );

      print('DEBUG: Import order item response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể nhập thiết bị',
        };
      }
    } catch (e) {
      print('DEBUG: Error in importOrderItem: $e');
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