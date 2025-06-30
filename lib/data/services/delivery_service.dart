import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';

class DeliveryService {
  static const String _baseUrl = 'https://sns-e-com-backend.up.railway.app/api';
  StreamController<Position>? _positionStreamController;
  Position? _currentPosition;

  // Mock data for demonstration
  final List<DeliveryOrder> _mockOrders = [
    DeliveryOrder(
      id: 'DH-2025-001',
      customerName: 'Nguyễn Văn A',
      customerPhone: '0901234567',
      customerAddress: '123 Đường ABC, Quận 1, TP.HCM',
      pickupAddress: 'Kho SmartNet, 456 Đường XYZ, Quận 2, TP.HCM',
      createdDate: DateTime.now().subtract(const Duration(hours: 2)),
      expectedDeliveryDate: DateTime.now().add(const Duration(hours: 4)),
      status: DeliveryStatus.assigned,
      totalAmount: 2500000,
      isUrgent: true,
      latitude: 10.7769,
      longitude: 106.7009,
      items: [
        const DeliveryItem(
          id: '1',
          name: 'Smart Sensor SS-100',
          quantity: 5,
          price: 300000,
          description: 'Cảm biến thông minh cho nhà thông minh',
        ),
        const DeliveryItem(
          id: '2',
          name: 'Control Unit CU-200',
          quantity: 2,
          price: 500000,
          description: 'Bộ điều khiển trung tâm',
        ),
        const DeliveryItem(
          id: '3',
          name: 'Gateway GW-300',
          quantity: 1,
          price: 1000000,
          description: 'Thiết bị kết nối mạng',
        ),
      ],
    ),
    DeliveryOrder(
      id: 'DH-2025-002',
      customerName: 'Trần Thị B',
      customerPhone: '0987654321',
      customerAddress: '789 Đường DEF, Quận 3, TP.HCM',
      pickupAddress: 'Kho SmartNet, 456 Đường XYZ, Quận 2, TP.HCM',
      createdDate: DateTime.now().subtract(const Duration(hours: 1)),
      expectedDeliveryDate: DateTime.now().add(const Duration(hours: 6)),
      status: DeliveryStatus.assigned,
      totalAmount: 1800000,
      isUrgent: false,
      latitude: 10.7890,
      longitude: 106.6947,
      items: [
        const DeliveryItem(
          id: '4',
          name: 'Smart Sensor SS-100',
          quantity: 3,
          price: 300000,
        ),
        const DeliveryItem(
          id: '5',
          name: 'Gateway GW-300',
          quantity: 1,
          price: 1000000,
        ),
      ],
    ),
    DeliveryOrder(
      id: 'DH-2025-003',
      customerName: 'Lê Văn C',
      customerPhone: '0912345678',
      customerAddress: '321 Đường GHI, Quận 7, TP.HCM',
      pickupAddress: 'Kho SmartNet, 456 Đường XYZ, Quận 2, TP.HCM',
      createdDate: DateTime.now().subtract(const Duration(minutes: 30)),
      expectedDeliveryDate: DateTime.now().add(const Duration(hours: 8)),
      status: DeliveryStatus.started,
      totalAmount: 3200000,
      isUrgent: false,
      latitude: 10.7429,
      longitude: 106.7180,
      startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      items: [
        const DeliveryItem(
          id: '6',
          name: 'Smart Sensor SS-100',
          quantity: 8,
          price: 300000,
        ),
        const DeliveryItem(
          id: '7',
          name: 'Control Unit CU-200',
          quantity: 2,
          price: 500000,
        ),
      ],
    ),
  ];

  Future<List<DeliveryOrder>> getAssignedOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockOrders;
  }

  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate API call success
    return {
      'success': true,
      'message': 'Đã bắt đầu giao hàng thành công',
      'data': {
        'order_id': orderId,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'started',
      },
    };
  }

  Future<Map<String, dynamic>> completeDelivery({
    required String orderId,
    required String photoPath,
    required String note,
    required bool isSuccessful,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return {
      'success': true,
      'message': isSuccessful ? 'Giao hàng thành công' : 'Đã ghi nhận giao hàng thất bại',
      'data': {
        'order_id': orderId,
        'delivered_at': DateTime.now().toIso8601String(),
        'status': isSuccessful ? 'delivered' : 'failed',
        'photo_path': photoPath,
        'note': note,
      },
    };
  }

  Future<Map<String, dynamic>> updateDeliveryLocation({
    required String orderId,
    double? latitude,
    double? longitude,
  }) async {
    // Simulate API call to update delivery location
    await Future.delayed(const Duration(milliseconds: 300));

    if (latitude == null || longitude == null) {
      return {
        'success': false,
        'message': 'Invalid location data',
      };
    }

    return {
      'success': true,
      'message': 'Location updated successfully',
      'data': {
        'order_id': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<Position> getLocationStream() {
    _positionStreamController = StreamController<Position>.broadcast();
    
    requestLocationPermission().then((hasPermission) {
      if (hasPermission) {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen(
          (position) {
            _currentPosition = position;
            _positionStreamController?.add(position);
          },
          onError: (error) {
            print('Location stream error: $error');
          },
        );
      }
    });

    return _positionStreamController!.stream;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  Duration calculateEstimatedTime(double distanceInMeters) {
    // Assuming average speed of 30 km/h in city traffic
    final hours = distanceInMeters / 1000 / 30;
    return Duration(minutes: (hours * 60).round());
  }

  String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}p';
    } else {
      return '${duration.inMinutes}p';
    }
  }

  Position? get currentPosition => _currentPosition;

  void dispose() {
    _positionStreamController?.close();
  }
}
