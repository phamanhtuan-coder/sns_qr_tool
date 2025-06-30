import 'api_client.dart';

class ImportWarehouseService {
  final ApiClient _apiClient;
  static const String _baseUrl = 'https://sns-e-com-backend.up.railway.app/api';

  ImportWarehouseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> startImportOrder(String importId) async {
    try {
      // Temporarily change base URL for this service
      final originalBaseUrl = ApiClient.baseUrl;
      ApiClient.baseUrl = _baseUrl;

      final result = await _apiClient.post(
        '/import-warehouse/start',
        {
          'import_id': importId,
        },
      );

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      return result;
    } catch (e) {
      print('DEBUG: Error in startImportOrder: $e');
      return {
        'success': false,
        'errorCode': 'START_ERROR',
        'message': 'Failed to start import order: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUnfinishedInvoices() async {
    try {
      // Temporarily change base URL for this service
      final originalBaseUrl = ApiClient.baseUrl;
      ApiClient.baseUrl = _baseUrl;

      print('DEBUG: Getting unfinished invoices from: $_baseUrl/import-warehouse/invoice-not-finish');

      // Get current token to check authentication
      final token = await _apiClient.getAccessToken();
      print('DEBUG: Using token: ${token?.substring(0, 20)}...');

      final result = await _apiClient.get('/import-warehouse/invoice-not-finish');

      print('DEBUG: getUnfinishedInvoices response: $result');

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      // Check if the response indicates success
      if (result['success'] == true || result.containsKey('data')) {
        return {
          'success': true,
          'data': result['data'] ?? result,
        };
      } else {
        // Handle error case
        print('DEBUG: API returned error: ${result['message']}');
        return {
          'success': false,
          'errorCode': result['errorCode'] ?? 'API_ERROR',
          'message': result['message'] ?? 'Failed to get unfinished invoices',
        };
      }
    } catch (e) {
      print('DEBUG: Error in getUnfinishedInvoices: $e');
      return {
        'success': false,
        'errorCode': 'GET_ERROR',
        'message': 'Failed to get unfinished invoices: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getImportOrderDetails(String importId) async {
    try {
      // Temporarily change base URL for this service
      final originalBaseUrl = ApiClient.baseUrl;
      ApiClient.baseUrl = _baseUrl;

      final result = await _apiClient.get('/import-warehouse/?import_id=$importId');

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      return result;
    } catch (e) {
      print('DEBUG: Error in getImportOrderDetails: $e');
      return {
        'success': false,
        'errorCode': 'GET_DETAILS_ERROR',
        'message': 'Failed to get import order details: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> importOrderItem({
    required String importId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    try {
      // Temporarily change base URL for this service
      final originalBaseUrl = ApiClient.baseUrl;
      ApiClient.baseUrl = _baseUrl;

      final result = await _apiClient.post(
        '/import-warehouse/import-order',
        {
          'import_id': importId,
          'serial_number': serialNumber,
          'batch_production_id': batchProductionId,
          'template_id': templateId,
        },
      );

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      return result;
    } catch (e) {
      print('DEBUG: Error in importOrderItem: $e');
      return {
        'success': false,
        'errorCode': 'IMPORT_ERROR',
        'message': 'Failed to import order item: ${e.toString()}',
      };
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
