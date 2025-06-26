import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/custom_app_bar.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/device_type.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/order_selector.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/stock_action_button.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StockBloc>().add(const LoadStockOrders('stockOut'));
  }

  void _handleScanQR() {
    Navigator.of(context).pushNamed(
      AppRouter.scanner,
      arguments: {
        'purpose': 'stockout',
        'context': context,
      },
    );
  }

  void _handleCompleteOrder() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hoàn thành đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn hoàn thành đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<StockBloc>().add(const CompleteOrder());

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đơn hàng đã được hoàn thành thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Xuất kho',
        showThemeSwitch: true,
        automaticallyImplyLeading: true,
      ),
      body: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state is StockLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is StockError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StockBloc>().add(const LoadStockOrders('stockOut'));
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StockLoaded) {
            return Column(
              children: [
                // Order Selector
                OrderSelector(
                  orders: state.orders,
                  selectedOrder: state.selectedOrder,
                  onOrderSelected: (orderId) {
                    context.read<StockBloc>().add(SelectOrder(orderId));
                  },
                  title: 'Chọn đơn xuất hàng',
                ),

                // Content Area
                Expanded(
                  child: state.selectedOrder != null
                      ? _buildOrderContent(state)
                      : _buildEmptyState(),
                ),

                // Action Buttons
                StockActionButtons(
                  hasSelectedOrder: state.selectedOrder != null,
                  isOrderComplete: state.isOrderComplete,
                  onScanQR: _handleScanQR,
                  onComplete: state.isOrderComplete ? _handleCompleteOrder : null,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderContent(StockLoaded state) {
    final order = state.selectedOrder!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thiết bị cần quét',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.isOrderComplete
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.success.withOpacity(0.1))
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.warning.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  state.isOrderComplete ? 'Hoàn thành' : 'Đang thực hiện',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.isOrderComplete
                        ? AppColors.success
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber[300] // Light amber for dark theme
                            : Colors.amber[800], // Dark amber for light theme
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Device Types List
          ...order.deviceTypes.map((deviceType) => DeviceTypeCard(
            deviceType: deviceType,
            scannedItems: state.scannedItems,
            scannedCounts: state.scannedCounts,
            isStockIn: false,
          )).toList(),

          // Scanned Devices List (if any)
          if (state.scannedDevices.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Thiết bị đã quét',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildScannedDevicesGroups(state.scannedDevices),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildScannedDevicesGroups(List<Device> scannedDevices) {
    // Group devices by type (this would need to be implemented based on device data)
    final Map<String, List<Device>> groupedDevices = {};

    for (final device in scannedDevices) {
      // This is a simplified grouping - in real implementation,
      // you'd group by actual device type from device metadata
      final type = device.serial.contains('001') || device.serial.contains('002') || device.serial.contains('003')
          ? 'Smart Sensor'
          : device.serial.contains('004') || device.serial.contains('005')
          ? 'Control Unit'
          : 'Gateway';

      groupedDevices.putIfAbsent(type, () => []).add(device);
    }

    return groupedDevices.entries.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.cardBackground,
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
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((device) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBackground
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ID thiết bị:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                device.serial,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Serial Number:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SN${device.serial.split('-').last}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa chọn đơn hàng',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn đơn hàng để xem danh sách thiết bị cần quét',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}