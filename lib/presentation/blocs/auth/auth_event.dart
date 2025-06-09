part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  final BuildContext? context;

  const LoginEvent(this.username, this.password, {this.context});

  @override
  List<Object> get props => [username, password];
}

class CheckLoginStatus extends AuthEvent {
  const CheckLoginStatus();
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class TokenExpiringEvent extends AuthEvent {
  const TokenExpiringEvent();
}
