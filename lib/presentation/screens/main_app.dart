import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/splash_screen.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/dashboard.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_scanner_screen.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/login_page.dart';
import 'package:smart_net_qr_scanner/utils/theme.dart';
import 'package:smart_net_qr_scanner/utils/theme_provider.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showingSplash = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Create a dummy user
  static const dummyUser = User(
    name: 'Người dùng',
    role: 'Kỹ thuật viên',
    department: 'Sản xuất'
  );

  @override
  void initState() {
    super.initState();
    // Hide splash after a delay
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showingSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showingSplash) {
      return const SplashScreen();
    }
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => BlocProvider(
          create: (context) => DashboardBloc(),
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (context) => LoginPage(
                onLogin: ({required String username, required String password, required bool remember}) {
                  // Change from pushReplacementNamed to pushNamed to keep login in the stack
                  _navigatorKey.currentState?.pushNamed('/dashboard');
                },
              ),
              '/dashboard': (context) => BlocListener<DashboardBloc, DashboardState>(
                listener: (context, state) {
                  if (state.selectedFunction != null && state.selectedFunction!.isNotEmpty) {
                    _navigatorKey.currentState?.pushNamed(
                      '/scanner',
                      arguments: state.selectedFunction,
                    );
                  }
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('SmartNet QR Scanner'),
                    actions: [
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                        tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      ),
                    ],
                  ),
                  body: const Dashboard(user: dummyUser),
                ),
              ),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/scanner') {
                final purpose = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => QRScannerScreen(
                    purpose: purpose,
                    onBack: () {
                      // Just reset the function selection
                      context.read<DashboardBloc>().add(const SelectFunction(""));
                      // Navigation will be handled by the Navigator's pop
                    },
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}

