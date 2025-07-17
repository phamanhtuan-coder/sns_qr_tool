import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/export_order_card.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

import ' export_order_detail_screen.dart';
import '../blocs/stock/stock_state.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({Key? key}) : super(key: key);

  @override
  _StockOutScreenState createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  late final StockBloc _stockBloc;
  ExportOrder? _selectedOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stockBloc = getIt<StockBloc>();
    _loadExportOrders();
  }

  void _loadExportOrders() {
    _stockBloc.add(const LoadExportOrders());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      bloc: _stockBloc,
      listener: (context, state) {
        if (state is StockLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is StockError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is StockExportOrderStarted) {
          _navigateToOrderDetail(state.exportId, state.orderDetails);
        } else if (state is StockExportOrderNotStarted) {
          _navigateToOrderDetail(state.exportId, state.orderDetails);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xuất kho'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadExportOrders,
              tooltip: 'Làm mới danh sách',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<StockBloc, StockState>(
          bloc: _stockBloc,
          buildWhen: (previous, current) => current is StockExportLoaded,
          builder: (context, state) {
            if (state is StockExportLoaded) {
              return _buildExportOrdersList(state.exportOrders);
            }
            return const Center(child: Text('Không có dữ liệu'));
          },
        ),
      ),
    );
  }

  Widget _buildExportOrdersList(List<ExportOrder> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có đơn xuất kho nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExportOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isSelected = _selectedOrder?.id == order.id;

        return ExportOrderCard(
          order: order,
          isSelected: isSelected,
          onTap: () => _selectOrder(order),
          onStartOrder: order.status == 0
              ? () => _startExportOrder(order.id.toString())
              : null,
        );
      },
    );
  }

  void _selectOrder(ExportOrder order) {
    setState(() {
      _selectedOrder = order;
    });

    // If order is already in progress (status 1), directly load details
    if (order.status == 1) {
      _stockBloc.add(SelectExportOrder(order.id.toString()));
    } else if (order.status == 0) {
      // Show a confirmation dialog to start the order
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận xuất kho'),
          content: const Text('Bạn muốn bắt đầu xuất kho đơn hàng này?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stockBloc.add(SelectExportOrder(order.id.toString()));
              },
              child: const Text('Xem chi tiết'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startExportOrder(order.id.toString());
              },
              child: const Text('Bắt đầu xuất'),
            ),
          ],
        ),
      );
    } else {
      // For completed orders, just view details
      _stockBloc.add(SelectExportOrder(order.id.toString()));
    }
  }

  void _startExportOrder(String exportId) {
    _stockBloc.add(StartExportOrder(exportId));
  }

  void _navigateToOrderDetail(String exportId, Map<String, dynamic> orderDetails) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExportOrderDetailScreen(
          exportId: exportId,
          orderDetails: orderDetails,
          onBack: () {
            Navigator.pop(context);
            _loadExportOrders(); // Refresh list after returning
          },
        ),
      ),
    );
  }
}