import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/splash_screen.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/custom_app_bar.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/dashboard.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/login_page.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_scanner_screen.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/token_expiry_warning.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String scanner = '/scanner';

  // Track route history
  static final List<String> _routeHistory = [splash];

  static String get currentRoute => _routeHistory.isNotEmpty ? _routeHistory.last : splash;
  static String? get previousRoute => _routeHistory.length > 1 ? _routeHistory[_routeHistory.length - 2] : null;

  static void addToHistory(String route) {
    // Don't add duplicate consecutive routes
    if (_routeHistory.isEmpty || _routeHistory.last != route) {
      _routeHistory.add(route);
      print('DEBUG: Route history updated: $_routeHistory');
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Update history when generating a new route
    if (settings.name != null) {
      addToHistory(settings.name!);
    }

    print('DEBUG: Navigating to ${settings.name}');

    switch (settings.name) {
      case splash:
        return _buildPageRoute(
          settings,
          BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: const SplashScreen(),
          ),
          maintainState: false,
        );

      case login:
        return _buildPageRoute(
          settings,
          MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: getIt<AuthBloc>(),
              ),
            ],
            child: LoginPage(
              onLogin: ({required String username, required String password}) {
                // This will handle navigation in the bloc
                getIt<AuthBloc>().add(LoginEvent(username, password, context: null));
              },
            ),
          ),
          maintainState: true, // Maintain state for back navigation
        );

      case dashboard:
        return _buildPageRoute(
          settings,
          WillPopScope(
            // Handle back button press on dashboard
            onWillPop: () async {
              print('DEBUG: Back button pressed on dashboard');
              // If user is logged in, don't allow direct back navigation to login
              // Instead show a dialog asking if they want to logout
              return false; // Prevent default back navigation
            },
            child: BlocProvider.value(
              value: getIt<DashboardBloc>(),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  print('DEBUG: Building Dashboard route with auth state: ${state.isAuthenticated}');
                  return TokenExpiryWarning(
                    child: BlocListener<DashboardBloc, DashboardState>(
                      listener: (context, dashState) {
                        if (dashState.selectedFunction != null && dashState.selectedFunction!.isNotEmpty) {
                          Navigator.of(context).pushNamed(
                            scanner,
                            arguments: {
                              'purpose': dashState.selectedFunction,
                              'context': context,
                            },
                          );
                        }
                      },
                      child: Scaffold(
                        appBar: CustomAppBar(
                          title: 'SmartNet QR Scanner',
                          showThemeSwitch: true,
                          automaticallyImplyLeading: false, // No back button on dashboard
                          actions: [
                            // Add logout button
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white),
                              onPressed: () => _showLogoutDialog(context),
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                        body: Dashboard(
                          user: state.user ?? const User(
                            name: 'Người dùng',
                            role: 'Kỹ thuật viên',
                            department: 'Sản xuất',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          maintainState: true,
        );

      case scanner:
        final args = settings.arguments as Map<String, dynamic>;
        final purpose = args['purpose'] as String;
        final context = args['context'] as BuildContext;

        return _buildPageRoute(
          settings,
          TokenExpiryWarning(
            child: Scaffold(
              appBar: CustomAppBar(
                title: _getPurposeTitle(purpose), // Use a helper method to get proper title
                showThemeSwitch: false,
                automaticallyImplyLeading: true, // Show back button
                onBackPressed: () {
                  context.read<DashboardBloc>().add(const SelectFunction(''));
                  Navigator.of(context).pop(); // Use pop to go back to previous screen
                },
              ),
              body: QRScannerScreen(
                purpose: purpose,
                onBack: () {
                  context.read<DashboardBloc>().add(const SelectFunction(''));
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          maintainState: true,
        );

      default:
        return _buildPageRoute(
          settings,
          Scaffold(
            appBar: CustomAppBar(
              title: 'Không tìm thấy trang',
              showThemeSwitch: true,
              automaticallyImplyLeading: true, // Show back button to navigate back
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không tìm thấy trang yêu cầu'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to dashboard if logged in, otherwise to login
                      final authBloc = getIt<AuthBloc>();
                      final isAuthenticated = authBloc.state.isAuthenticated;

                      Navigator.of(globalNavigatorKey.currentContext!).pushNamedAndRemoveUntil(
                        isAuthenticated ? dashboard : login,
                        (route) => false,
                      );
                    },
                    child: const Text('Quay về trang chính'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  // Show logout confirmation dialog
  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              // Logout and navigate to login screen
              context.read<AuthBloc>().add(const LogoutEvent());

              // Navigate to login screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                login,
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  static PageRouteBuilder<dynamic> _buildPageRoute(
    RouteSettings settings,
    Widget page, {
    bool maintainState = true,
  }) {
    return PageRouteBuilder(
      settings: settings,
      maintainState: maintainState,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (settings.name == login && previousRoute == splash) {
          // No animation for login page from splash
          return child;
        }

        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: settings.name == login
          ? Duration.zero
          : const Duration(milliseconds: 300),
    );
  }

  static final GlobalKey<NavigatorState> _globalNavigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get globalNavigatorKey => _globalNavigatorKey;

  // Helper method to get the title based on the purpose
  static String _getPurposeTitle(String purpose) {
    switch (purpose) {
      case 'scan':
        return 'Quét mã QR';
      case 'generate':
        return 'Tạo mã QR';
      default:
        return 'QR Scanner';
    }
  }
}
