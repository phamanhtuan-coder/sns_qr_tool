import 'package:flutter/material.dart';

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
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.7)),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 384),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isSuccess ? Colors.green.shade800 : Colors.red.shade800)),
                            const SizedBox(height: 8),
                            Text(message, style: TextStyle(fontSize: 14, color: isSuccess ? Colors.green.shade700 : Colors.red.shade700)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                if (details.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      children: details.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    Text(e.value, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: ElevatedButton(
                      onPressed: isSuccess && onContinue != null ? onContinue : onClose,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: isSuccess ? Colors.green : Colors.blue,
                      ),
                      child: Text(isSuccess && onContinue != null ? 'Continue Scanning' : 'Confirm'),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}