import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class EmergencyContactWidget extends StatelessWidget {
  const EmergencyContactWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Liên hệ khẩn cấp',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  'Cấp cứu',
                  '115',
                  Icons.local_hospital,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  'Cảnh sát',
                  '113',
                  Icons.local_police,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyButton(
                  context,
                  'Quản lý',
                  '0909123456',
                  Icons.support_agent,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context,
    String label,
    String phoneNumber,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _makeEmergencyCall(context, phoneNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              phoneNumber,
              style: TextStyle(
                fontSize: 9,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeEmergencyCall(BuildContext context, String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gọi số $phoneNumber'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class BreakManagementWidget extends StatefulWidget {
  final VoidCallback? onStartBreak;
  final VoidCallback? onEndBreak;
  final bool isOnBreak;

  const BreakManagementWidget({
    super.key,
    this.onStartBreak,
    this.onEndBreak,
    this.isOnBreak = false,
  });

  @override
  State<BreakManagementWidget> createState() => _BreakManagementWidgetState();
}

class _BreakManagementWidgetState extends State<BreakManagementWidget> {
  DateTime? _breakStartTime;

  @override
  void initState() {
    super.initState();
    if (widget.isOnBreak) {
      _breakStartTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isOnBreak
            ? AppColors.warning.withOpacity(0.05)
            : AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOnBreak
              ? AppColors.warning.withOpacity(0.2)
              : AppColors.success.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isOnBreak
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.isOnBreak ? Icons.pause_circle : Icons.work,
                  color: widget.isOnBreak ? AppColors.warning : AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isOnBreak ? 'Đang nghỉ ngơi' : 'Trạng thái làm việc',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isOnBreak ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isOnBreak && _breakStartTime != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Bắt đầu nghỉ: ${_formatTime(_breakStartTime!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isOnBreak ? _endBreak : _startBreak,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isOnBreak ? AppColors.success : AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(
                widget.isOnBreak ? Icons.play_arrow : Icons.pause,
                size: 20,
              ),
              label: Text(
                widget.isOnBreak ? 'Kết thúc nghỉ ngơi' : 'Bắt đầu nghỉ ngơi',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startBreak() {
    setState(() {
      _breakStartTime = DateTime.now();
    });
    widget.onStartBreak?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã bắt đầu nghỉ ngơi'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _endBreak() {
    if (_breakStartTime != null) {
      final breakDuration = DateTime.now().difference(_breakStartTime!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kết thúc nghỉ ngơi - Thời gian: ${_formatDuration(breakDuration)}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    setState(() {
      _breakStartTime = null;
    });
    widget.onEndBreak?.call();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
