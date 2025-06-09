import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  bool _hasCheckedAuth = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: Initializing SplashScreen');

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Reduced duration
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation immediately
    _controller.forward();

    // Check auth status after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_hasCheckedAuth && mounted) {
        print('DEBUG: Initiating auth check from SplashScreen');
        context.read<AuthBloc>().add(const CheckLoginStatus());
        _hasCheckedAuth = true;
      }
    });
  }

  @override
  void dispose() {
    print('DEBUG: Disposing SplashScreen');
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNextScreen(bool isAuthenticated) {
    if (_isNavigating) return; // Prevent multiple navigations

    _isNavigating = true;
    print('DEBUG: Navigating from splash to ${isAuthenticated ? 'dashboard' : 'login'}');

    // Add a small delay to ensure animations are completed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final route = isAuthenticated ? AppRouter.dashboard : AppRouter.login;
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('DEBUG: SplashScreen auth state changed: ${state.isAuthenticated}');
        // Navigate based on authentication state
        _navigateToNextScreen(state.isAuthenticated);
      },
      child: Scaffold( // Wrap with Scaffold for better layout
        body: Container(
          color: AppColors.primary,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/app_icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SmartNet QR Scanner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quản lý sản xuất thông minh',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
