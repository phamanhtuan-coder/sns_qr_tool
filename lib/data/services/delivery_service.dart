import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class DeliveryService {
  final ApiClient _apiClient = getIt<ApiClient>();

  /// Lấy danh sách đơn hàng được phân cho shipper
  /// Tương ứng với API: GET /admin/warehouse (với filter cho shipper)
  Future<List<DeliveryOrder>> getAssignedOrders() async {
    try {
      // Lấy thông tin shipper hiện tại từ token
      final username = await _apiClient.getUsername();
      if (username == null) {
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      // Gọi API để lấy đơn hàng cho warehouse employee (shipper)
      // Filter theo shipper_id và status phù hợp
      final result = await _apiClient.get('/order/admin/warehouse?filter=[{"field":"shipper_id","condition":"=","value":"$username"},{"field":"status","condition":"IN","value":"[2,3]"}]&logic=AND');

      if (result['success'] == true && result['data'] != null) {
        final ordersData = result['data']['data'] as List;
        return ordersData.map((orderJson) => _mapOrderFromApi(orderJson)).toList();
      }

      return [];
    } catch (e, stackTrace) {
      logError('Error loading delivery orders', e, stackTrace);
      throw Exception('Không thể tải danh sách đơn giao hàng: ${e.toString()}');
    }
  }

  /// Bắt đầu giao hàng cho một đơn hàng
  /// Tương ứng với API: PATCH /admin/shipping-order
  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    try {
      final result = await _apiClient.patch('/order/admin/shipping-order', {
        'order_id': orderId,
      });

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
      logError('Error starting delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể bắt đầu giao hàng: ${e.toString()}',
      };
    }
  }

  /// Hoàn thành giao hàng với ảnh chứng minh
  /// Tương ứng với API: PATCH /admin/finish-shipping-order
  Future<Map<String, dynamic>> completeDelivery({
    required String orderId,
    required String photoPath,
    required String note,
    required bool isSuccessful,
  }) async {
    try {
      // Chỉ gọi API nếu giao hàng thành công
      // Nếu thất bại, cần logic riêng (có thể cần API khác hoặc xử lý khác)
      if (isSuccessful) {
        final result = await _apiClient.patch('/order/admin/finish-shipping-order', {
          'order_id': orderId,
          'image_proof': photoPath, // Trong thực tế cần upload ảnh trước
        });

        if (result['success'] == true) {
          return {
            'success': true,
            'message': 'Giao hàng thành công',
            'data': result['data'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Không thể hoàn thành giao hàng',
          };
        }
      } else {
        // Logic cho trường hợp giao hàng thất bại
        // Có thể cần API riêng hoặc cập nhật trạng thái khác
        return {
          'success': true,
          'message': 'Đã ghi nhận giao hàng thất bại',
          'data': {
            'order_id': orderId,
            'completed_at': DateTime.now().toIso8601String(),
            'photo_path': photoPath,
            'note': note,
            'is_successful': false,
          }
        };
      }
    } catch (e, stackTrace) {
      logError('Error completing delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể hoàn thành giao hàng: ${e.toString()}',
      };
    }
  }

  /// Lấy chi tiết một đơn hàng
  /// Tương ứng với API: GET /admin/detail/:order_id
  Future<DeliveryOrder?> getOrderDetail(String orderId) async {
    try {
      final result = await _apiClient.get('/order/admin/detail/$orderId');

      if (result['success'] == true && result['data'] != null) {
        final orderData = result['data']['data'] as List;
        if (orderData.isNotEmpty) {
          return _mapOrderFromApi(orderData.first);
        }
      }

      return null;
    } catch (e, stackTrace) {
      logError('Error getting order detail', e, stackTrace);
      throw Exception('Không thể lấy chi tiết đơn hàng: ${e.toString()}');
    }
  }

  /// Cập nhật vị trí giao hàng (mock - backend chưa có API này)
  Future<Map<String, dynamic>> updateDeliveryLocation({
    required String orderId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Skip update if location is not available
      if (latitude == null || longitude == null) {
        return {
          'success': false,
          'message': 'Không có thông tin vị trí để cập nhật',
        };
      }

      // TODO: Implement actual API call when backend supports location tracking
      // For now, return mock response
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'message': 'Cập nhật vị trí thành công',
        'data': {
          'order_id': orderId,
          'latitude': latitude,
          'longitude': longitude,
          'updated_at': DateTime.now().toIso8601String(),
        }
      };
    } catch (e, stackTrace) {
      logError('Error updating delivery location', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể cập nhật vị trí giao hàng: ${e.toString()}',
      };
    }
  }

  /// Lấy thống kê đơn hàng cho shipper
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      // Gọi API để lấy tất cả đơn hàng của shipper
      final username = await _apiClient.getUsername();
      if (username == null) {
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      final result = await _apiClient.get('/order/admin/warehouse?filter=[{"field":"shipper_id","condition":"=","value":"$username"}]&logic=AND');

      if (result['success'] == true && result['data'] != null) {
        final orders = result['data']['data'] as List;

        // Tính toán thống kê
        int totalOrders = orders.length;
        int completedOrders = orders.where((order) => order['status'] == 4 || order['status'] == 5).length;
        int pendingOrders = orders.where((order) => order['status'] == 2 || order['status'] == 3).length;
        int failedOrders = orders.where((order) => order['status'] == -1).length;

        return {
          'success': true,
          'data': {
            'total_orders': totalOrders,
            'completed_orders': completedOrders,
            'pending_orders': pendingOrders,
            'failed_orders': failedOrders,
          }
        };
      }

      return {
        'success': false,
        'message': 'Không thể tải thống kê',
      };
    } catch (e, stackTrace) {
      logError('Error getting delivery stats', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể tải thống kê: ${e.toString()}',
      };
    }
  }

  // Helper methods

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e, stackTrace) {
      logError('Error getting current location', e, stackTrace);
      return null;
    }
  }

  Future<double> calculateDistance(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) async {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (e, stackTrace) {
      logError('Error calculating distance', e, stackTrace);
      return 0.0;
    }
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  Duration estimateDeliveryTime(double distanceInMeters) {
    // Assume average speed of 25 km/h in city traffic
    final averageSpeedKmH = 25.0;
    final distanceInKm = distanceInMeters / 1000;
    final timeInHours = distanceInKm / averageSpeedKmH;
    final timeInMinutes = (timeInHours * 60).round();

    return Duration(minutes: timeInMinutes);
  }

  /// Map data từ API response sang DeliveryOrder model
  DeliveryOrder _mapOrderFromApi(Map<String, dynamic> orderJson) {
    // Map status từ backend sang DeliveryStatus enum
    DeliveryStatus mapStatus(int status) {
      switch (status) {
        case 2: // PENDING_SHIPPING
          return DeliveryStatus.assigned;
        case 3: // SHIPPING
          return DeliveryStatus.started;
        case 4: // DELIVERED
          return DeliveryStatus.delivered;
        case 5: // COMPLETED
          return DeliveryStatus.delivered;
        case -1: // CANCELLED
          return DeliveryStatus.cancelled;
        default:
          return DeliveryStatus.assigned;
      }
    }

    // Map products từ API response
    List<DeliveryItem> mapProducts(List<dynamic>? products) {
      if (products == null) return [];

      return products.map((product) => DeliveryItem(
        id: product['id']?.toString() ?? '',
        name: product['name']?.toString() ?? '',
        quantity: product['quantity'] ?? 0,
        price: (product['sale_price'] ?? 0).toDouble(),
        description: product['description']?.toString(),
      )).toList();
    }

    return DeliveryOrder(
      id: orderJson['id']?.toString() ?? '',
      customerName: orderJson['customer_name']?.toString() ?? '',
      customerPhone: _extractPhoneFromOrder(orderJson),
      customerAddress: orderJson['address']?.toString() ?? '',
      pickupAddress: 'Kho SmartNet', // Default pickup address
      createdDate: _parseDateTime(orderJson['order_date']),
      expectedDeliveryDate: _parseDateTime(orderJson['order_date']).add(const Duration(days: 1)), // Mock expected date
      status: mapStatus(orderJson['status'] ?? 0),
      items: mapProducts(orderJson['products']),
      totalAmount: (orderJson['total_amount'] ?? 0).toDouble(),
      notes: orderJson['note']?.toString(),
      trackingCode: _generateTrackingCode(orderJson['id']?.toString() ?? ''),
      isUrgent: false, // Backend chưa có field này
      // Coordinates - backend chưa có, sử dụng mock data cho Vietnam
      latitude: _getMockLatitude(),
      longitude: _getMockLongitude(),
    );
  }

  String _extractPhoneFromOrder(Map<String, dynamic> orderJson) {
    // Thử các field có thể chứa số điện thoại
    return orderJson['phone']?.toString() ??
        orderJson['customer_phone']?.toString() ??
        '0909123456'; // Default phone
  }

  DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      }
    } catch (e) {
      logError('Error parsing datetime: $dateTime', e, null);
    }

    return DateTime.now();
  }

  String _generateTrackingCode(String orderId) {
    return 'TK${orderId.replaceAll('-', '').toUpperCase()}';
  }

  // Mock coordinates for Vietnam locations (sẽ được thay thế khi backend hỗ trợ)
  double _getMockLatitude() {
    final locations = [
      10.7769, // Nguyen Hue Street, Ho Chi Minh City
      10.7684, // Le Loi Street, District 3
      10.7673, // Vo Van Tan Street
      10.7709, // Hai Ba Trung Street
      10.8012, // Dien Bien Phu Street, Binh Thanh
    ];
    return locations[(DateTime.now().millisecond % locations.length)];
  }

  double _getMockLongitude() {
    final locations = [
      106.7009, // Nguyen Hue Street, Ho Chi Minh City
      106.6934, // Le Loi Street, District 3
      106.6898, // Vo Van Tan Street
      106.7025, // Hai Ba Trung Street
      106.7147, // Dien Bien Phu Street, Binh Thanh
    ];
    return locations[(DateTime.now().millisecond % locations.length)];
  }

  // Additional utility methods for delivery management

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    try {
      // Có thể mở rộng để lấy tracking history từ backend
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'data': {
          'order_id': orderId,
          'tracking_updates': [
            {
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
              'status': 'Đơn hàng được tạo',
              'location': 'Kho SmartNet',
            },
            {
              'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
              'status': 'Shipper đã nhận đơn',
              'location': 'Kho SmartNet',
            },
            {
              'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
              'status': 'Đang vận chuyển',
              'location': 'Đường Nguyễn Văn Linh',
            },
          ],
        }
      };
    } catch (e, stackTrace) {
      logError('Error getting delivery tracking', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể lấy thông tin tracking: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> cancelDelivery({
    required String orderId,
    required String reason,
  }) async {
    try {
      // Gọi API cancel order
      final result = await _apiClient.patch('/order/customer', {
        'order_id': orderId,
      });

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Đã hủy đơn hàng thành công',
          'data': {
            'order_id': orderId,
            'cancelled_at': DateTime.now().toIso8601String(),
            'reason': reason,
          }
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể hủy đơn hàng',
        };
      }
    } catch (e, stackTrace) {
      logError('Error cancelling delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể hủy đơn hàng: ${e.toString()}',
      };
    }
  }
}