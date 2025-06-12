import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class ErrorDialog extends StatefulWidget {
  final Device device;
  final VoidCallback onClose;
  final Function(String, String?) onConfirm;
  final bool isLoading; // Add loading state

  const ErrorDialog({
    super.key,
    required this.device,
    required this.onClose,
    required this.onConfirm,
    this.isLoading = false, // Add default value
  });

  @override
  _ErrorDialogState createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<ErrorDialog> {
  final _reasonController = TextEditingController();
  String? _imageUrl;
  bool _confirmDialogOpen = false;

  Widget _buildActions() {
    final theme = Theme.of(context);
    final isTextEmpty = _reasonController.text.trim().isEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onClose,
          style: TextButton.styleFrom(
            foregroundColor: theme.brightness == Brightness.light
                ? Colors.grey[700]
                : Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: isTextEmpty || widget.isLoading
              ? null
              : () => setState(() => _confirmDialogOpen = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.brightness == Brightness.light
                ? AppColors.error.withOpacity(0.5)
                : AppColors.error.withOpacity(0.3),
            disabledForegroundColor: theme.brightness == Brightness.light
                ? Colors.white70
                : Colors.white54,
            elevation: 2,
            shadowColor: AppColors.shadowColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: widget.isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.brightness == Brightness.light
                          ? Colors.white70
                          : Colors.white54,
                    ),
                  ),
                )
              : const Icon(Icons.report_problem, size: 18),
          label: Text(widget.isLoading ? 'Đang xử lý...' : 'Báo lỗi'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTextEmpty = _reasonController.text.trim().isEmpty;

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? Colors.red.shade50
                        : Colors.red.shade900.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.brightness == Brightness.light
                                  ? Colors.red.shade700
                                  : Colors.red.shade300,
                              size: 24),
                          const SizedBox(width: 12),
                          const Text('Báo cáo lỗi thiết bị',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        ],
                      ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Serial Number:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(widget.device.serial,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Lý do lỗi *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.error, width: 2),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Note: File picker not implemented; requires file_picker package
                      const Text('Ảnh minh chứng (tùy chọn)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {}, // Implement file picker
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.brightness == Brightness.light
                              ? AppColors.primary
                              : AppColors.accent,
                          backgroundColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Tải ảnh lên'),
                      ),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_confirmDialogOpen)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                      color: theme.brightness == Brightness.light
                          ? AppColors.error
                          : AppColors.error.withOpacity(0.8),
                      size: 24),
                    const SizedBox(width: 12),
                    const Text('Xác nhận báo lỗi'),
                  ],
                ),
                content: const Text('Bạn có chắc chắn muốn báo lỗi thiết bị này không?'),
                actions: [
                  TextButton(
                    onPressed: widget.isLoading ? null : () => setState(() => _confirmDialogOpen = false),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.light
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: widget.isLoading ? null : () {
                      widget.onConfirm(_reasonController.text, _imageUrl);
                      // Don't close dialog immediately, let parent handle it based on API response
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.brightness == Brightness.light
                          ? AppColors.error.withOpacity(0.5)
                          : AppColors.error.withOpacity(0.3),
                      disabledForegroundColor: theme.brightness == Brightness.light
                          ? Colors.white70
                          : Colors.white54,
                      elevation: 2,
                      shadowColor: AppColors.shadowColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.brightness == Brightness.light
                                    ? Colors.white70
                                    : Colors.white54,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.check_circle, size: 16),
                        const SizedBox(width: 8),
                        Text(widget.isLoading ? 'Đang xử lý...' : 'Xác nhận'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}