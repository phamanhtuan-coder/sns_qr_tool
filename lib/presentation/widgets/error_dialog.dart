import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';

class ErrorDialog extends StatefulWidget {
  final Device device;
  final VoidCallback onClose;
  final Function(String, String?) onConfirm;

  const ErrorDialog({
    super.key,
    required this.device,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  _ErrorDialogState createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<ErrorDialog> {
  final _reasonController = TextEditingController();
  String? _imageUrl;
  bool _confirmDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 384),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Báo cáo lỗi thiết bị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Serial Number:', style: TextStyle(fontSize: 14)),
                          Text(widget.device.serial, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Lý do lỗi *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Note: File picker not implemented; requires file_picker package
                      const Text('Ảnh minh chứng (tùy chọn)', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {}, // Implement file picker
                        child: const Text('Choose File'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: widget.onClose,
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: _reasonController.text.trim().isEmpty
                                ? null
                                : () => setState(() => _confirmDialogOpen = true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Báo lỗi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_confirmDialogOpen)
          AlertDialog(
            title: const Text('Xác nhận báo lỗi'),
            content: const Text('Bạn có chắc chắn muốn báo lỗi thiết bị này không?'),
            actions: [
              TextButton(
                onPressed: () => setState(() => _confirmDialogOpen = false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_reasonController.text, _imageUrl);
                  setState(() => _confirmDialogOpen = false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
      ],
    );
  }
}