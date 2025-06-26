import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class OrderSelector extends StatefulWidget {
  final List<StockOrder> orders;
  final StockOrder? selectedOrder;
  final Function(String) onOrderSelected;
  final String title;

  const OrderSelector({
    super.key,
    required this.orders,
    required this.selectedOrder,
    required this.onOrderSelected,
    required this.title,
  });

  @override
  State<OrderSelector> createState() => _OrderSelectorState();
}

class _OrderSelectorState extends State<OrderSelector> {
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
            widget.title,
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
                value: widget.selectedOrder?.id,
                hint: Text(
                  'Chọn đơn hàng',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkSurface : Colors.white,
                items: widget.orders.map((order) {
                  return DropdownMenuItem<String>(
                    value: order.id,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.type == 'stockIn'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.type == 'stockIn' ? 'Nhập' : 'Xuất',
                            style: TextStyle(
                              fontSize: 12,
                              color: order.type == 'stockIn'
                                  ? AppColors.primary
                                  : AppColors.error,
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
                                order.date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onOrderSelected(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}