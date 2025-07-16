import 'package:get_it/get_it.dart';
import 'package:smart_net_qr_scanner/data/services/auth_service.dart';
import 'package:smart_net_qr_scanner/data/services/scanner_service.dart';
import 'package:smart_net_qr_scanner/data/services/production_service.dart';
import 'package:smart_net_qr_scanner/data/services/camera_service.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/data/services/stock_service.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/export_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/local_export_storage.dart';
import 'package:smart_net_qr_scanner/data/services/delivery_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/scanner/scanner_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/theme/theme_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/delivery/delivery_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  print('DEBUG: Starting dependency setup');

  // Register API client first since other services depend on it
  try {
    if (!getIt.isRegistered<ApiClient>()) {
      print('DEBUG: Registering ApiClient');
      getIt.registerSingleton<ApiClient>(ApiClient());
    }

    // Register services
    print('DEBUG: Registering services');
    if (!getIt.isRegistered<AuthService>()) {
      getIt.registerSingleton<AuthService>(AuthService());
    }
    if (!getIt.isRegistered<ProductionService>()) {
      getIt.registerSingleton<ProductionService>(ProductionService());
    }
    if (!getIt.isRegistered<ScannerService>()) {
      getIt.registerSingleton<ScannerService>(ScannerService());
    }
    if (!getIt.isRegistered<CameraService>()) {
      getIt.registerSingleton<CameraService>(CameraService());
    }
    if (!getIt.isRegistered<StockService>()) {
      getIt.registerSingleton<StockService>(StockService());
    }
    if (!getIt.isRegistered<ImportWarehouseService>()) {
      getIt.registerSingleton<ImportWarehouseService>(ImportWarehouseService());
    }
    if (!getIt.isRegistered<ExportWarehouseService>()) {
      getIt.registerSingleton<ExportWarehouseService>(ExportWarehouseService());
    }
    if (!getIt.isRegistered<LocalExportStorage>()) {
      getIt.registerSingleton<LocalExportStorage>(LocalExportStorage());
    }
    if (!getIt.isRegistered<DeliveryService>()) {
      getIt.registerSingleton<DeliveryService>(DeliveryService());
    }

    // Then register blocs that depend on services
    print('DEBUG: Registering blocs');
    if (!getIt.isRegistered<AuthBloc>()) {
      getIt.registerSingleton<AuthBloc>(AuthBloc());
    }
    if (!getIt.isRegistered<DashboardBloc>()) {
      getIt.registerSingleton<DashboardBloc>(DashboardBloc());
    }
    if (!getIt.isRegistered<ScannerBloc>()) {
      getIt.registerSingleton<ScannerBloc>(ScannerBloc());
    }
    if (!getIt.isRegistered<ThemeBloc>()) {
      getIt.registerSingleton<ThemeBloc>(ThemeBloc());
    }
    if (!getIt.isRegistered<StockBloc>()) {
      getIt.registerSingleton<StockBloc>(
        StockBloc(
          getIt<ImportWarehouseService>(),
          getIt<ExportWarehouseService>(),
        ),
      );
    }
    if (!getIt.isRegistered<DeliveryBloc>()) {
      getIt.registerSingleton<DeliveryBloc>(
        DeliveryBloc(getIt<DeliveryService>()),
      );
    }

    print('DEBUG: All dependencies registered successfully');
  } catch (e, stackTrace) {
    print('DEBUG: Error registering dependencies: $e');
    print('DEBUG: Stack trace: $stackTrace');
    rethrow;
  }
}
