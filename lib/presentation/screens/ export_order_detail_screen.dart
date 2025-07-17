import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/stock_action_button.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

import '../blocs/stock/stock_state.dart';

class ExportOrderDetailScreen extends StatefulWidget {
  final String exportId;
  final Map<String, dynamic> orderDetails;
  final VoidCallback onBack;

  const ExportOrderDetailScreen({
    Key? key,
    required this.exportId,
    required this.orderDetails,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ExportOrderDetailScreen> createState() => _ExportOrderDetailScreenState();
}

class _ExportOrderDetailScreenState extends State<ExportOrderDetailScreen> {
  late final StockBloc _stockBloc;
  late final ScannerBloc _scannerBloc;
  bool _isLoading = false;
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _stockBloc = getIt<StockBloc>();
    _scannerBloc = getIt<ScannerBloc>();

    // Initialize by loading the export progress
    _stockBloc.add(LoadExportProgress(widget.exportId));

    // Set default selected order if available
    final orders = widget.orderDetails['orders'] as List<dynamic>? ?? [];
    if (orders.isNotEmpty) {
      _selectedOrderId = orders[0]['order_id'];
    }
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
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết phiếu xuất #${widget.exportId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _stockBloc.add(LoadExportProgress(widget.exportId)),
              tooltip: 'Làm mới',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<StockBloc, StockState>(
          bloc: _stockBloc,
          builder: (context, state) {
            if (state is StockProgressLoaded) {
              return _buildProgressContent(state);
            } else if (state is StockError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return _buildInitialContent();
          },
        ),
      ),
    );
  }

  Widget _buildInitialContent() {
    final orders = widget.orderDetails['orders'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportInfo(),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  _buildEmptyOrdersState()
                else
                  _buildOrdersList(orders),
              ],
            ),
          ),
        ),
        if (orders.isNotEmpty)
          StockActionButtons(
            hasSelectedOrder: _selectedOrderId != null,
            isOrderComplete: false,
            onScanQR: () => _navigateToScanQR(),
          ),
      ],
    );
  }

  Widget _buildProgressContent(StockProgressLoaded state) {
    final progressData = state.progressData;
    final orders = progressData['orders'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportInfo(),
                const SizedBox(height: 16),
                _buildProgressBar(state),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  _buildEmptyOrdersState()
                else
                  _buildOrdersList(orders),
              ],
            ),
          ),
        ),
        if (orders.isNotEmpty)
          StockActionButtons(
            hasSelectedOrder: _selectedOrderId != null,
            isOrderComplete: state.canComplete,
            onScanQR: () => _navigateToScanQR(),
            onComplete: state.canComplete ? () => _completeExport() : null,
          ),
      ],
    );
  }

  Widget _buildEmptyOrdersState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có đơn đặt hàng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phiếu xuất kho này chưa có đơn đặt hàng được thêm vào',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportInfo() {
    final exportDate = DateTime.tryParse(widget.orderDetails['export_date']?.toString() ?? '') ?? DateTime.now();
    final formattedDate = '${exportDate.day.toString().padLeft(2, '0')}/${exportDate.month.toString().padLeft(2, '0')}/${exportDate.year}';
    final employeeName = widget.orderDetails['employee_name'] ?? 'N/A';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phiếu xuất #${widget.exportId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Ngày xuất: $formattedDate'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Nhân viên: $employeeName'),
              ],
            ),
            if (widget.orderDetails['note'] != null && widget.orderDetails['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Ghi chú: ${widget.orderDetails['note']}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(StockProgressLoaded state) {
    // Ensure we don't divide by zero
    final progress = state.totalCount > 0 ? state.scannedCount / state.totalCount : 0.0;
    final percentage = (progress * 100).toInt();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ xuất kho',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: percentage == 100 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.isNaN ? 0.0 : progress, // Handle NaN case
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 100 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              state.totalCount == 0
                  ? 'Không có sản phẩm nào cần xuất'
                  : 'Đã xuất: ${state.scannedCount}/${state.totalCount} sản phẩm',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách đơn hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...orders.map((order) => _buildOrderCard(order)).toList(),
      ],
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderId = order['order_id']?.toString() ?? 'N/A';
    final products = order['products'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOrderId = orderId;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #$orderId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedOrderId == orderId)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              if (products.isEmpty)
                _buildEmptyProductsState()
              else
                ...products.map((product) => _buildProductItem(product)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Không có sản phẩm nào',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic product) {
    final productId = product['product_id']?.toString() ?? 'N/A';
    final productName = product['product_name']?.toString() ?? 'Sản phẩm #$productId';
    final quantity = product['quantity'] ?? 0;
    final serials = product['serials'] as List<dynamic>? ?? [];
    final scannedCount = serials.length;
    final isComplete = scannedCount >= quantity;
    final productImage = product['product_image'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (productImage != null && productImage.isNotEmpty)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: productImage.startsWith('data:image')
                        ? Image.memory(
                      _imageFromBase64String(productImage),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                    )
                        : const Icon(Icons.image_not_supported),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isComplete ? Icons.check_circle : Icons.pending,
                          size: 14,
                          color: isComplete ? AppColors.success : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$scannedCount/$quantity đã quét',
                          style: TextStyle(
                            fontSize: 12,
                            color: isComplete ? AppColors.success : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$scannedCount/$quantity',
                  style: TextStyle(
                    color: isComplete ? AppColors.success : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (serials.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: serials.map((serial) {
                  final serialNumber = serial['serial_number']?.toString() ?? '';
                  return Chip(
                    label: Text(
                      serialNumber.length > 12
                          ? '${serialNumber.substring(0, 6)}...${serialNumber.substring(serialNumber.length - 6)}'
                          : serialNumber,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Uint8List _imageFromBase64String(String base64String) {
    try {
      // Extract the base64 part from the data URL
      final parts = base64String.split(',');
      final base64Data = parts.length > 1 ? parts[1] : base64String;

      return base64Decode(base64Data);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return Uint8List(0);
    }
  }

  void _navigateToScanQR() {
    if (_selectedOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đơn hàng trước khi quét'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set export ID and order ID in ScannerBloc
    _scannerBloc.add(SetExportId(widget.exportId, _selectedOrderId!));

    // Navigate to QR scanner
    getIt<DashboardBloc>().add(const SelectFunction('stockout'));
  }

  void _completeExport() {
    // Implement completion of export order
    // This would call the API to complete the export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hoàn thành đơn xuất thành công'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back
    widget.onBack();
  }
}