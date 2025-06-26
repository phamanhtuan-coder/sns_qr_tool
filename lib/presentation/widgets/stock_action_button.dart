import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class StockActionButtons extends StatefulWidget {
  final bool hasSelectedOrder;
  final bool isOrderComplete;
  final VoidCallback onScanQR;
  final VoidCallback? onComplete;

  const StockActionButtons({
    super.key,
    required this.hasSelectedOrder,
    required this.isOrderComplete,
    required this.onScanQR,
    this.onComplete,
  });

  @override
  State<StockActionButtons> createState() => _StockActionButtonsState();
}

class _StockActionButtonsState extends State<StockActionButtons> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scan QR Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.hasSelectedOrder ? widget.onScanQR : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                disabledForegroundColor: Colors.grey[600],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text(
                'Quét mã QR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Complete Order Button (shown when order is complete)
          if (widget.isOrderComplete && widget.onComplete != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text(
                  'Hoàn thành đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}