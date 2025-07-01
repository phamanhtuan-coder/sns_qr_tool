import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class DeliveryCompletionDialog extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryCompletionDialog({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryCompletionDialog> createState() => _DeliveryCompletionDialogState();
}

class _DeliveryCompletionDialogState extends State<DeliveryCompletionDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  String? photoPath;
  String note = '';
  bool isSuccessful = true;

  Future<String?> _capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return photo?.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chụp ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return photo?.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  void _onComplete() {
    Navigator.of(context).pop();
    context.read<DeliveryBloc>().add(CompleteDeliveryOrder(
      orderId: widget.order.id,
      photoPath: photoPath!,
      note: note,
      isSuccessful: isSuccessful,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSuccessful
            ? 'Đã xác nhận giao hàng thành công!'
            : 'Đã ghi nhận giao hàng thất bại!'),
        backgroundColor: isSuccessful ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.camera_alt,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Xác nhận giao hàng',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.text,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: ${widget.order.id}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.text,
              ),
            ),
            const SizedBox(height: 16),

            // Photo capture section
            _buildPhotoCaptureSection(isDark),
            const SizedBox(height: 16),

            // Delivery status selection
            _buildStatusSelection(isDark),
            const SizedBox(height: 16),

            // Note input
            _buildNoteInput(isDark),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: photoPath != null ? _onComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSuccessful ? AppColors.success : AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: Text(isSuccessful ? 'Xác nhận giao' : 'Ghi nhận thất bại'),
        ),
      ],
    );
  }

  Widget _buildPhotoCaptureSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          if (photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photoPath!),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await _capturePhoto();
                    if (result != null) {
                      setState(() {
                        photoPath = result;
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Chụp lại'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      photoPath = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa ảnh'),
                ),
              ],
            ),
          ] else ...[
            Icon(
              Icons.camera_alt,
              size: 48,
              color: isDark ? AppColors.darkIconLight : AppColors.iconLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Chụp ảnh xác nhận giao hàng',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ảnh này sẽ được gửi cho khách hàng làm bằng chứng giao hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _capturePhoto();
                    if (result != null) {
                      setState(() {
                        photoPath = result;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Chụp ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await _pickImageFromGallery();
                    if (result != null) {
                      setState(() {
                        photoPath = result;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                    side: BorderSide(
                      color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                    ),
                  ),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Thư viện'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSelection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái giao hàng:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(
                    'Thành công',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                    ),
                  ),
                  value: true,
                  groupValue: isSuccessful,
                  onChanged: (value) {
                    setState(() {
                      isSuccessful = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.success,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(
                    'Thất bại',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                    ),
                  ),
                  value: false,
                  groupValue: isSuccessful,
                  onChanged: (value) {
                    setState(() {
                      isSuccessful = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Ghi chú (không bắt buộc)',
        hintText: 'Nhập ghi chú về việc giao hàng...',
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextLight : AppColors.textLight,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.text,
      ),
      maxLines: 3,
      onChanged: (value) {
        note = value;
      },
    );
  }
}
