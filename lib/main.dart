import 'package:firmware_deployment_tool/presentation/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/auth/auth_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:firmware_deployment_tool/presentation/screens/main_app.dart';
import 'package:firmware_deployment_tool/utils/di.dart';
import 'package:firmware_deployment_tool/utils/theme.dart';

void main() {
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
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Firmware Deployment Tool',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            home: const MainApp(),
          );
        },
      ),
    );
  }
}