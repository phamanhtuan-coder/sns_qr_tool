import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class InProgressOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onComplete;

  const InProgressOrderCard({
    super.key,
    required this.order,
    required this.onComplete,
  });

  Future<void> _openMaps() async {
    if (order.latitude != null && order.longitude != null) {
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final url = 'tel:${order.customerPhone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                        ),
                      ),
                      Text(
                        order.customerName,
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
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.customerAddress,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.text,
              ),
            ),
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Hoàn thành'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
