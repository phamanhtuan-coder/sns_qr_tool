import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/custom_app_bar.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/delivery_order_card.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/delivery_detail_screen.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/delivery_completion_dialog.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/start_delivery_dialog.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/in_progress_order_card.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/map_view_widget.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/shipper/shipper_state_widgets.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ShipperScreen extends StatefulWidget {
  const ShipperScreen({super.key});

  @override
  State<ShipperScreen> createState() => _ShipperScreenState();
}

class _ShipperScreenState extends State<ShipperScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load delivery orders when screen initializes
    context.read<DeliveryBloc>().add(const LoadDeliveryOrders());

    // Start location tracking
    _startLocationTracking();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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

  void _showStartDeliveryDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => StartDeliveryDialog(orderId: orderId),
    );
  }

  void _showDeliveryCompletionDialog(DeliveryOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryCompletionDialog(order: order),
    );
  }

  void _navigateToDetail(DeliveryOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(order: order),
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
          // Tab Bar
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
                  return ErrorShipperState(
                    message: state.message,
                    onRetry: () {
                      context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
                    },
                  );
                }

                if (state is DeliveryLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAssignedOrders(state),
                      _buildInProgressOrders(state),
                      _buildCompletedOrders(state),
                      MapViewWidget(
                        currentLocation: state.currentLocation,
                        deliveryOrders: state.orders,
                        selectedOrder: state.selectedOrder,
                      ),
                    ],
                  );
                }

                return InitialShipperState(
                  onLoadOrders: () {
                    context.read<DeliveryBloc>().add(const LoadDeliveryOrders());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedOrders(DeliveryLoaded state) {
    final assignedOrders = state.orders
        .where((order) => order.status == DeliveryStatus.assigned)
        .toList();

    if (assignedOrders.isEmpty) {
      return const EmptyOrdersState(
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
      return const EmptyOrdersState(
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
          return InProgressOrderCard(
            order: order,
            onComplete: () => _showDeliveryCompletionDialog(order),
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
      return const EmptyOrdersState(
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
}
