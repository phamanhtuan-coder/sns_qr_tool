import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class SimpleMapWidget extends StatelessWidget {
  final Position? currentLocation;
  final List<DeliveryOrder> deliveryOrders;
  final DeliveryOrder? selectedOrder;
  final Function(DeliveryOrder)? onMarkerTap;

  const SimpleMapWidget({
    super.key,
    this.currentLocation,
    this.deliveryOrders = const [],
    this.selectedOrder,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Map header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.map,
                color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bản đồ giao hàng',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                ),
              ),
              const Spacer(),
              if (currentLocation != null)
                IconButton(
                  onPressed: () => _openCurrentLocationInMaps(context),
                  icon: Icon(
                    Icons.my_location,
                    color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                  ),
                  tooltip: 'Xem vị trí hiện tại',
                ),
              IconButton(
                onPressed: () => _openAllOrdersInMaps(context),
                icon: Icon(
                  Icons.map_outlined,
                  color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                ),
                tooltip: 'Xem tất cả đơn hàng',
              ),
            ],
          ),
        ),

        // Map content area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD),
                      isDark ? const Color(0xFF2D4A6B) : const Color(0xFFBBDEFB),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MapPatternPainter(isDark: isDark),
                      ),
                    ),

                    // Map content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Current location card
                          if (currentLocation != null) ...[
                            _buildLocationCard(
                              context,
                              'Vị trí hiện tại',
                              '${currentLocation!.latitude.toStringAsFixed(4)}, ${currentLocation!.longitude.toStringAsFixed(4)}',
                              Icons.my_location,
                              AppColors.success,
                              () => _openCurrentLocationInMaps(context),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Delivery orders list
                          Expanded(
                            child: deliveryOrders.isEmpty
                                ? _buildEmptyState(context, isDark)
                                : ListView.builder(
                                    itemCount: deliveryOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = deliveryOrders[index];
                                      return _buildOrderCard(context, order, isDark);
                                    },
                                  ),
                          ),

                          // Quick actions
                          _buildQuickActions(context, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    String title,
    String coordinates,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    coordinates,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, DeliveryOrder order, bool isDark) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (order.latitude != null && order.longitude != null) {
            _openOrderLocationInMaps(context, order);
          } else {
            onMarkerTap?.call(order);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      order.customerAddress,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (order.latitude != null && order.longitude != null)
                    Icon(
                      Icons.directions,
                      color: statusColor,
                      size: 18,
                    )
                  else
                    Icon(
                      Icons.location_off,
                      color: Colors.grey,
                      size: 18,
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có đơn hàng nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách giao hàng trống',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Vị trí hiện tại',
            Icons.my_location,
            AppColors.primary,
            currentLocation != null ? () => _openCurrentLocationInMaps(context) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context,
            'Tất cả đơn hàng',
            Icons.map,
            AppColors.info,
            deliveryOrders.isNotEmpty ? () => _openAllOrdersInMaps(context) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return AppColors.primary;
      case DeliveryStatus.started:
      case DeliveryStatus.inTransit:
        return AppColors.warning;
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.failed:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return Icons.assignment;
      case DeliveryStatus.started:
        return Icons.local_shipping;
      case DeliveryStatus.inTransit:
        return Icons.directions_car;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.failed:
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return 'Chờ giao';
      case DeliveryStatus.started:
        return 'Bắt đầu';
      case DeliveryStatus.inTransit:
        return 'Đang giao';
      case DeliveryStatus.delivered:
        return 'Hoàn thành';
      case DeliveryStatus.failed:
        return 'Thất bại';
      default:
        return 'Không xác định';
    }
  }

  Future<void> _openCurrentLocationInMaps(BuildContext context) async {
    if (currentLocation == null) return;

    try {
      await _openGoogleMaps(
        context,
        currentLocation!.latitude,
        currentLocation!.longitude,
        label: 'Vị trí hiện tại',
      );
    } catch (e) {
      _showError(context, 'Không thể mở bản đồ: $e');
    }
  }

  Future<void> _openOrderLocationInMaps(BuildContext context, DeliveryOrder order) async {
    if (order.latitude == null || order.longitude == null) {
      _showError(context, 'Đơn hàng không có thông tin tọa độ');
      return;
    }

    try {
      await _openGoogleMaps(
        context,
        order.latitude!,
        order.longitude!,
        label: '${order.id} - ${order.customerName}',
      );
    } catch (e) {
      _showError(context, 'Không thể mở bản đồ: $e');
    }
  }

  Future<void> _openAllOrdersInMaps(BuildContext context) async {
    if (deliveryOrders.isEmpty) return;

    final ordersWithLocation = deliveryOrders
        .where((order) => order.latitude != null && order.longitude != null)
        .toList();

    if (ordersWithLocation.isEmpty) {
      _showError(context, 'Không có đơn hàng nào có thông tin tọa độ');
      return;
    }

    // Show dialog to select which order to open
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn đơn hàng để xem trên bản đồ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...ordersWithLocation.map((order) => ListTile(
              leading: Icon(
                _getStatusIcon(order.status),
                color: _getStatusColor(order.status),
              ),
              title: Text(order.id),
              subtitle: Text(order.customerName),
              trailing: const Icon(Icons.directions),
              onTap: () {
                Navigator.pop(context);
                _openOrderLocationInMaps(context, order);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    double latitude,
    double longitude, {
    String? label,
  }) async {
    // Improved URL list with better Android compatibility
    final urls = [
      // Try Google Maps app with navigation intent
      'google.navigation:q=$latitude,$longitude&mode=d',
      // Try with explicit geo intent for Android
      'geo:$latitude,$longitude?q=$latitude,$longitude',
      // Try opening Google Maps app directly
      'https://maps.google.com/maps?q=$latitude,$longitude',
      // Try with directions
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      // Try search API
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      // Fallback to browser
      'https://maps.google.com/?q=$latitude,$longitude',
    ];

    bool launched = false;

    for (String url in urls) {
      try {
        print('DEBUG: Trying to launch URL: $url');
        final uri = Uri.parse(url);

        // Check if URL can be launched
        if (await canLaunchUrl(uri)) {
          print('DEBUG: URL can be launched: $url');
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: false,
            ),
          );
          launched = true;
          print('DEBUG: Successfully launched URL: $url');
          break;
        } else {
          print('DEBUG: Cannot launch URL: $url');
        }
      } catch (e) {
        print('DEBUG: Failed to launch URL: $url, Error: $e');
        continue;
      }
    }

    if (!launched) {
      // Show coordinates in a dialog as fallback
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tọa độ địa điểm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitude: $latitude'),
                Text('Longitude: $longitude'),
                const SizedBox(height: 16),
                const Text(
                  'Vui lòng mở ứng dụng Google Maps và nhập tọa độ trên.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Copy coordinates to clipboard
                  Clipboard.setData(ClipboardData(text: '$latitude,$longitude'));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tọa độ')),
                  );
                },
                child: const Text('Sao chép tọa độ'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class MapPatternPainter extends CustomPainter {
  final bool isDark;

  MapPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid pattern
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some decorative elements
    final decorativePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw some circles representing locations
    final positions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.8),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, 8, decorativePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
