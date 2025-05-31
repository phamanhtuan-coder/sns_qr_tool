import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultDialog extends StatelessWidget {
  final String type;
  final String title;
  final String message;
  final Map<String, String> details;
  final VoidCallback onClose;
  final VoidCallback? onContinue;

  const ResultDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.details,
    required this.onClose,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == 'success';
    final formattedDetails = _formatDetails();

    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.7)),
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
                  _buildActions(context, isSuccess),
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
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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

  Widget _buildActions(BuildContext context, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (!isSuccess || onContinue != null)
            Expanded(
              child: TextButton(
                onPressed: onClose,
                child: Text(isSuccess ? 'Đóng' : 'Thử lại'),
              ),
            ),
          if (!isSuccess || onContinue != null)
            const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isSuccess && onContinue != null ? onContinue : onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(isSuccess && onContinue != null ? 'Quét tiếp' : 'Xác nhận'),
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

    details.forEach((key, value) {
      // Skip internal error codes and technical details in success case
      if (type == 'success' && (key == 'errorCode' || key == 'reason')) {
        return;
      }

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
      if (key == 'timestamp') {
        try {
          final date = DateTime.parse(value);
          displayValue = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
        } catch (_) {}
      } else if (key == 'rawData' && value.length > 50) {
        displayValue = '${value.substring(0, 50)}...';
      }

      formattedDetails.add(MapEntry(displayKey, displayValue));
    });

    return formattedDetails;
  }
}

