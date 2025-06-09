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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
                getIt<AuthBloc>().add(LoginEvent(username, password));
              },
            ),
          ),
          maintainState: false,
        );

      case dashboard:
        return _buildPageRoute(
          settings,
          BlocProvider.value(
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
                title: 'Quét mã QR',
                showThemeSwitch: false,
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<DashboardBloc>().add(const SelectFunction(''));
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
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
          maintainState: false,
        );

      default:
        return _buildPageRoute(
          settings,
          const Scaffold(
            appBar: CustomAppBar(
              title: 'Không tìm thấy trang',
              showThemeSwitch: true,
            ),
            body: Center(
              child: Text('Không tìm thấy trang yêu cầu'),
            ),
          ),
        );
    }
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
        if (settings.name == login) {
          // No animation for login page
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
}
