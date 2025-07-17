import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/services/export_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/stock_service.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/splash_screen.dart';
import 'package:smart_net_qr_scanner/presentation/screens/stock_in_screen.dart';
import 'package:smart_net_qr_scanner/presentation/screens/stock_out_screen.dart';
import 'package:smart_net_qr_scanner/presentation/screens/shipper_screen.dart';
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
  static const String stockIn = '/stock-in';
  static const String stockOut = '/stock-out';
  static const String shipper = '/shipper';

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
                        appBar: const CustomAppBar(
                          title: 'SmartNet QR Scanner',
                          showThemeSwitch: true,
                          automaticallyImplyLeading: false, // No back button on dashboard
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

      case stockIn:
        return _buildPageRoute(
          settings,
          BlocProvider(
            create: (context) => StockBloc(
              getIt<ImportWarehouseService>(),
              getIt<ExportWarehouseService>(),
            ),
            child: const StockInScreen(),
          ),
          maintainState: true,
        );

      case stockOut:
        return _buildPageRoute(
          settings,
          BlocProvider(
            create: (context) => StockBloc(
              getIt<ImportWarehouseService>(),
              getIt<ExportWarehouseService>(),
            ),
            child: const StockOutScreen(),
          ),
          maintainState: true,
        );

      case shipper:
        print('DEBUG: AppRouter - Creating shipper route');
        try {
          final deliveryService = getIt<DeliveryService>();
          print('DEBUG: AppRouter - DeliveryService obtained: $deliveryService');

          return _buildPageRoute(
            settings,
            BlocProvider(
              create: (context) {
                print('DEBUG: AppRouter - Creating DeliveryBloc with service: $deliveryService');
                final bloc = DeliveryBloc(deliveryService);
                print('DEBUG: AppRouter - DeliveryBloc created: $bloc');
                return bloc;
              },
              child: const ShipperScreen(),
            ),
            maintainState: true,
          );
        } catch (e, stackTrace) {
          print('DEBUG: AppRouter - Error creating shipper route: $e');
          print('DEBUG: AppRouter - Stack trace: $stackTrace');
          rethrow;
        }

      default:
        return _buildPageRoute(
          settings,
          Scaffold(
            appBar: const CustomAppBar(
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

  static PageRoute<dynamic> _buildPageRoute(
    RouteSettings settings,
    Widget page, {
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) => page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static final GlobalKey<NavigatorState> _globalNavigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get globalNavigatorKey => _globalNavigatorKey;

  // Helper method to get the title based on the purpose
  static String _getPurposeTitle(String purpose) {
    switch (purpose) {
      case 'identify':
        return 'Xác định thiết bị';
      case 'firmware':
        return 'Cập nhật Firmware';
      case 'testing':
        return 'Kiểm tra thiết bị';
      case 'packaging':
        return 'Đóng gói thiết bị';
      case 'stockin':
        return 'Nhập kho';
      case 'stockout':
        return 'Xuất kho';
      case 'delivery_scan':
        return 'Quét đơn giao hàng';
      case 'scan_import_id':
        return 'Quét mã đơn nhập';
      default:
        return 'Quét QR Code';
    }
  }
}
