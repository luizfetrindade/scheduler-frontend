import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched on app startup to check if a stored token is still valid.
class AuthUserFetched extends AuthEvent {
  const AuthUserFetched();
}

/// Dispatched when the user submits the login form.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, password];
}

/// Dispatched when the user taps logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
