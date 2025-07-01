import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class ExportWarehouseService {
  final ApiClient _apiClient = ApiClient();

  /// Get list of unfinished export orders
  Future<Map<String, dynamic>> getUnfinishedExportOrders() async {
    try {
      final response = await _apiClient.get('/warehouse/export-orders/unfinished');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
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
      final response = await _apiClient.post('/warehouse/export-orders/start', {
        'export_id': exportId,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Bắt đầu đơn xuất thành công',
          'data': response['data'],
        };
      } else {
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

  /// Scan device for export
  Future<Map<String, dynamic>> scanExportDevice(String exportId, String serialNumber) async {
    try {
      final response = await _apiClient.post('/warehouse/export-orders/scan', {
        'export_id': exportId,
        'serial_number': serialNumber,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Quét thiết bị thành công',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Không thể quét thiết bị',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị xuất kho', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
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

      final response = await _apiClient.post('/warehouse/export-orders/complete', requestBody);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Hoàn thành đơn xuất thành công',
          'data': response['data'],
        };
      } else {
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
      final response = await _apiClient.get('/warehouse/export-orders/$exportId');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
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
}
