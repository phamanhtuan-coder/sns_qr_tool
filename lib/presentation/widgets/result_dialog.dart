import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == 'success';
    final formattedDetails = _formatDetails();

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withAlpha(179)), // 0.7 * 255 ≈ 179
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isSuccess),
                  if (formattedDetails.isNotEmpty)
                    _buildDetailsSection(context, formattedDetails),
                  _buildActions(context, isSuccess, actions),
                ],
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

  Widget _buildActions(BuildContext context, bool isSuccess, List<String> actionsList) {
    print("DEBUG: Building actions with: $actionsList");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đảm bảo các nút cách đều
        children: [
          // Nút Quét lại (retry)
          if (actionsList.contains('retry'))
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : onRetry ?? onClose,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text('Quét lại'),
                  ],
                ),
              ),
            ),
          if (actionsList.contains('retry') && actionsList.contains('submit'))
            const SizedBox(width: 16),

          // Nút Xác nhận (submit)
          if (actionsList.contains('submit'))
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.blue.withOpacity(0.6),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Xác nhận'),
                        ],
                      ),
              ),
            )

          // Nút Quay về (dashboard)
          else if (actionsList.contains('dashboard'))
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 20),
                    SizedBox(width: 8),
                    Text('Quay về'),
                  ],
                ),
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
