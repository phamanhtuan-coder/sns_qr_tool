import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final Position? currentLocation;
  final VoidCallback? onTap;
  final VoidCallback? onStartDelivery;
  final bool showProgress;
  final bool showResult;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    this.currentLocation,
    this.onTap,
    this.onStartDelivery,
    this.showProgress = false,
    this.showResult = false,
  });

  @override
  State<DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<DeliveryOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall() async {
    final url = 'tel:${widget.order.customerPhone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openMaps() async {
    if (widget.order.latitude != null && widget.order.longitude != null) {
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.order.latitude},${widget.order.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case DeliveryStatus.assigned:
        return AppColors.info;
      case DeliveryStatus.started:
      case DeliveryStatus.inTransit:
        return AppColors.warning;
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.failed:
        return AppColors.error;
      case DeliveryStatus.cancelled:
        return AppColors.iconSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () => _animationController.reverse(),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with order ID and status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.id,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.order.customerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.order.status.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.customerAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.order.customerPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Only show delivery date, not time/distance as API doesn't provide this data
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Giao trước: ${_formatDate(widget.order.expectedDeliveryDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Action buttons for different states
                    if (widget.order.status == DeliveryStatus.assigned) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onStartDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Bắt đầu giao hàng'),
                        ),
                      ),
                    ],

                    if (widget.order.status == DeliveryStatus.started ||
                        widget.order.status == DeliveryStatus.inTransit) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _makePhoneCall,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                                ),
                              ),
                              icon: Icon(
                                Icons.phone,
                                size: 18,
                                color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                              ),
                              label: Text(
                                'Gọi',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openMaps,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                                ),
                              ),
                              icon: Icon(
                                Icons.map,
                                size: 18,
                                color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                              ),
                              label: Text(
                                'Chỉ đường',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Show result for completed orders
                    if (widget.showResult && widget.order.status.isCompleted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.order.status == DeliveryStatus.delivered
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _getStatusColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.order.status == DeliveryStatus.delivered
                                        ? 'Đã giao thành công'
                                        : 'Giao hàng thất bại',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                  if (widget.order.deliveryNote?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.order.deliveryNote!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (widget.order.deliveredAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lúc: ${_formatDateTime(widget.order.deliveredAt!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
