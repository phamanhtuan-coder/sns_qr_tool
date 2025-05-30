part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  final bool remember;

  const LoginEvent(this.username, this.password, this.remember);

  @override
  List<Object> get props => [username, password, remember];
}