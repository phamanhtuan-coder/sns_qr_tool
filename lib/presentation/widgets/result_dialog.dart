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
  Timer? _loadingTimeoutTimer;

  // Kiểm tra xem hiện tại có phải là mode firmware không
  bool get isFirmwareMode => widget.currentMode == 'firmware';

  @override
  void initState() {
    super.initState();
    _isApiLoading = widget.isApiLoading;
    _isBluetoothLoading = widget.isBluetoothLoading;

    // Set loading timeout timer if buttons are in loading state
    if (_isApiLoading || _isBluetoothLoading) {
      _startLoadingTimeout();
    }
  }

  @override
  void didUpdateWidget(ResultDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update loading states when widget updates
    if (oldWidget.isApiLoading != widget.isApiLoading ||
        oldWidget.isBluetoothLoading != widget.isBluetoothLoading) {
      _isApiLoading = widget.isApiLoading;
      _isBluetoothLoading = widget.isBluetoothLoading;

      // Reset timeout timer
      _loadingTimeoutTimer?.cancel();
      if (_isApiLoading || _isBluetoothLoading) {
        _startLoadingTimeout();
      }
    }
  }

  void _startLoadingTimeout() {
    // Cancel existing timer if any
    _loadingTimeoutTimer?.cancel();

    // Dynamic timeout based on current mode
    Duration timeoutDuration = _getTimeoutDuration();

    // Create dynamic timeout timer
    _loadingTimeoutTimer = Timer(timeoutDuration, () {
      if (mounted) {
        setState(() {
          _isApiLoading = false;
          _isBluetoothLoading = false;
          print("⚡ DEBUG: Loading timeout occurred - automatically stopping loading state after ${timeoutDuration.inSeconds} seconds");
        });
      }
    });
  }

  Duration _getTimeoutDuration() {
    // Dynamic timeout based on current mode
    switch (widget.currentMode) {
      case 'firmware':
        return const Duration(seconds: 30); // Longer timeout for firmware
      case 'stockin':
      case 'stockout':
        return const Duration(seconds: 20); // Medium timeout for stock operations
      default:
        return const Duration(seconds: 15); // Default timeout
    }
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.type == 'success';
    final formattedDetails = _formatDetails();
    final hasErrors = widget.apiError != null || widget.bluetoothError != null;
    // Fix loading state logic to handle both firmware and non-firmware modes
    final isAnyLoading = (_isApiLoading || _isBluetoothLoading) &&
        !(widget.details['sent_to_desktop'] == 'Thành công' || (!isFirmwareMode && !_isApiLoading && !_isBluetoothLoading));

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
        // Add loading overlay
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
                        _isApiLoading && _isBluetoothLoading
                            ? 'Đang xử lý...'
                            : _isApiLoading
                                ? 'Đang gửi API...'
                                : 'Đang kết nối Bluetooth...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Timeout sau ${_getTimeoutDuration().inSeconds} giây',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
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

  Widget _buildHeader(BuildContext context, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isSuccess ? Colors.green : Colors.red).withAlpha(26), // 0.1 * 255 ≈ 26
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
        children: formattedDetails.map((detail) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  detail.key,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        detail.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (detail.value.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _copyToClipboard(context, detail),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
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
    final hasBluetoothError = widget.bluetoothError != null;
    // Update loading state check to properly handle non-firmware modes
    final isAnyLoading = (_isApiLoading || _isBluetoothLoading) &&
        !(widget.details['sent_to_desktop'] == 'Thành công' || (!isFirmwareMode && !_isApiLoading && !_isBluetoothLoading));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // First row of buttons
          Row(
            children: [
              // Button 1: Scan Again (Quét lại) - Always shown
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

              // Button 2: Dashboard - Always shown
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

          // Second row of buttons - shown only in specific modes
          if (isFirmwareMode || widget.onSubmit != null)
            const SizedBox(height: 12),

          // Show action buttons for firmware mode
          if (isFirmwareMode)
            Row(
              children: [
                // Button 3: Send to Device (Only show in firmware mode)
                Expanded(
                  child: _buildLoadingButton(
                    context: context,
                    isLoading: _isBluetoothLoading && !_isApiLoading,
                    loadingText: 'Đang kết nối...',
                    normalText: 'Gửi tới thiết bị',
                    onPressed: hasBluetoothError || isAnyLoading ? null : widget.onSendToDevice,
                    backgroundColor: const Color(0xFF9333EA), // Màu tím cho bluetooth
                    icon: Icons.bluetooth,
                  ),
                ),

                const SizedBox(width: 12),

                // Button 4: Confirm - Calls API and then sends data to device in firmware mode
                Expanded(
                  child: _buildLoadingButton(
                    context: context,
                    isLoading: _isApiLoading || _isBluetoothLoading,
                    loadingText: (_isApiLoading && _isBluetoothLoading) ?
                                'Đang xử lý...' :
                                (_isApiLoading ? 'Đang gửi API...' : 'Đang kết nối...'),
                    normalText: 'Xác nhận',
                    onPressed: hasApiError || hasBluetoothError || isAnyLoading ? null : widget.onSubmit,
                    backgroundColor: AppColors.primary,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            )
          // For non-firmware modes, just show Submit/Confirm button if provided
          else if (widget.onSubmit != null)
            _buildLoadingButton(
              context: context,
              isLoading: _isApiLoading,
              loadingText: 'Đang xử lý...',
              normalText: 'Xác nhận',
              onPressed: hasApiError || isAnyLoading ? null : widget.onSubmit,
              backgroundColor: AppColors.primary,
              icon: Icons.check_circle,
            ),
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
    final allowedKeys = ['device_serial', 'stage', 'status'];

    widget.details.forEach((key, value) {
      // Only show allowed keys
      if (!allowedKeys.contains(key)) return;

      // Format keys for display
      String displayKey = key
          .replaceAll(RegExp(r'([A-Z])'), ' \$1')
          .replaceAll('_', ' ')
          .trim()
          .split(' ')
          .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
          .join(' ');

      // Format values for display
      String displayValue = value;
      if (key == 'stage') {
        displayValue = value == 'assembly' ? 'Lắp ráp' : value;
      } else if (key == 'status') {
        displayValue = value == 'in_progress' ? 'Đang xử lý' : value;
      }

      formattedDetails.add(MapEntry(displayKey, displayValue));
    });

    return formattedDetails;
  }
}
