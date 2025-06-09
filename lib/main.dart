import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/utils/theme_provider.dart';
import 'package:smart_net_qr_scanner/utils/theme.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    print('DEBUG: ${bloc.runtimeType} Event: $event');
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    print('DEBUG: ${bloc.runtimeType} Change: $change');
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('DEBUG: ${bloc.runtimeType} Transition: $transition');
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('DEBUG: ${bloc.runtimeType} Error: $error');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  try {
    print('DEBUG: Starting app initialization');
    WidgetsFlutterBinding.ensureInitialized();

    // Set up bloc observer for debugging
    Bloc.observer = SimpleBlocObserver();

    print('DEBUG: Setting up dependencies');
    setupDependencies();

    print('DEBUG: Initializing API client');
    await ApiClient.initializeBaseUrl();

    print('DEBUG: Creating ThemeProvider');
    final themeProvider = ThemeProvider();

    print('DEBUG: Running app');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          BlocProvider(
            create: (context) {
              print('DEBUG: Creating AuthBloc');
              return getIt<AuthBloc>()..add(CheckLoginStatus());
            },
            lazy: false,
          ),
          BlocProvider(
            create: (context) {
              print('DEBUG: Creating DashboardBloc');
              return getIt<DashboardBloc>();
            },
            lazy: false,
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              navigatorKey: AppRouter.globalNavigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Smart Net QR Scanner',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: Provider.of<ThemeProvider>(context).themeMode,
              initialRoute: AppRouter.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          }
        ),
      ),
    );
  } catch (e, stackTrace) {
    print('DEBUG: Initialization error: $e');
    print('DEBUG: Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Khởi động ứng dụng thất bại: $e'),
          ),
        ),
      ),
    );
  }
}
