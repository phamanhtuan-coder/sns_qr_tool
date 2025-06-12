import 'package:flutter/material.dart';

class QROverlay extends StatefulWidget {
  final bool isScanning;
  final String purpose; // Add purpose parameter

  const QROverlay({
    super.key,
    required this.isScanning,
    required this.purpose, // Add required purpose
  });

  // Helper method to get stage info
  static Map<String, dynamic> getPurposeInfo(String purpose) {
    final stages = {
      'identify': {'number': 1, 'name': 'Xác định thiết bị'},
      'firmware': {'number': 2, 'name': 'Cập nhật Firmware'},
      'testing': {'number': 3, 'name': 'Kiểm tra thiết bị'},
      'packaging': {'number': 4, 'name': 'Đóng gói thiết bị'},
      'stockin': {'number': 5, 'name': 'Nhập kho'},
      'stockout': {'number': 6, 'name': 'Xuất kho'},
    };
    return stages[purpose] ?? {'number': 0, 'name': 'Không xác định'};
  }

  @override
  _QROverlayState createState() => _QROverlayState();
}

class _QROverlayState extends State<QROverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimationRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 256).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    if (widget.isScanning) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_isAnimationRunning) return;
    _isAnimationRunning = true;
    _controller.repeat();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isAnimationRunning) {
        _controller.stop();
        _isAnimationRunning = false;
      }
    });
  }

  @override
  void didUpdateWidget(QROverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _startAnimation();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _controller.stop();
      _isAnimationRunning = false;
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _isAnimationRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purposeInfo = QROverlay.getPurposeInfo(widget.purpose);
    final stageNumber = purposeInfo['number'];
    final stageName = purposeInfo['name'];

    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.7)),
        // Add stage info at the top
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$stageNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stageName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.blue, width: 4), left: BorderSide(color: Colors.blue, width: 4)))),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.blue, width: 4), right: BorderSide(color: Colors.blue, width: 4)))),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.blue, width: 4), left: BorderSide(color: Colors.blue, width: 4)))),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.blue, width: 4), right: BorderSide(color: Colors.blue, width: 4)))),
                ),
                if (widget.isScanning && _isAnimationRunning)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(height: 2, color: Colors.blue),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}