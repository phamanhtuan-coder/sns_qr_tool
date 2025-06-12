import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ResultDialog extends StatelessWidget {
  final String type;
  final String title;
  final String message;
  final Map<String, String> details;
  final List<String> actions;
  final VoidCallback onClose;
  final VoidCallback? onSubmit; // Callback riêng cho nút Xác nhận
  final VoidCallback? onRetry; // Callback riêng cho nút Quét lại
  final VoidCallback? onDashboard; // Callback riêng cho nút Quay về/Dashboard
  final bool isLoading;
  final bool isApiLoading;
  final bool isBluetoothLoading;
  final String? apiError;
  final String? bluetoothError;

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
    this.isLoading = false,
    this.isApiLoading = false,
    this.isBluetoothLoading = false,
    this.apiError,
    this.bluetoothError,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == 'success';
    final formattedDetails = _formatDetails();
    final hasErrors = apiError != null || bluetoothError != null;
    // Modify loading state to stop when success details include sent_to_desktop
    final isAnyLoading = (isLoading || isApiLoading || isBluetoothLoading) &&
        !(details['sent_to_desktop'] == 'Thành công');

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
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
                  _buildActions(context, isSuccess, actions),
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
                        isApiLoading && isBluetoothLoading
                            ? 'Đang xử lý...'
                            : isApiLoading
                                ? 'Đang gửi API...'
                                : 'Đang kết nối Bluetooth...',
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
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
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
            onPressed: onClose,
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
          if (apiError != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API: $apiError',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (bluetoothError != null) ...[
            Row(
              children: [
                const Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bluetooth: $bluetoothError',
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
    final hasApiError = apiError != null;
    final hasBluetoothError = bluetoothError != null;
    // Update loading state check to include the success condition
    final isAnyLoading = (isApiLoading || isBluetoothLoading) &&
        !(details['sent_to_desktop'] == 'Thành công');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Quét lại (retry)
          if (actionsList.contains('retry'))
            Expanded(
              child: TextButton(
                onPressed: isAnyLoading ? null : (onRetry ?? onClose),
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

          // Add a spacer between buttons if both retry and another button exist
          if ((actionsList.contains('retry') && actionsList.contains('submit')) ||
              (actionsList.contains('retry') && actionsList.contains('dashboard')))
            const SizedBox(width: 16),

          // Nút Xác nhận (submit)
          if (actionsList.contains('submit'))
            Expanded(
              child: _buildLoadingButton(
                context: context,
                isLoading: isApiLoading || isBluetoothLoading,
                loadingText: isApiLoading && isBluetoothLoading
                    ? 'Đang xử lý...'
                    : isApiLoading
                        ? 'Đang gửi API...'
                        : 'Đang kết nối...',
                normalText: 'Xác nhận',
                onPressed: hasApiError || hasBluetoothError ? null : onSubmit,
                backgroundColor: AppColors.primary,
                icon: Icons.check_circle,
              ),
            ),

          // Add a spacer between submit and dashboard if both exist
          if (actionsList.contains('submit') && actionsList.contains('dashboard'))
            const SizedBox(width: 16),

          // Nút Quay về (dashboard) - now in a separate if condition, not an else if
          if (actionsList.contains('dashboard'))
            Expanded(
              child: _buildLoadingButton(
                context: context,
                isLoading: false, // Dashboard button is never in loading state
                loadingText: '',
                normalText: 'Quay về',
                onPressed: onDashboard,
                backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                icon: Icons.home,
              ),
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

    details.forEach((key, value) {
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
