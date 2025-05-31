import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firmware_deployment_tool/data/models/user.dart';
import 'package:firmware_deployment_tool/data/services/auth_service.dart';
import 'package:firmware_deployment_tool/utils/logger.dart';
import 'package:firmware_deployment_tool/utils/di.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = getIt<AuthService>();

  AuthBloc() : super(const AuthState()) {
    on<LoginEvent>((event, emit) async {
      try {
        final success = await _authService.login(event.username, event.password, event.remember);
        if (success) {
          emit(state.copyWith(
            isAuthenticated: true,
            user: _authService.user,
            error: null,
          ));
        } else {
          emit(state.copyWith(
            isAuthenticated: false,
            user: null,
            error: 'Invalid credentials',
          ));
        }
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện LoginEvent', e, stackTrace);
        emit(state.copyWith(
          isAuthenticated: false,
          user: null,
          error: 'Lỗi hệ thống. Vui lòng thử lại.',
        ));
      }
    });
  }
}

