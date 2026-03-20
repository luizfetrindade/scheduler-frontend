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

/// Step 1 of login: validate that the email exists on the backend.
class AuthEmailSubmitted extends AuthEvent {
  final String email;
  const AuthEmailSubmitted({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Step 2 of login: submit the 6-digit TOTP code from Google Authenticator.
class AuthTotpLoginSubmitted extends AuthEvent {
  final String email;
  final String code;
  const AuthTotpLoginSubmitted({required this.email, required this.code});
  @override
  List<Object?> get props => [email, code];
}

/// Step 1 of registration: submit profile fields (no password).
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
  });
  @override
  List<Object?> get props => [name, email, phone];
}

/// Step 3 of registration: confirm TOTP setup with the 6-digit code.
class AuthTotpSetupConfirmed extends AuthEvent {
  final String tempToken;
  final String code;
  const AuthTotpSetupConfirmed({required this.tempToken, required this.code});
  @override
  List<Object?> get props => [tempToken, code];
}

/// Dispatched when the user taps logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Checks which auth method (totp | password) is required for the given email.
class AuthCheckEmailRequested extends AuthEvent {
  final String email;
  const AuthCheckEmailRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Login with email + password (for staff/member personas).
class AuthPasswordLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthPasswordLoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

/// Triggers a forgot-password email to be sent.
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Submits a new password using the reset token received by email.
class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  const AuthResetPasswordRequested(this.token, this.newPassword);
  @override
  List<Object?> get props => [token, newPassword];
}

/// Accepts a staff invite and sets up the account with name + password.
class AuthAcceptInviteRequested extends AuthEvent {
  final String token;
  final String name;
  final String password;
  const AuthAcceptInviteRequested(this.token, this.name, this.password);
  @override
  List<Object?> get props => [token, name, password];
}
