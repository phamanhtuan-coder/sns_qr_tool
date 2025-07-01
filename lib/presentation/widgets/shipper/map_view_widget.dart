import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/google_maps_webview.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MapViewWidget extends StatelessWidget {
  final Position? currentLocation;
  final List<DeliveryOrder> deliveryOrders;
  final DeliveryOrder? selectedOrder;

  const MapViewWidget({
    super.key,
    this.currentLocation,
    this.deliveryOrders = const [],
    this.selectedOrder,
  });

  void _startLocationTracking(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog(context);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog(context);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog(context);
        return;
      }

      // Listen to location changes
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        context.read<DeliveryBloc>().add(UpdateLocation(position));
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS không khả dụng'),
        content: const Text('Vui lòng bật GPS để sử dụng tính năng bản đồ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền truy cập vị trí'),
        content: const Text('Ứng dụng cần quyền truy cập vị trí để hiển thị bản đồ và theo dõi giao hàng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startLocationTracking(context);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền truy cập vị trí bị từ chối'),
        content: const Text('Vui lòng vào Cài đặt > Ứng dụng > Smart Net QR Scanner > Quyền để cấp quyền truy cập vị trí.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Google Maps WebView
          Expanded(
            child: GoogleMapsWebView(
              currentLocation: currentLocation,
              deliveryOrders: deliveryOrders,
              selectedOrder: selectedOrder,
              onMarkerTap: (order) {
                // Handle marker tap - could show order details or navigate to detail screen
                _showOrderQuickActions(context, order);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Current location info and controls
          if (currentLocation != null) ...[
            _buildCurrentLocationCard(context, isDark),
          ] else ...[
            _buildNoLocationCard(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              color: AppColors.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí hiện tại',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Lat: ${currentLocation!.latitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Lng: ${currentLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  final position = currentLocation!;
                  final url = 'https://www.google.com/maps/@${position.latitude},${position.longitude},15z';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icon(
                  Icons.open_in_new,
                  color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                ),
                tooltip: 'Mở trong Google Maps',
              ),
              IconButton(
                onPressed: () => _shareLocation(context),
                icon: Icon(
                  Icons.share,
                  color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                ),
                tooltip: 'Chia sẻ vị trí',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoLocationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              color: AppColors.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Chưa có thông tin vị trí\nVui lòng bật GPS và cấp quyền truy cập',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _startLocationTracking(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bật GPS'),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext context) async {
    if (currentLocation != null) {
      final position = currentLocation!;
      final url = 'https://www.google.com/maps/@${position.latitude},${position.longitude},15z';

      // For now, just copy to clipboard - you could integrate with share_plus package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vị trí: $url'),
          action: SnackBarAction(
            label: 'Mở',
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      );
    }
  }

  void _showOrderQuickActions(BuildContext context, DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.customerAddress,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _makePhoneCall(order.customerPhone);
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Gọi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (order.latitude != null && order.longitude != null) {
                        final url = 'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Chỉ đường'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
