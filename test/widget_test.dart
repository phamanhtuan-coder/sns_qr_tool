// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/screens/splash_screen.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';
import 'package:smart_net_qr_scanner/utils/theme.dart';
import 'package:smart_net_qr_scanner/utils/theme_provider.dart';

void main() {
  setUp(() {
    setupDependencies();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          BlocProvider(
            create: (context) => getIt<AuthBloc>()..add(CheckLoginStatus()),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => getIt<DashboardBloc>(),
            lazy: false,
          ),
        ],
        child: MaterialApp(
          navigatorKey: AppRouter.globalNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Smart Net QR Scanner',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );

    // Verify that the splash screen is shown initially
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
