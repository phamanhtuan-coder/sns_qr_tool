import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service_extension.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class ShippingActionButton extends StatefulWidget {
  final DeliveryOrder order;
  final VoidCallback? onOrderUpdated;

  const ShippingActionButton({
    Key? key,
    required this.order,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  State<ShippingActionButton> createState() => _ShippingActionButtonState();
}

class _ShippingActionButtonState extends State<ShippingActionButton> {
  final DeliveryService _deliveryService = getIt<DeliveryService>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.order.status) {
      case DeliveryStatus.assigned:
        return _buildStartDeliveryButton();
      case DeliveryStatus.started:
        return _buildCompleteDeliveryButton();
      case DeliveryStatus.delivered:
        return _buildDeliveredStatus();
      case DeliveryStatus.cancelled:
        return _buildCancelledStatus();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStartDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startDelivery,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.local_shipping),
        label: Text(_isLoading ? 'Đang xử lý...' : 'Bắt đầu giao'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCompleteDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _showCompleteDeliveryDialog,
        icon: const Icon(Icons.check_circle),
        label: const Text('Hoàn thành đơn'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDeliveredStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text(
            'Đã giao thành công',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text(
            'Đã hủy',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDelivery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _deliveryService.startShippingOrder(widget.order.id);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đã bắt đầu giao hàng thành công'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onOrderUpdated?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Không thể bắt đầu giao hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCompleteDeliveryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompleteDeliveryDialog(
        order: widget.order,
        deliveryService: _deliveryService,
      ),
    );

    if (result == true) {
      widget.onOrderUpdated?.call();
    }
  }
}

class CompleteDeliveryDialog extends StatefulWidget {
  final DeliveryOrder order;
  final DeliveryService deliveryService;

  const CompleteDeliveryDialog({
    Key? key,
    required this.order,
    required this.deliveryService,
  }) : super(key: key);

  @override
  State<CompleteDeliveryDialog> createState() => _CompleteDeliveryDialogState();
}

class _CompleteDeliveryDialogState extends State<CompleteDeliveryDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hoàn thành giao hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: ${widget.order.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Khách hàng: ${widget.order.customerName}'),
            const SizedBox(height: 16),

            const Text(
              'Ảnh bằng chứng giao hàng:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_selectedImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Thay đổi ảnh'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: InkWell(
                  onTap: _selectImage,
                  borderRadius: BorderRadius.circular(8),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chụp/Chọn ảnh bằng chứng',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Ghi chú (tùy chọn):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập ghi chú về việc giao hàng...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedImage == null ? null : _completeDelivery,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hoàn thành'),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final XFile? image = await _imagePicker.pickImage(
          source: result,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi chọn ảnh: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeDelivery() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh bằng chứng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await widget.deliveryService.confirmShippingOrder(
        orderId: widget.order.id,
        imageProofBase64: base64Image,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Hoàn thành giao hàng thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Không thể hoàn thành giao hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
