// Extension for DeliveryService to add shipping methods
import 'package:smart_net_qr_scanner/data/services/delivery_service.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

extension ShippingMethods on DeliveryService {
  /// Bắt đầu giao hàng cho một đơn hàng
  /// Tương ứng với API: PATCH /order/admin/shipping-order
  Future<Map<String, dynamic>> startShippingOrder(String orderId) async {
    try {
      final ApiClient apiClient = getIt<ApiClient>();

      print('DEBUG: Starting shipping order: $orderId');
      final result = await apiClient.patch('/order/admin/shipping-order', {
        'order_id': orderId,
      });

      print('DEBUG: Start shipping order response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Đã bắt đầu giao hàng thành công',
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể bắt đầu giao hàng',
        };
      }
    } catch (e, stackTrace) {
      logError('Error starting shipping order', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Xác nhận hoàn thành giao hàng với ảnh bằng chứng
  /// Tương ứng với API: PATCH /order/admin/confirm-shipping-order
  Future<Map<String, dynamic>> confirmShippingOrder({
    required String orderId,
    required String imageProofBase64,
  }) async {
    try {
      final ApiClient apiClient = getIt<ApiClient>();

      print('DEBUG: Confirming shipping order: $orderId');
      final result = await apiClient.patch('/order/admin/confirm-shipping-order', {
        'order_id': orderId,
        'image_proof': imageProofBase64,
      });

      print('DEBUG: Confirm shipping order response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Đã xác nhận hoàn thành giao hàng thành công',
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể xác nhận hoàn thành giao hàng',
        };
      }
    } catch (e, stackTrace) {
      logError('Error confirming shipping order', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }
}
