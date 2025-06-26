import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class DeviceTypeCard extends StatefulWidget {
  final DeviceType deviceType;
  final Map<String, bool> scannedItems;
  final Map<String, int> scannedCounts;
  final bool isStockIn;

  const DeviceTypeCard({
    super.key,
    required this.deviceType,
    required this.scannedItems,
    required this.scannedCounts,
    required this.isStockIn,
  });

  @override
  State<DeviceTypeCard> createState() => _DeviceTypeCardState();
}

class _DeviceTypeCardState extends State<DeviceTypeCard> {
  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'smart sensor':
        return Icons.sensors;
      case 'control unit':
        return Icons.settings_input_component;
      case 'gateway':
        return Icons.router;
      default:
        return Icons.device_hub;
    }
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'smart sensor':
        return Colors.blue;
      case 'control unit':
        return Colors.green;
      case 'gateway':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    final deviceColor = _getDeviceColor(widget.deviceType.type);

    if (widget.isStockIn) {
      return _buildStockInCard(isDarkMode, deviceColor);
    } else {
      return _buildStockOutCard(isDarkMode, deviceColor);
    }
  }

  Widget _buildStockInCard(bool isDarkMode, Color deviceColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: deviceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDeviceIcon(widget.deviceType.type),
                    color: deviceColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.deviceType.type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors
                          .text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.deviceType.devices != null)
              ...widget.deviceType.devices!.map((device) {
                final isScanned = widget.scannedItems[device.id] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkBackground : Colors
                        .grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isScanned
                          ? AppColors.success.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.id,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              device.serialNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isScanned ? AppColors.success : Colors
                              .grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockOutCard(bool isDarkMode, Color deviceColor) {
    final scanned = widget.scannedCounts[widget.deviceType.type] ?? 0;
    final progress = widget.deviceType.quantity > 0
        ? (scanned / widget.deviceType.quantity).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = scanned >= widget.deviceType.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isComplete ? AppColors.success : deviceColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDeviceIcon(widget.deviceType.type),
                    color: isComplete ? AppColors.success : deviceColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deviceType.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$scanned',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppColors.success : AppColors
                                  .primary,
                            ),
                          ),
                          Text(
                            '/${widget.deviceType.quantity} thiết bị',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkBackground : Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: isComplete ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}