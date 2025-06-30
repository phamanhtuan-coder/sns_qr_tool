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

      print('DEBUG: Starting import order: $importId');
      final result = await _apiClient.post(
        '/import-warehouse/start',
        {
          'import_id': importId,
        },
      );

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      print('DEBUG: Start import order response: $result');

      // Check for success response
      if (result['status_code'] == 200 && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        // Handle error response
        final errors = result['errors'] as List<dynamic>?;
        final errorMessage = errors?.isNotEmpty == true
            ? errors!.first['message'] ?? 'Unknown error'
            : result['message'] ?? 'Failed to start import order';

        return {
          'success': false,
          'errorCode': errors?.isNotEmpty == true ? errors!.first['code']?.toString() : 'START_ERROR',
          'message': errorMessage,
        };
      }
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

      final result = await _apiClient.get('/import-warehouse/invoice-not-finish');

      print('DEBUG: getUnfinishedInvoices response: $result');

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      // Check for success response
      if (result['status_code'] == 200 && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        // Handle error case
        final errors = result['errors'] as List<dynamic>?;
        final errorMessage = errors?.isNotEmpty == true
            ? errors!.first['message'] ?? 'Unknown error'
            : result['message'] ?? 'Failed to get unfinished invoices';

        return {
          'success': false,
          'errorCode': errors?.isNotEmpty == true ? errors!.first['code']?.toString() : 'API_ERROR',
          'message': errorMessage,
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

      print('DEBUG: Getting import order details for: $importId');
      final result = await _apiClient.get('/import-warehouse/?import_id=$importId');

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      print('DEBUG: Import order details response: $result');

      // Check for success response
      if (result['status_code'] == 200 && result['data'] != null) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        // Handle error case
        final errors = result['errors'] as List<dynamic>?;
        final errorMessage = errors?.isNotEmpty == true
            ? errors!.first['message'] ?? 'Unknown error'
            : result['message'] ?? 'Failed to get import order details';

        return {
          'success': false,
          'errorCode': errors?.isNotEmpty == true ? errors!.first['code']?.toString() : 'GET_DETAILS_ERROR',
          'message': errorMessage,
        };
      }
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

      // Restore original base URL
      ApiClient.baseUrl = originalBaseUrl;

      print('DEBUG: Import order item response: $result');

      // Check for success response
      if (result['status_code'] == 200) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        // Handle error response
        final errors = result['errors'] as List<dynamic>?;
        final errorMessage = errors?.isNotEmpty == true
            ? errors!.first['message'] ?? 'Unknown error'
            : result['message'] ?? 'Failed to import order item';

        return {
          'success': false,
          'errorCode': errors?.isNotEmpty == true ? errors!.first['code']?.toString() : 'IMPORT_ERROR',
          'message': errorMessage,
        };
      }
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
