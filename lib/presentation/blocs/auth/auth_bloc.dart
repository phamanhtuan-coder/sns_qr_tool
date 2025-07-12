import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/data/services/auth_service.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = getIt<AuthService>();
  DateTime? _lastLoginAttempt;
  static const _loginDebounceTime = Duration(seconds: 1);

  AuthBloc() : super(const AuthState()) {
    print('DEBUG: Creating AuthBloc');

    on<LoginEvent>(_handleLoginEvent);
    on<CheckLoginStatus>(_handleCheckLoginStatus);
    on<LogoutEvent>(_handleLogoutEvent);
    on<TokenExpiringEvent>(_handleTokenExpiringEvent);
  }

  Future<void> _handleLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    print('DEBUG: Processing LoginEvent for ${event.username}');

    // Apply debounce to prevent multiple rapid login attempts
    final now = DateTime.now();
    if (_lastLoginAttempt != null && now.difference(_lastLoginAttempt!) < _loginDebounceTime) {
      print('DEBUG: Login attempt debounced');
      return;
    }
    _lastLoginAttempt = now;

    // Show loading state
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Clear any previous errors before attempting login
      if (state.error != null) {
        emit(state.copyWith(error: null));
      }

      // Call the auth service
      final userData = await _authService.login(
        event.username,
        event.password
      );

      print('DEBUG: Login response received: $userData');

      if (userData != null) {
        // Create User object from response data
        final user = User(
          name: userData['name'] ?? userData['username'] ?? event.username,
          role: userData['role'] ?? 'Admin',
          department: userData['department'] ?? 'IT',
        );

        print('DEBUG: Login successful - user: $user');

        // Update state with authenticated user
        emit(state.copyWith(
          isAuthenticated: true,
          user: user,
          error: null,
          isLoading: false,
          showTokenWarning: false
        ));

        // Handle navigation if context provided
        if (event.context != null && event.context!.mounted) {
          print('DEBUG: Navigating to dashboard');
          Navigator.of(event.context!).pushReplacementNamed(AppRouter.dashboard);
        }
      } else {
        // Handle login failure - provide more specific error message
        print('DEBUG: Login failed - credentials invalid or API error');
        emit(state.copyWith(
          isAuthenticated: false,
          user: null,
          error: 'Sai tên đăng nhập hoặc mật khẩu. Vui lòng kiểm tra lại.',
          isLoading: false
        ));
      }
    } catch (e, stackTrace) {
      print('DEBUG: Login error: $e');
      logError('Lỗi xử lý sự kiện LoginEvent', e, stackTrace);

      // Return error state with more specific message
      String errorMessage = 'Có lỗi xảy ra khi đăng nhập';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Lỗi định dạng dữ liệu từ máy chủ.';
      }

      emit(state.copyWith(
        isAuthenticated: false,
        user: null,
        error: errorMessage,
        isLoading: false
      ));
    }
  }

  Future<void> _handleCheckLoginStatus(CheckLoginStatus event, Emitter<AuthState> emit) async {
    print('DEBUG: Checking login status');

    emit(state.copyWith(isLoading: true));

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      final username = await _authService.getUsername();
      final currentUser = await _authService.getCurrentUser();

      print('DEBUG: isLoggedIn: $isLoggedIn, username: $username');

      if (isLoggedIn && username != null) {
        // Create User object from stored data or defaults
        final user = User(
          name: currentUser?['name'] ?? currentUser?['username'] ?? username,
          role: currentUser?['role'] ?? 'Kỹ thuật viên',
          department: currentUser?['department'] ?? 'Sản xuất',
        );

        print('DEBUG: User is authenticated with stored credentials');
        emit(state.copyWith(
          isAuthenticated: true,
          user: user,
          error: null,
          isLoading: false
        ));
      } else {
        print('DEBUG: No stored credentials, user is not authenticated');
        emit(state.copyWith(
          isAuthenticated: false,
          user: null,
          error: null,
          isLoading: false
        ));
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error checking login status: $e');
      logError('Lỗi kiểm tra trạng thái đăng nhập', e, stackTrace);

      emit(state.copyWith(
        isAuthenticated: false,
        user: null,
        error: null, // Don't show error on startup check
        isLoading: false
      ));
    }
  }

  Future<void> _handleLogoutEvent(LogoutEvent event, Emitter<AuthState> emit) async {
    print('DEBUG: Processing LogoutEvent');

    try {
      // Clear credentials
      await _authService.logout();

      // Update state
      emit(const AuthState(
        isAuthenticated: false,
        user: null,
        error: null,
        isLoading: false,
        showTokenWarning: false
      ));

    } catch (e, stackTrace) {
      print('DEBUG: Error during logout: $e');
      logError('Lỗi xử lý sự kiện LogoutEvent', e, stackTrace);

      // Still log the user out in UI even if backend fails
      emit(const AuthState(
        isAuthenticated: false,
        user: null,
        error: null,
        isLoading: false,
        showTokenWarning: false
      ));
    }
  }

  Future<void> _handleTokenExpiringEvent(TokenExpiringEvent event, Emitter<AuthState> emit) async {
    print('DEBUG: Processing TokenExpiringEvent');

    // Only show warning if user is authenticated
    if (state.isAuthenticated) {
      emit(state.copyWith(
        showTokenWarning: true,
        tokenWarningMessage: 'Phiên làm việc sắp hết hạn. Vui lòng đăng nhập lại để tiếp tục.'
      ));
    }
  }
}
