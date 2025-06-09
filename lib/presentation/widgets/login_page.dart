import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

import '../../utils/theme_provider.dart';

class LoginPage extends StatefulWidget {
  final Function({
    required String username,
    required String password,
  }) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Listen for auth state changes
    context.read<AuthBloc>().stream.listen((state) {
      setState(() {
        _error = state.error;
        _isLoading = state.isLoading;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // Pass the context to the login event for navigation
      context.read<AuthBloc>().add(LoginEvent(
        _usernameController.text,
        _passwordController.text,
        context: context
      ));
    }
  }

  Color _withOpacity(Color color, double opacity) {
    return Color.fromARGB(
      (opacity * 255).round(),
      (color.r * 255.0).round() & 0xff,
      (color.g * 255.0).round() & 0xff,
      (color.b * 255.0).round() & 0xff,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Disable back button
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: isDarkMode ? Colors.white70 : Colors.white,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDarkMode ? AppColors.darkHeaderBackground : AppColors.primary,
                isDarkMode
                  ? _withOpacity(AppColors.darkBackground, 0.8)
                  : _withOpacity(AppColors.accent, 0.8),
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo
                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _withOpacity(Colors.black, 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/app_icon.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Form Card
                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 0.4),
                            child: Card(
                              elevation: 8,
                              color: isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Error message
                                      if (_error != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                ? _withOpacity(Colors.red, 0.1)
                                                : _withOpacity(Colors.red, 0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _withOpacity(Colors.red, 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red[300],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _error!,
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                        ? Colors.red[300]
                                                        : Colors.red[700],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Text(
                                        'ĐĂNG NHẬP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: primaryColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Username Field
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: InputDecoration(
                                          labelText: 'Tên đăng nhập',
                                          hintText: 'Nhập tên đăng nhập',
                                          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: isDarkMode ? AppColors.darkSurface : _withOpacity(Colors.white, 0.9),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập tên đăng nhập';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      // Password Field
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_showPassword,
                                        decoration: InputDecoration(
                                          labelText: 'Mật khẩu',
                                          hintText: 'Nhập mật khẩu',
                                          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _showPassword ? Icons.visibility_off : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showPassword = !_showPassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: isDarkMode ? AppColors.darkSurface : _withOpacity(Colors.white, 0.9),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập mật khẩu';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 40),
                                      // Login Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'ĐĂNG NHẬP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 0.2),
                            child: Text(
                              'Phiên bản 1.0.0',
                              style: TextStyle(
                                color: _withOpacity(Colors.white, 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
