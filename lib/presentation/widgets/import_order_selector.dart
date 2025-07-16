import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ImportOrderSelector extends StatelessWidget {
  final List<ImportOrder> importOrders;
  final Function(String) onSelectOrder;

  const ImportOrderSelector({
    super.key,
    required this.importOrders,
    required this.onSelectOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (importOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn nhập nào cần xử lý',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: importOrders.length,
      itemBuilder: (context, index) {
        final order = importOrders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, ImportOrder order) {
    final status = order.status;
    final isNotStarted = status == 0;
    final isInProgress = status == 1;

    // Determine status display
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isNotStarted) {
      statusText = 'Chưa bắt đầu';
      statusColor = AppColors.success;
      statusIcon = Icons.play_circle_outline;
    } else if (isInProgress) {
      statusText = 'Đang xử lý';
      statusColor = AppColors.warning;
      statusIcon = Icons.play_circle_filled;
    } else {
      statusText = 'Khác';
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onSelectOrder(order.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Kho: ${order.warehouseId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày nhập: ${_formatDate(order.importDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Ngày tạo: ${_formatDate(order.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Optional total quantity display
              if (order.totalQuantity != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tổng số lượng: ${order.totalQuantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Action hint
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isNotStarted
                        ? 'Nhấn để bắt đầu đơn nhập'
                        : 'Nhấn để xem chi tiết',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}