part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, user, error];
}