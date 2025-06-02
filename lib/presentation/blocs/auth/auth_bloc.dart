import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/data/services/auth_service.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';
import 'package:smart_net_qr_scanner/utils/di.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = getIt<AuthService>();

  AuthBloc() : super(const AuthState()) {
    on<LoginEvent>((event, emit) async {
      try {
        // Since login functionality doesn't exist yet, just emit authenticated state directly
        // with a dummy user for demonstration purposes
        emit(state.copyWith(
          isAuthenticated: true,
          user: const User(name: 'Người dùng', role: 'Kỹ thuật viên', department: 'Sản xuất'),
          error: null,
        ));
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện LoginEvent', e, stackTrace);
        emit(state.copyWith(
          isAuthenticated: false,
          user: null,
          error: 'Lỗi hệ thống. Vui lòng thử lại.',
        ));
      }
    });

    on<CheckLoginStatus>((event, emit) async {
      try {
        // Since there's no login/logout functionality yet,
        // just consider the user as always logged in with a dummy user
        emit(state.copyWith(
          isAuthenticated: true,
          user: const User(name: 'Người dùng', role: 'Kỹ thuật viên', department: 'Sản xuất'),
          error: null,
        ));
      } catch (e, stackTrace) {
        logError('Lỗi kiểm tra trạng thái đăng nhập', e, stackTrace);
        emit(state.copyWith(
          isAuthenticated: true, // Keep as true for now
          user: const User(name: 'Người dùng', role: 'Kỹ thuật viên', department: 'Sản xuất'),
          error: null,
        ));
      }
    });

    on<LogoutEvent>((event, emit) async {
      // Since logout functionality doesn't exist yet, do nothing
      // Just keep the user authenticated with the dummy user
      emit(state.copyWith(
        isAuthenticated: true,
        user: const User(name: 'Người dùng', role: 'Kỹ thuật viên', department: 'Sản xuất'),
        error: null,
      ));
    });
  }
}
