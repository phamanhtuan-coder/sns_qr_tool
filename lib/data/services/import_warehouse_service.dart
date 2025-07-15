import 'api_client.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';

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

  void dispose() {
    _apiClient.dispose();
  }
}