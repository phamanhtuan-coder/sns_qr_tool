import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/dashboard.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/login_page.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_scanner_screen.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/utils/theme_provider.dart';

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String scanner = '/scanner';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildPageRoute(
          settings,
          Builder(
            builder: (context) => LoginPage(
              onLogin: ({required String username, required String password, required bool remember}) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  dashboard,
                  (route) => false,
                );
              },
            ),
          ),
          maintainState: false,
        );

      case dashboard:
        return _buildPageRoute(
          settings,
          BlocProvider(
            create: (context) => DashboardBloc(),
            child: WillPopScope(
              onWillPop: () async => false,
              child: BlocListener<DashboardBloc, DashboardState>(
                listener: (context, state) {
                  if (state.selectedFunction != null && state.selectedFunction!.isNotEmpty) {
                    Navigator.of(context).pushNamed(
                      scanner,
                      arguments: {
                        'purpose': state.selectedFunction,
                        'context': context,
                      },
                    );
                  }
                },
                child: Builder(
                  builder: (context) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('SmartNet QR Scanner'),
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: Icon(
                              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            ),
                            onPressed: () => themeProvider.toggleTheme(),
                            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                          ),
                        ],
                      ),
                      body: const Dashboard(user: User(
                        name: 'Người dùng',
                        role: 'Kỹ thuật viên',
                        department: 'Sản xuất'
                      )),
                    );
                  },
                ),
              ),
            ),
          ),
        );

      case scanner:
        final args = settings.arguments as Map<String, dynamic>;
        final purpose = args['purpose'] as String;
        final context = args['context'] as BuildContext;

        return _buildPageRoute(
          settings,
          QRScannerScreen(
            purpose: purpose,
            onBack: () {
              context.read<DashboardBloc>().add(const SelectFunction(''));
              Navigator.of(context).pop();
            },
          ),
          maintainState: false,
        );

      default:
        return _buildPageRoute(
          settings,
          const Scaffold(
            body: Center(child: Text('Route not found')),
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
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
