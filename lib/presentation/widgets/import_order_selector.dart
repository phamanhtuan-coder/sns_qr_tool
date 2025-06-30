import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ImportOrderSelector extends StatefulWidget {
  final List<ImportOrder> importOrders;
  final ImportOrder? selectedImportOrder;
  final Function(String) onImportOrderSelected;

  const ImportOrderSelector({
    super.key,
    required this.importOrders,
    required this.selectedImportOrder,
    required this.onImportOrderSelected,
  });

  @override
  State<ImportOrderSelector> createState() => _ImportOrderSelectorState();
}

class _ImportOrderSelectorState extends State<ImportOrderSelector> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.darkDivider : AppColors.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn đơn nhập kho',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkBackground : Colors.white,
              border: Border.all(
                color: isDarkMode ? AppColors.darkDivider : AppColors.dividerColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedImportOrder?.id,
                hint: Text(
                  'Chọn đơn nhập',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkSurface : Colors.white,
                items: widget.importOrders.map((order) {
                  return DropdownMenuItem<String>(
                    value: order.id,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Nhập',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.text,
                                ),
                              ),
                              Text(
                                _formatDate(order.importDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onImportOrderSelected(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chờ';
      case 1:
        return 'Đang nhập';
      case 2:
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }
}
