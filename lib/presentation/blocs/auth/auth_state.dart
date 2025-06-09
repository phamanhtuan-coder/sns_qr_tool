part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final User? user;
  final String? error;
  final bool isLoading;
  final bool showTokenWarning;
  final String? tokenWarningMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isLoading = false,
    this.showTokenWarning = false,
    this.tokenWarningMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? error,
    bool? isLoading,
    bool? showTokenWarning,
    String? tokenWarningMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error, // Allow nulling error messages
      isLoading: isLoading ?? this.isLoading,
      showTokenWarning: showTokenWarning ?? this.showTokenWarning,
      tokenWarningMessage: tokenWarningMessage ?? this.tokenWarningMessage,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, user, error, isLoading, showTokenWarning, tokenWarningMessage];
}