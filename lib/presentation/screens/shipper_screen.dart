import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/custom_app_bar.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/delivery_order_card.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/delivery_detail_screen.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class ShipperScreen extends StatefulWidget {
  const ShipperScreen({super.key});

  @override
  State<ShipperScreen> createState() => _ShipperScreenState();
}

class _ShipperScreenState extends State<ShipperScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    // Load delivery orders when screen initializes
    context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _handleScanQR() {
    Navigator.of(context).pushNamed(
      AppRouter.scanner,
      arguments: {
        'purpose': 'delivery_scan',
        'context': context,
      },
    );
  }

  void _showStartDeliveryDialog(String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Bắt đầu giao hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn bắt đầu giao đơn hàng:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống sẽ bắt đầu theo dõi vị trí của bạn.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<DeliveryBloc>().add(StartDeliveryOrder(orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã bắt đầu giao hàng!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Bắt đầu giao'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Giao hàng',
        showThemeSwitch: true,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          // Tab Bar as a separate widget
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment),
                  text: 'Chờ giao',
                ),
                Tab(
                  icon: Icon(Icons.local_shipping),
                  text: 'Đang giao',
                ),
                Tab(
                  icon: Icon(Icons.check_circle),
                  text: 'Hoàn thành',
                ),
                Tab(
                  icon: Icon(Icons.map),
                  text: 'Bản đồ',
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: BlocBuilder<DeliveryBloc, DeliveryState>(
              builder: (context, state) {
                if (state is DeliveryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is DeliveryError) {
                  return _buildErrorState(state.message);
                }

                if (state is DeliveryLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAssignedOrders(state),
                      _buildInProgressOrders(state),
                      _buildCompletedOrders(state),
                      _buildMapView(state),
                    ],
                  );
                }

                return _buildInitialState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _handleScanQR,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text(
            'Quét mã đơn',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Giao hàng thông minh',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Quản lý đơn hàng và giao hàng hiệu quả',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải danh sách đơn hàng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedOrders(DeliveryLoaded state) {
    final assignedOrders = state.orders
        .where((order) => order.status == DeliveryStatus.assigned)
        .toList();

    if (assignedOrders.isEmpty) {
      return _buildEmptyOrdersState(
        icon: Icons.assignment_outlined,
        title: 'Không có đơn hàng chờ giao',
        subtitle: 'Tất cả đơn hàng đã được bắt đầu giao hoặc hoàn thành',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignedOrders.length,
        itemBuilder: (context, index) {
          final order = assignedOrders[index];
          return DeliveryOrderCard(
            order: order,
            currentLocation: state.currentLocation,
            onTap: () => _navigateToDetail(order),
            onStartDelivery: () => _showStartDeliveryDialog(order.id),
          );
        },
      ),
    );
  }

  Widget _buildInProgressOrders(DeliveryLoaded state) {
    final inProgressOrders = state.orders
        .where((order) =>
            order.status == DeliveryStatus.started ||
            order.status == DeliveryStatus.inTransit)
        .toList();

    if (inProgressOrders.isEmpty) {
      return _buildEmptyOrdersState(
        icon: Icons.local_shipping_outlined,
        title: 'Không có đơn hàng đang giao',
        subtitle: 'Bắt đầu giao một đơn hàng để theo dõi tiến trình',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inProgressOrders.length,
        itemBuilder: (context, index) {
          final order = inProgressOrders[index];
          return DeliveryOrderCard(
            order: order,
            currentLocation: state.currentLocation,
            onTap: () => _navigateToDetail(order),
            showProgress: true,
          );
        },
      ),
    );
  }

  Widget _buildCompletedOrders(DeliveryLoaded state) {
    final completedOrders = state.orders
        .where((order) => order.status.isCompleted)
        .toList();

    if (completedOrders.isEmpty) {
      return _buildEmptyOrdersState(
        icon: Icons.check_circle_outline,
        title: 'Chưa có đơn hàng hoàn thành',
        subtitle: 'Các đơn hàng đã giao sẽ hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedOrders.length,
        itemBuilder: (context, index) {
          final order = completedOrders[index];
          return DeliveryOrderCard(
            order: order,
            currentLocation: state.currentLocation,
            onTap: () => _navigateToDetail(order),
            showResult: true,
          );
        },
      ),
    );
  }

  Widget _buildMapView(DeliveryLoaded state) {
    // For now, show a placeholder. In a real app, you'd integrate with Google Maps or similar
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Bản đồ sẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Tích hợp Google Maps/OpenStreetMap',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.currentLocation != null) ...[
            Container(
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
                          'Lat: ${state.currentLocation!.latitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Lng: ${state.currentLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[400]?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  void _navigateToDetail(DeliveryOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(order: order),
      ),
    );
  }
}
