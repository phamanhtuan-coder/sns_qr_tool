import 'package:flutter/material.dart';

class QROverlay extends StatefulWidget {
  final bool isScanning;
  final String purpose;
  final bool isProcessing; // Thêm parameter để hiển thị trạng thái processing

  const QROverlay({
    super.key,
    required this.isScanning,
    required this.purpose,
    this.isProcessing = false, // Default false
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

class _QROverlayState extends State<QROverlay> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _processingController; // Controller cho processing animation
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _processingRotation; // Animation xoay cho processing
  bool _isAnimationRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scanAnimation = Tween<double>(begin: 0, end: 256).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _processingRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _processingController, curve: Curves.linear),
    );

    if (widget.isScanning && !widget.isProcessing) {
      _startAnimation();
    }

    if (widget.isProcessing) {
      _startProcessingAnimation();
    }
  }

  void _startAnimation() {
    if (_isAnimationRunning) return;
    _isAnimationRunning = true;
    _controller.repeat(reverse: true);
  }

  void _startProcessingAnimation() {
    _processingController.repeat();
  }

  void _stopAnimations() {
    _controller.stop();
    _processingController.stop();
    _isAnimationRunning = false;
  }

  @override
  void didUpdateWidget(QROverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isProcessing && !oldWidget.isProcessing) {
      // Bắt đầu processing animation
      _stopAnimations();
      _startProcessingAnimation();
    } else if (widget.isScanning && !widget.isProcessing &&
               (!oldWidget.isScanning || oldWidget.isProcessing)) {
      // Bắt đầu scan animation
      _processingController.stop();
      _startAnimation();
    } else if (!widget.isScanning && !widget.isProcessing) {
      // Dừng tất cả animations
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _stopAnimations();
    _controller.dispose();
    _processingController.dispose();
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

        // Stage info at the top với animation cải thiện
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: widget.isProcessing
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isProcessing
                        ? Colors.green.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isProcessing
                          ? Colors.green.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.isProcessing
                            ? Colors.green.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.isProcessing
                                ? Colors.green.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: widget.isProcessing
                          ? AnimatedBuilder(
                              animation: _processingRotation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _processingRotation.value * 2 * 3.14159,
                                  child: const Icon(
                                    Icons.sync,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                );
                              },
                            )
                          : Text(
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
                      widget.isProcessing ? 'Đang xử lý...' : stageName,
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
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _processingController]),
            builder: (context, child) {
              return SizedBox(
                width: 256,
                height: 256,
                child: Stack(
                  children: [
                    // QR Frame base với màu sắc thay đổi theo trạng thái
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.isProcessing
                              ? Colors.green.withOpacity(0.6)
                              : Colors.white.withOpacity(0.4),
                          width: 2
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isProcessing
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Animated corners với màu sắc dynamic
                    ...List.generate(4, (index) {
                      final positions = [
                        {'top': 0.0, 'left': 0.0, 'borders': ['top', 'left']},
                        {'top': 0.0, 'right': 0.0, 'borders': ['top', 'right']},
                        {'bottom': 0.0, 'left': 0.0, 'borders': ['bottom', 'left']},
                        {'bottom': 0.0, 'right': 0.0, 'borders': ['bottom', 'right']},
                      ];

                      final pos = positions[index];
                      final color = widget.isProcessing ? Colors.green : Colors.blue;

                      return Positioned(
                        top: pos['top'] as double?,
                        left: pos['left'] as double?,
                        right: pos['right'] as double?,
                        bottom: pos['bottom'] as double?,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: widget.isProcessing ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border(
                                top: (pos['borders'] as List).contains('top')
                                    ? BorderSide(color: color, width: 4)
                                    : BorderSide.none,
                                left: (pos['borders'] as List).contains('left')
                                    ? BorderSide(color: color, width: 4)
                                    : BorderSide.none,
                                right: (pos['borders'] as List).contains('right')
                                    ? BorderSide(color: color, width: 4)
                                    : BorderSide.none,
                                bottom: (pos['borders'] as List).contains('bottom')
                                    ? BorderSide(color: color, width: 4)
                                    : BorderSide.none,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Scan line animation - chỉ hiển thị khi đang scan
                    if (widget.isScanning && !widget.isProcessing && _isAnimationRunning)
                      Positioned(
                        top: _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.0),
                                Colors.blue.withOpacity(0.8),
                                Colors.blue,
                                Colors.blue.withOpacity(0.8),
                                Colors.blue.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Processing overlay - hiển thị khi đang xử lý
                    if (widget.isProcessing)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _processingRotation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _processingRotation.value * 2 * 3.14159,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.sync,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}