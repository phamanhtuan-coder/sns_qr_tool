import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/theme/theme_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/main_app.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
import 'package:smart_net_qr_scanner/utils/theme.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client with correct base URL before setting up dependencies
  await ApiClient.initializeBaseUrl();

  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<DashboardBloc>()),
        BlocProvider(create: (_) => getIt<ThemeBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'SmartNet QR Scanner',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: state.themeMode,
            home: const MainApp(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

