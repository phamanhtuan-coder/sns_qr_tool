import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/splash_screen.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/dashboard.dart';
import 'package:smart_net_qr_scanner/presentation/widgets/qr_scanner_screen.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showingSplash = true;

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

    // After splash is done, go directly to dashboard (skip authentication)
    // Create a dummy user since we don't have authentication
    const dummyUser = User(
      name: 'Người dùng',
      role: 'Kỹ thuật viên',
      department: 'Sản xuất'
    );

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashboardState) {
        if (dashboardState.selectedFunction != null && dashboardState.selectedFunction!.isNotEmpty) {
          return QRScannerScreen(
            purpose: dashboardState.selectedFunction!,
            onBack: () => context.read<DashboardBloc>().add(const SelectFunction("")),
          );
        }
        return Dashboard(user: dummyUser);
      },
    );
  }
}

