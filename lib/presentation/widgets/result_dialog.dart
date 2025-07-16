import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ResultDialog extends StatefulWidget {
  final String type;
  final String title;
  final String message;
  final Map<String, String> details;
  final List<String> actions;
  final VoidCallback onClose;
  final VoidCallback? onSubmit;
  final VoidCallback? onRetry;
  final VoidCallback? onDashboard;
  final VoidCallback? onSendToDevice;
  final VoidCallback? onCallApi;
  final bool isLoading;
  final bool isApiLoading;
  final bool isBluetoothLoading;
  final String? apiError;
  final String? bluetoothError;
  final String? currentMode;

  const ResultDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.details,
    required this.actions,
    required this.onClose,
    this.onSubmit,
    this.onRetry,
    this.onDashboard,
    this.onSendToDevice,
    this.onCallApi,
    this.isLoading = false,
    this.isApiLoading = false,
    this.isBluetoothLoading = false,
    this.apiError,
    this.bluetoothError,
    this.currentMode,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  bool _isApiLoading = false;
  bool _isBluetoothLoading = false;

  bool get isFirmwareMode => widget.currentMode == 'firmware';
  bool get isStockInMode => widget.currentMode == 'stockin';

  @override
  void initState() {
    super.initState();
    _isApiLoading = widget.isApiLoading;
    _isBluetoothLoading = widget.isBluetoothLoading;
  }

  @override
  void didUpdateWidget(ResultDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isApiLoading != widget.isApiLoading ||
        oldWidget.isBluetoothLoading != widget.isBluetoothLoading) {
      setState(() {
        _isApiLoading = widget.isApiLoading;
        _isBluetoothLoading = widget.isBluetoothLoading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.type == 'success';
    final formattedDetails = _formatDetails();
    final hasErrors = widget.apiError != null || widget.bluetoothError != null;
    final isAnyLoading = (_isApiLoading || _isBluetoothLoading) &&
        !(widget.details['sent_to_desktop'] == 'Thành công' ||
            (!isFirmwareMode && !_isApiLoading && !_isBluetoothLoading));

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withAlpha(179)),
        ),
        Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 384),
              margin: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isSuccess),
                  if (formattedDetails.isNotEmpty)
                    _buildDetailsSection(context, formattedDetails),
                  if (hasErrors)
                    _buildErrorSection(context),
                  _buildActions(context, isSuccess, widget.actions),
                ],
              ),
            ),
          ),
        ),
        if (isAnyLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _getLoadingText(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getLoadingText() {
    if (_isApiLoading && _isBluetoothLoading) {
      return 'Đang xử lý...';
    } else if (_isApiLoading) {
      if (isStockInMode) {
        return 'Đang nhập kho...';
      }
      return 'Đang gửi API...';
    } else if (_isBluetoothLoading) {
      return 'Đang kết nối Bluetooth...';
    }
    return 'Đang xử lý...';
  }

  Widget _buildHeader(BuildContext context, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isSuccess ? Colors.green : Colors.red).withAlpha(26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, List<MapEntry<String, String>> formattedDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for QR data section
          if (_hasQrData())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin mã QR:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Details list
          ...formattedDetails.map((detail) => _buildDetailRow(context, detail)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, MapEntry<String, String> detail) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              detail.key,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    detail.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (detail.value.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyToClipboard(context, detail),
                    tooltip: 'Sao chép',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasQrData() {
    return widget.details.containsKey('serial_number') ||
        widget.details.containsKey('batch_production_id') ||
        widget.details.containsKey('template_id');
  }

  Widget _buildErrorSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.apiError != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API: ${widget.apiError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (widget.bluetoothError != null) ...[
            Row(
              children: [
                const Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bluetooth: ${widget.bluetoothError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingButton({
    required BuildContext context,
    required bool isLoading,
    required String loadingText,
    required String normalText,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        disabledBackgroundColor: theme.brightness == Brightness.light
            ? backgroundColor.withOpacity(0.5)
            : backgroundColor.withOpacity(0.3),
        disabledForegroundColor: theme.brightness == Brightness.light
            ? AppColors.onPrimary.withOpacity(0.6)
            : AppColors.onPrimary.withOpacity(0.4),
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.onPrimary.withOpacity(0.8),
                ),
              ),
            )
          else
            Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(isLoading ? loadingText : normalText),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isSuccess, List<String> actionsList) {
    final theme = Theme.of(context);
    final hasApiError = widget.apiError != null;
    final isAnyLoading = _isApiLoading || _isBluetoothLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: isAnyLoading ? null : (widget.onRetry ?? widget.onClose),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.brightness == Brightness.light
                        ? AppColors.primary
                        : AppColors.accent,
                    backgroundColor: theme.brightness == Brightness.light
                        ? Colors.grey[200]
                        : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20, color: theme.brightness == Brightness.light
                          ? AppColors.primary
                          : AppColors.accent),
                      const SizedBox(width: 8),
                      const Text('Quét lại'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildLoadingButton(
                  context: context,
                  isLoading: false,
                  loadingText: '',
                  normalText: 'Dashboard',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.dashboard,
                          (route) => false,
                    );
                  },
                  backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                  icon: Icons.home,
                ),
              ),
            ],
          ),

          if (widget.onSubmit != null) ...[
            const SizedBox(height: 12),
            _buildLoadingButton(
              context: context,
              isLoading: _isApiLoading,
              loadingText: isStockInMode ? 'Đang nhập kho...' : 'Đang xử lý...',
              normalText: isStockInMode ? 'Nhập kho' : 'Xác nhận',
              onPressed: hasApiError || isAnyLoading ? null : widget.onSubmit,
              backgroundColor: AppColors.primary,
              icon: isStockInMode ? Icons.inventory : Icons.check_circle,
            ),
          ],
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, MapEntry<String, String> detail) {
    Clipboard.setData(ClipboardData(text: detail.value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép ${detail.key.toLowerCase()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<MapEntry<String, String>> _formatDetails() {
    final formattedDetails = <MapEntry<String, String>>[];

    // Define the order and allowed keys for QR data
    final qrDataKeys = [
      'serial_number',
      'batch_production_id',
      'template_id',
      'template_name',
    ];

    final otherKeys = [
      'device_serial',
      'stage',
      'status'
    ];

    // Process QR data keys first (in order)
    for (final key in qrDataKeys) {
      if (widget.details.containsKey(key)) {
        final value = widget.details[key]!;

        // Skip empty template_name values
        if (key == 'template_name' && (value.isEmpty || value == 'null')) continue;

        final displayKey = _getDisplayKey(key);
        final displayValue = _getDisplayValue(key, value);

        formattedDetails.add(MapEntry(displayKey, displayValue));
      }
    }

    // Process other keys
    for (final key in otherKeys) {
      if (widget.details.containsKey(key)) {
        final value = widget.details[key]!;
        final displayKey = _getDisplayKey(key);
        final displayValue = _getDisplayValue(key, value);

        formattedDetails.add(MapEntry(displayKey, displayValue));
      }
    }

    return formattedDetails;
  }

  String _getDisplayKey(String key) {
    switch (key) {
      case 'serial_number':
        return 'Số serial';
      case 'batch_production_id':
        return 'Mã lô sản xuất';
      case 'template_id':
        return 'Mã template';
      case 'template_name':
        return 'Tên template';
      case 'device_serial':
        return 'Serial thiết bị';
      case 'stage':
        return 'Giai đoạn';
      case 'status':
        return 'Trạng thái';
      default:
        return key
            .replaceAll(RegExp(r'([A-Z])'), ' \$1')
            .replaceAll('_', ' ')
            .trim()
            .split(' ')
            .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  String _getDisplayValue(String key, String value) {
    switch (key) {
      case 'stage':
        return value == 'assembly' ? 'Lắp ráp' : value;
      case 'status':
        return value == 'in_progress' ? 'Đang xử lý' : value;
      default:
        return value;
    }
  }
}