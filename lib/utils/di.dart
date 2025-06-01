import 'package:get_it/get_it.dart';
import 'package:firmware_deployment_tool/data/services/auth_service.dart';
import 'package:firmware_deployment_tool/data/services/device_service.dart';
import 'package:firmware_deployment_tool/data/services/scanner_service.dart';
import 'package:firmware_deployment_tool/data/services/production_service.dart';
import 'package:firmware_deployment_tool/data/services/camera_service.dart';
import 'package:firmware_deployment_tool/data/services/bluetooth_client_service.dart';
import 'package:firmware_deployment_tool/presentation/blocs/auth/auth_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:firmware_deployment_tool/presentation/blocs/theme/theme_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register services first
  getIt.registerSingleton<ProductionService>(ProductionService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<DeviceService>(DeviceService());
  getIt.registerSingleton<ScannerService>(ScannerService());
  getIt.registerSingleton<CameraService>(CameraService());
  getIt.registerSingleton<BluetoothClientService>(BluetoothClientService());

  // Then register blocs that depend on services
  getIt.registerSingleton<AuthBloc>(AuthBloc());
  getIt.registerSingleton<DashboardBloc>(DashboardBloc());
  getIt.registerSingleton<ScannerBloc>(ScannerBloc());
  getIt.registerSingleton<ThemeBloc>(ThemeBloc());
}
