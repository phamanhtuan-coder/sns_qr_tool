import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class TokenExpiryWarning extends StatefulWidget {
  final Widget child;

  const TokenExpiryWarning({Key? key, required this.child}) : super(key: key);

  @override
  State<TokenExpiryWarning> createState() => _TokenExpiryWarningState();
}

class _TokenExpiryWarningState extends State<TokenExpiryWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showWarning = false;
  String? _warningMessage;
  bool _isAutoLoggingOut = false;
  final int _autoLogoutCountdown = 30; // seconds to auto-logout
  int _countdownValue = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isAutoLoggingOut = true;
      _countdownValue = _autoLogoutCountdown;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      // Stop if widget is disposed
      if (!mounted) return false;

      setState(() {
        _countdownValue--;
      });

      // When countdown reaches zero, logout
      if (_countdownValue <= 0) {
        _performLogout();
        return false;
      }

      return _countdownValue > 0;
    });
  }

  void _performLogout() {
    if (!mounted) return;

    // Reverse the animation first, then trigger logout
    _controller.reverse().then((_) {
      final navigatorKey = AppRouter.globalNavigatorKey;
      final authBloc = context.read<AuthBloc>();

      // Add logout event
      authBloc.add(const LogoutEvent());

      // Navigate to login screen with a fade transition
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          AppRouter.login,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.showTokenWarning != current.showTokenWarning ||
          previous.tokenWarningMessage != current.tokenWarningMessage,
      listener: (context, state) {
        if (state.showTokenWarning && !_showWarning) {
          setState(() {
            _showWarning = true;
            _warningMessage = state.tokenWarningMessage;
          });
          _controller.forward();

          // Show a snackbar with the warning
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.tokenWarningMessage ?? 'Phiên làm việc sắp hết hạn',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Đăng nhập lại',
                textColor: Colors.white,
                onPressed: () {
                  _performLogout();
                },
              ),
            ),
          );

          // Start countdown after showing warning for a while (1 minute)
          Future.delayed(const Duration(minutes: 1), () {
            if (mounted && _showWarning) {
              _startCountdown();
            }
          });
        } else if (!state.showTokenWarning && _showWarning) {
          setState(() {
            _showWarning = false;
            _isAutoLoggingOut = false;
          });
          _controller.reverse();
        }
      },
      child: Stack(
        children: [
          // Main content
          widget.child,

          // Warning overlay
          if (_showWarning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizeTransition(
                sizeFactor: _animation,
                axis: Axis.vertical,
                axisAlignment: -1.0,
                child: Material(
                  elevation: 4,
                  color: AppColors.warning.withOpacity(0.9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SafeArea(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cảnh báo phiên làm việc',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isAutoLoggingOut
                                    ? 'Tự động đăng xuất sau $_countdownValue giây...'
                                    : _warningMessage ?? 'Phiên làm việc sắp hết hạn',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _performLogout,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Đăng nhập lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
