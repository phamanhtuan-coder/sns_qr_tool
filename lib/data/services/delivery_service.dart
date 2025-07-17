import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class DeliveryService {
  final ApiClient _apiClient = getIt<ApiClient>();

  /// Lấy danh sách đơn hàng được phân cho shipper
  /// Tương ứng với API: GET /order/shipper/:shipper_id
  Future<List<DeliveryOrder>> getAssignedOrders() async {
    try {
      print('DEBUG: DeliveryService.getAssignedOrders() - Starting');

      // Lấy thông tin shipper hiện tại từ token
      final username = await _apiClient.getUsername();
      print('DEBUG: DeliveryService.getAssignedOrders() - Username: $username');

      if (username == null) {
        print('DEBUG: DeliveryService.getAssignedOrders() - No username found');
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      // Gọi API endpoint mới cho shipper cụ thể
      print('DEBUG: DeliveryService.getAssignedOrders() - Calling API: /order/shipper/$username');
      final result = await _apiClient.get('/order/shipper/$username');
      print('DEBUG: DeliveryService.getAssignedOrders() - API Response: $result');

      // Xử lý response format mới từ API
      // Structure: {success: true, data: {status_code: 200, data: {data: [...], total_page: 1, shipperStats: {...}}}}
      if (result['success'] == true && result['data'] != null) {
        final outerData = result['data'];
        print('DEBUG: DeliveryService.getAssignedOrders() - Outer data: $outerData');

        if (outerData is Map<String, dynamic> &&
            outerData['status_code'] == 200 &&
            outerData['data'] != null) {
          final innerData = outerData['data'];
          print('DEBUG: DeliveryService.getAssignedOrders() - Inner data: $innerData');

          if (innerData is Map<String, dynamic> && innerData['data'] != null) {
            final ordersData = innerData['data'];
            print('DEBUG: DeliveryService.getAssignedOrders() - Orders data type: ${ordersData.runtimeType}');

            // Xử lý trường hợp data là null hoặc empty list
            if (ordersData == null) {
              print('DEBUG: DeliveryService.getAssignedOrders() - Orders data is null, returning empty list');
              return [];
            }

            if (ordersData is List) {
              print('DEBUG: DeliveryService.getAssignedOrders() - Found ${ordersData.length} orders');

              if (ordersData.isEmpty) {
                print('DEBUG: DeliveryService.getAssignedOrders() - Empty orders list, returning empty');
                return [];
              }

              final mappedOrders = ordersData.map((orderJson) => _mapOrderFromApi(orderJson)).toList();
              print('DEBUG: DeliveryService.getAssignedOrders() - Successfully mapped ${mappedOrders.length} orders');
              return mappedOrders;
            } else {
              print('DEBUG: DeliveryService.getAssignedOrders() - Orders data is not a list: ${ordersData.runtimeType}');
              return [];
            }
          } else {
            print('DEBUG: DeliveryService.getAssignedOrders() - Inner data is not a Map or data field is null');
            return [];
          }
        } else {
          print('DEBUG: DeliveryService.getAssignedOrders() - Outer data is not a Map or status_code != 200');
          return [];
        }
      }

      print('DEBUG: DeliveryService.getAssignedOrders() - No valid data found or success != true, returning empty list');
      return [];
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.getAssignedOrders() - Error: $e');
      print('DEBUG: DeliveryService.getAssignedOrders() - Stack trace: $stackTrace');
      logError('Error loading delivery orders', e, stackTrace);
      throw Exception('Không thể tải danh sách đơn giao hàng: ${e.toString()}');
    }
  }

  /// Bắt đầu giao hàng cho một đơn hàng
  /// Tương ứng với API: PATCH /order/admin/shipping-order
  Future<Map<String, dynamic>> startDelivery(String orderId) async {
    try {
      print('DEBUG: DeliveryService.startDelivery() - Starting with orderId: $orderId');

      final requestBody = {'order_id': orderId};
      print('DEBUG: DeliveryService.startDelivery() - Request body: $requestBody');

      final result = await _apiClient.patch('/order/admin/shipping-order', requestBody);
      print('DEBUG: DeliveryService.startDelivery() - API Response: $result');

      if (result['success'] == true) {
        print('DEBUG: DeliveryService.startDelivery() - Success');
        return {
          'success': true,
          'message': 'Đã bắt đầu giao hàng thành công',
          'data': result['data'],
        };
      } else {
        print('DEBUG: DeliveryService.startDelivery() - Failed: ${result['message']}');
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể bắt đầu giao hàng',
        };
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.startDelivery() - Error: $e');
      print('DEBUG: DeliveryService.startDelivery() - Stack trace: $stackTrace');
      logError('Error starting delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể bắt đầu giao hàng: ${e.toString()}',
      };
    }
  }

  /// Hoàn thành giao hàng với ảnh chứng minh
  /// Tương ứng với API: PATCH /order/admin/finish-shipping-order
  Future<Map<String, dynamic>> completeDelivery({
    required String orderId,
    required String photoPath,
    required String note,
    required bool isSuccessful,
  }) async {
    try {
      print('DEBUG: DeliveryService.completeDelivery() - Starting');
      print('DEBUG: DeliveryService.completeDelivery() - OrderId: $orderId');
      print('DEBUG: DeliveryService.completeDelivery() - PhotoPath: $photoPath');
      print('DEBUG: DeliveryService.completeDelivery() - Note: $note');
      print('DEBUG: DeliveryService.completeDelivery() - IsSuccessful: $isSuccessful');

      // Chỉ gọi API nếu giao hàng thành công
      // Nếu thất bại, cần logic riêng (có thể cần API khác hoặc xử lý khác)
      if (isSuccessful) {
        print('DEBUG: DeliveryService.completeDelivery() - Processing successful delivery');

        final requestBody = {
          'order_id': orderId,
          'image_proof': photoPath, // Trong thực tế cần upload ảnh trước
        };
        print('DEBUG: DeliveryService.completeDelivery() - Request body: $requestBody');

        final result = await _apiClient.patch('/order/admin/finish-shipping-order', requestBody);
        print('DEBUG: DeliveryService.completeDelivery() - API Response: $result');

        if (result['success'] == true) {
          print('DEBUG: DeliveryService.completeDelivery() - API call successful');
          return {
            'success': true,
            'message': 'Giao hàng thành công',
            'data': result['data'],
          };
        } else {
          print('DEBUG: DeliveryService.completeDelivery() - API call failed: ${result['message']}');
          return {
            'success': false,
            'message': result['message'] ?? 'Không thể hoàn thành giao hàng',
          };
        }
      } else {
        print('DEBUG: DeliveryService.completeDelivery() - Processing failed delivery (mock response)');
        // Logic cho trường hợp giao hàng thất bại
        // Có thể cần API riêng hoặc cập nhật trạng thái khác
        final mockResponse = {
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
        print('DEBUG: DeliveryService.completeDelivery() - Mock response: $mockResponse');
        return mockResponse;
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.completeDelivery() - Error: $e');
      print('DEBUG: DeliveryService.completeDelivery() - Stack trace: $stackTrace');
      logError('Error completing delivery', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể hoàn thành giao hàng: ${e.toString()}',
      };
    }
  }

  /// Lấy chi tiết một đơn hàng
  /// Tương ứng với API: GET /order/admin/detail/:order_id
  Future<DeliveryOrder?> getOrderDetail(String orderId) async {
    try {
      print('DEBUG: DeliveryService.getOrderDetail() - Starting with orderId: $orderId');

      final result = await _apiClient.get('/order/admin/detail/$orderId');
      print('DEBUG: DeliveryService.getOrderDetail() - API Response: $result');

      if (result['success'] == true && result['data'] != null) {
        final orderData = result['data']['data'] as List;
        print('DEBUG: DeliveryService.getOrderDetail() - Found ${orderData.length} order(s)');

        if (orderData.isNotEmpty) {
          final mappedOrder = _mapOrderFromApi(orderData.first);
          print('DEBUG: DeliveryService.getOrderDetail() - Successfully mapped order: ${mappedOrder.id}');
          return mappedOrder;
        } else {
          print('DEBUG: DeliveryService.getOrderDetail() - No order data found');
        }
      } else {
        print('DEBUG: DeliveryService.getOrderDetail() - API call failed or no data');
      }

      return null;
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.getOrderDetail() - Error: $e');
      print('DEBUG: DeliveryService.getOrderDetail() - Stack trace: $stackTrace');
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
      print('DEBUG: DeliveryService.getDeliveryStats() - Starting');

      // Gọi API để lấy tất cả đơn hàng của shipper
      final username = await _apiClient.getUsername();
      print('DEBUG: DeliveryService.getDeliveryStats() - Username: $username');

      if (username == null) {
        print('DEBUG: DeliveryService.getDeliveryStats() - No username found');
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      // Sử dụng endpoint mới
      print('DEBUG: DeliveryService.getDeliveryStats() - Calling API: /order/shipper/$username');
      final result = await _apiClient.get('/order/shipper/$username');
      print('DEBUG: DeliveryService.getDeliveryStats() - API Response: $result');

      // Xử lý response format mới từ API
      if ((result['status_code'] == 200 || result['success'] == true) && result['data'] != null) {
        final dataSection = result['data'];

        // Kiểm tra nếu có shipperStats trong response
        if (dataSection is Map<String, dynamic> && dataSection['shipperStats'] != null) {
          final shipperStats = dataSection['shipperStats'] as Map<String, dynamic>;
          print('DEBUG: DeliveryService.getDeliveryStats() - Found shipperStats: $shipperStats');

          // Sử dụng stats từ API nếu có
          return {
            'success': true,
            'data': {
              'total_orders': (shipperStats['pending_shipping'] ?? 0) +
                            (shipperStats['shipping'] ?? 0) +
                            (shipperStats['delivered'] ?? 0) +
                            (shipperStats['completed'] ?? 0),
              'completed_orders': (shipperStats['delivered'] ?? 0) + (shipperStats['completed'] ?? 0),
              'pending_orders': (shipperStats['pending_shipping'] ?? 0) + (shipperStats['shipping'] ?? 0),
              'failed_orders': 0, // API chưa có field này
            }
          };
        }

        // Fallback: tính toán từ danh sách orders nếu không có shipperStats
        if (dataSection['data'] != null && dataSection['data'] is List) {
          final orders = dataSection['data'] as List;
          print('DEBUG: DeliveryService.getDeliveryStats() - Found ${orders.length} orders, calculating stats');

          // Tính toán thống kê
          int totalOrders = orders.length;
          int completedOrders = orders.where((order) => order['status'] == 4 || order['status'] == 5).length;
          int pendingOrders = orders.where((order) => order['status'] == 2 || order['status'] == 3).length;
          int failedOrders = orders.where((order) => order['status'] == -1).length;

          print('DEBUG: DeliveryService.getDeliveryStats() - Statistics calculated:');
          print('  Total: $totalOrders');
          print('  Completed: $completedOrders');
          print('  Pending: $pendingOrders');
          print('  Failed: $failedOrders');

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
      }

      print('DEBUG: DeliveryService.getDeliveryStats() - No data found, returning default stats');
      return {
        'success': true,
        'data': {
          'total_orders': 0,
          'completed_orders': 0,
          'pending_orders': 0,
          'failed_orders': 0,
        }
      };
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.getDeliveryStats() - Error: $e');
      print('DEBUG: DeliveryService.getDeliveryStats() - Stack trace: $stackTrace');
      logError('Error getting delivery stats', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể tải thống kê: ${e.toString()}',
      };
    }
  }

  /// Bắt đầu đơn shipping (tương ứng với startShippingOrder API)
  Future<Map<String, dynamic>> startShippingOrder(String orderId) async {
    try {
      print('DEBUG: DeliveryService.startShippingOrder() - Starting with orderId: $orderId');

      final requestBody = {'order_id': orderId};
      print('DEBUG: DeliveryService.startShippingOrder() - Request body: $requestBody');

      final result = await _apiClient.patch('/order/admin/shipping-order', requestBody);
      print('DEBUG: DeliveryService.startShippingOrder() - API Response: $result');

      if (result['success'] == true) {
        print('DEBUG: DeliveryService.startShippingOrder() - Success');
        return {
          'success': true,
          'message': 'Đã bắt đầu giao hàng thành công',
          'data': result['data'],
        };
      } else {
        print('DEBUG: DeliveryService.startShippingOrder() - Failed: ${result['message']}');
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể bắt đầu giao hàng',
        };
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.startShippingOrder() - Error: $e');
      print('DEBUG: DeliveryService.startShippingOrder() - Stack trace: $stackTrace');
      logError('Error starting shipping order', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể bắt đầu giao hàng: ${e.toString()}',
      };
    }
  }

  /// Xác nhận hoàn thành đơn shipping với ảnh chứng minh (base64)
  Future<Map<String, dynamic>> confirmShippingOrder({
    required String orderId,
    required String imageProofBase64,
  }) async {
    try {
      print('DEBUG: DeliveryService.confirmShippingOrder() - Starting');
      print('DEBUG: DeliveryService.confirmShippingOrder() - OrderId: $orderId');
      print('DEBUG: DeliveryService.confirmShippingOrder() - ImageProof length: ${imageProofBase64.length} characters');

      final requestBody = {
        'order_id': orderId,
        'image_proof': imageProofBase64,
      };
      print('DEBUG: DeliveryService.confirmShippingOrder() - Request body keys: ${requestBody.keys.toList()}');

      final result = await _apiClient.patch('/order/admin/finish-shipping-order', requestBody);
      print('DEBUG: DeliveryService.confirmShippingOrder() - API Response: $result');

      if (result['success'] == true) {
        print('DEBUG: DeliveryService.confirmShippingOrder() - Success');
        return {
          'success': true,
          'message': 'Hoàn thành giao hàng thành công',
          'data': result['data'],
        };
      } else {
        print('DEBUG: DeliveryService.confirmShippingOrder() - Failed: ${result['message']}');
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể hoàn thành giao hàng',
        };
      }
    } catch (e, stackTrace) {
      print('DEBUG: DeliveryService.confirmShippingOrder() - Error: $e');
      print('DEBUG: DeliveryService.confirmShippingOrder() - Stack trace: $stackTrace');
      logError('Error confirming shipping order', e, stackTrace);
      return {
        'success': false,
        'message': 'Không thể hoàn thành giao hàng: ${e.toString()}',
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
    print('DEBUG: DeliveryService._mapOrderFromApi() - Starting mapping for order: ${orderJson['id']}');
    print('DEBUG: DeliveryService._mapOrderFromApi() - Raw order data: $orderJson');

    // Map status từ backend sang DeliveryStatus enum
    DeliveryStatus mapStatus(int status) {
      print('DEBUG: DeliveryService._mapOrderFromApi() - Mapping status: $status');
      switch (status) {
        case -1: // CANCELLED
          return DeliveryStatus.cancelled;
        case 0: // PENDING
          return DeliveryStatus.pending;
        case 1: // PREPARING
          return DeliveryStatus.preparing;
        case 2: // PENDING_SHIPPING - Chờ giao hàng
          return DeliveryStatus.assigned;
        case 3: // SHIPPING - Đang giao hàng
          return DeliveryStatus.started;
        case 4: // DELIVERED - Đã giao hàng
          return DeliveryStatus.delivered;
        case 5: // COMPLETED - Hoàn thành
          return DeliveryStatus.completed;
        default:
          return DeliveryStatus.assigned;
      }
    }

    // Map products từ API response - matches exact API structure
    List<DeliveryItem> mapProducts(List<dynamic>? products) {
      print('DEBUG: DeliveryService._mapOrderFromApi() - Mapping products: ${products?.length ?? 0} items');
      if (products == null) return [];

      final mappedProducts = products.map((product) => DeliveryItem(
        id: product['id']?.toString() ?? '',
        name: product['name']?.toString() ?? '',
        quantity: product['quantity'] ?? 0,
        price: 0.0, // API doesn't provide price per item
        description: 'Tồn kho: ${product['total_stock'] ?? 'N/A'}',
      )).toList();

      print('DEBUG: DeliveryService._mapOrderFromApi() - Successfully mapped ${mappedProducts.length} products');
      return mappedProducts;
    }

    // Parse date from API if provided (API doesn't seem to have order_date in this response)
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null || dateStr.toString().isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    final mappedOrder = DeliveryOrder(
      // Exact API field mapping
      id: orderJson['id']?.toString() ?? '',
      customerName: orderJson['customer_name']?.toString() ?? '',
      customerPhone: orderJson['phone']?.toString() ?? '0000000000',
      customerAddress: orderJson['address']?.toString() ?? '',

      // Default/calculated fields
      pickupAddress: 'Kho SmartNet',
      createdDate: parseDate(orderJson['created_date']), // Use current time if not provided
      expectedDeliveryDate: DateTime.now().add(const Duration(days: 1)),

      // Direct API mapping
      status: mapStatus(orderJson['status'] ?? 2),
      items: mapProducts(orderJson['products']),
      totalAmount: (orderJson['amount'] ?? 0).toDouble(),
      notes: orderJson['note']?.toString(),

      // Generated fields
      trackingCode: _generateTrackingCode(orderJson['id']?.toString() ?? ''),
      isUrgent: false, // Not provided in API

      // Mock coordinates for Vietnam (API doesn't provide real coordinates)
      latitude: _getMockLatitude(),
      longitude: _getMockLongitude(),
    );

    print('DEBUG: DeliveryService._mapOrderFromApi() - Mapped order successfully:');
    print('  ID: ${mappedOrder.id}');
    print('  Customer: ${mappedOrder.customerName}');
    print('  Phone: ${mappedOrder.customerPhone}');
    print('  Address: ${mappedOrder.customerAddress}');
    print('  Status: ${mappedOrder.status} (API status: ${orderJson['status']})');
    print('  Amount: ${mappedOrder.totalAmount}');
    print('  Items count: ${mappedOrder.items.length}');

    return mappedOrder;
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
