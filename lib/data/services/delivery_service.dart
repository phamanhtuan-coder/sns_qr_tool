import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class DeliveryService {
  // Mock data for testing - replace with actual API calls
  Future<List<DeliveryOrder>> getAssignedOrders() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock delivery orders with coordinates for Vietnam locations
      return [
        DeliveryOrder(
          id: 'DH-2025-001',
          customerName: 'Nguyễn Văn A',
          customerPhone: '0909123456',
          customerAddress: '123 Nguyễn Huệ, Quận 1, TP.HCM',
          pickupAddress: 'Kho SmartNet, Quận 7, TP.HCM',
          createdDate: DateTime.now().subtract(const Duration(hours: 2)),
          expectedDeliveryDate: DateTime.now().add(const Duration(hours: 4)),
          status: DeliveryStatus.assigned,
          items: const [
            DeliveryItem(
              id: 'item1',
              name: 'Router WiFi',
              quantity: 1,
              price: 500000,
              description: 'Router WiFi 6 băng tần kép',
            ),
          ],
          totalAmount: 500000,
          notes: 'Giao hàng trong giờ hành chính',
          trackingCode: 'TK001',
          latitude: 10.7769, // Nguyen Hue Street, Ho Chi Minh City
          longitude: 106.7009,
        ),
        DeliveryOrder(
          id: 'DH-2025-002',
          customerName: 'Trần Thị B',
          customerPhone: '0909654321',
          customerAddress: '456 Lê Lợi, Quận 3, TP.HCM',
          pickupAddress: 'Kho SmartNet, Quận 7, TP.HCM',
          createdDate: DateTime.now().subtract(const Duration(hours: 1)),
          expectedDeliveryDate: DateTime.now().add(const Duration(hours: 6)),
          status: DeliveryStatus.started,
          items: const [
            DeliveryItem(
              id: 'item2',
              name: 'Switch 24 port',
              quantity: 2,
              price: 1200000,
              description: 'Switch quản lý 24 port Gigabit',
            ),
          ],
          totalAmount: 2400000,
          notes: 'Liên hệ trước khi giao',
          trackingCode: 'TK002',
          startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          latitude: 10.7684, // Le Loi Street, District 3
          longitude: 106.6934,
        ),
        DeliveryOrder(
          id: 'DH-2025-003',
          customerName: 'Lê Văn C',
          customerPhone: '0909111222',
          customerAddress: '789 Võ Văn Tần, Quận 3, TP.HCM',
          pickupAddress: 'Kho SmartNet, Quận 7, TP.HCM',
          createdDate: DateTime.now().subtract(const Duration(hours: 3)),
          expectedDeliveryDate: DateTime.now().add(const Duration(hours: 2)),
          status: DeliveryStatus.inTransit,
          items: const [
            DeliveryItem(
              id: 'item3',
              name: 'Access Point',
              quantity: 4,
              price: 800000,
              description: 'Access Point WiFi 6 outdoor',
            ),
          ],
          totalAmount: 3200000,
          notes: 'Kiểm tra hàng kỹ trước khi giao',
          trackingCode: 'TK003',
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          latitude: 10.7673, // Vo Van Tan Street
          longitude: 106.6898,
        ),
        DeliveryOrder(
          id: 'DH-2025-004',
          customerName: 'Phạm Thị D',
          customerPhone: '0909333444',
          customerAddress: '321 Hai Bà Trưng, Quận 1, TP.HCM',
          pickupAddress: 'Kho SmartNet, Quận 7, TP.HCM',
          createdDate: DateTime.now().subtract(const Duration(hours: 5)),
          expectedDeliveryDate: DateTime.now().subtract(const Duration(hours: 1)),
          status: DeliveryStatus.delivered,
          items: const [
            DeliveryItem(
              id: 'item4',
              name: 'Firewall',
              quantity: 1,
              price: 3000000,
              description: 'Firewall doanh nghiệp',
            ),
          ],
          totalAmount: 3000000,
          notes: 'Đã giao thành công',
          trackingCode: 'TK004',
          startedAt: DateTime.now().subtract(const Duration(hours: 3)),
          deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
          deliveryNote: 'Giao hàng thành công, khách hàng hài lòng',
          latitude: 10.7709, // Hai Ba Trung Street
          longitude: 106.7025,
        ),
        DeliveryOrder(
          id: 'DH-2025-005',
          customerName: 'Hoàng Văn E',
          customerPhone: '0909555666',
          customerAddress: '654 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
          pickupAddress: 'Kho SmartNet, Quận 7, TP.HCM',
          createdDate: DateTime.now().subtract(const Duration(hours: 4)),
          expectedDeliveryDate: DateTime.now().add(const Duration(hours: 3)),
          status: DeliveryStatus.assigned,
          items: const [
            DeliveryItem(
              id: 'item5',
              name: 'Camera IP',
              quantity: 8,
              price: 250000,
              description: 'Camera IP 2MP Full HD',
            ),
          ],
          totalAmount: 2000000,
          notes: 'Cần lắp đặt sau khi giao',
          trackingCode: 'TK005',
          latitude: 10.8012, // Dien Bien Phu Street, Binh Thanh
          longitude: 106.7147,
        ),
      ];
    } catch (e, stackTrace) {
      logError('Error loading delivery orders', e, stackTrace);
      throw Exception('Không thể tải danh sách đơn giao hàng');
    }
  }

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

  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Mock successful response
      return {
        'success': true,
        'message': 'Đã bắt đầu giao hàng thành công',
        'data': {
          'order_id': orderId,
          'started_at': DateTime.now().toIso8601String(),
        }
      };
    } catch (e, stackTrace) {
      logError('Error starting delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể bắt đầu giao hàng: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> completeDelivery({
    required String orderId,
    required String photoPath,
    required String note,
    required bool isSuccessful,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful response
      return {
        'success': true,
        'message': isSuccessful
            ? 'Giao hàng thành công'
            : 'Đã ghi nhận giao hàng thất bại',
        'data': {
          'order_id': orderId,
          'completed_at': DateTime.now().toIso8601String(),
          'photo_path': photoPath,
          'note': note,
          'is_successful': isSuccessful,
        }
      };
    } catch (e, stackTrace) {
      logError('Error completing delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể hoàn thành giao hàng: ${e.toString()}',
      };
    }
  }

  // Add the missing updateDeliveryLocation method
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

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock successful response
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

  // Additional utility methods for delivery management
  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    try {
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
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Đã hủy đơn hàng thành công',
        'data': {
          'order_id': orderId,
          'cancelled_at': DateTime.now().toIso8601String(),
          'reason': reason,
        }
      };
    } catch (e, stackTrace) {
      logError('Error cancelling delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không th�� hủy đơn hàng: ${e.toString()}',
      };
    }
  }
}
