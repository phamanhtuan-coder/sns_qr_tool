import 'package:firmware_deployment_tool/presentation/widgets/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/auth/auth_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:firmware_deployment_tool/presentation/widgets/mobile_login_page.dart';
import 'package:firmware_deployment_tool/presentation/widgets/dashboard.dart';
import 'package:firmware_deployment_tool/presentation/widgets/qr_scanner_screen.dart';
import 'package:firmware_deployment_tool/data/models/user.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (!state.isAuthenticated) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return LoginPage(
                  onLogin: ({required String username, required String password, required bool remember}) {
                    context.read<AuthBloc>().add(LoginEvent(username, password, remember));
                  },
                );
              } else {
                return MobileLoginPage(
                  onLogin: ({required String username, required String password, required bool remember}) {
                    context.read<AuthBloc>().add(LoginEvent(username, password, remember));
                  },
                );
              }
            },
          );
        }
        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, dashboardState) {
            if (dashboardState.selectedFunction != null && dashboardState.selectedFunction!.isNotEmpty) {
              return QRScannerScreen(
                purpose: dashboardState.selectedFunction!,
                onBack: () => context.read<DashboardBloc>().add(const SelectFunction("")),
              );
            }
            return Dashboard(user: state.user ?? const User(name: 'Unknown', role: 'Technician', department: 'Manufacturing'));
          },
        );
      },
    );
  }
}