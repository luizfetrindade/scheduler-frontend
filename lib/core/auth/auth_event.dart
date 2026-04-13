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

/// Step 1 of registration: submit profile fields. Sends OTP to email.
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

/// Step 2 of registration: confirm the OTP code sent to email.
class AuthRegisterOtpConfirmed extends AuthEvent {
  final String email;
  final String code;
  const AuthRegisterOtpConfirmed({required this.email, required this.code});
  @override
  // OTP code excluded — must not appear in Equatable toString() output.
  List<Object?> get props => [email];
}

/// Step 1 of login: send OTP to user's email.
class AuthLoginInitiateRequested extends AuthEvent {
  final String email;
  const AuthLoginInitiateRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Step 2 of login: confirm the OTP code sent to email.
class AuthOtpLoginSubmitted extends AuthEvent {
  final String email;
  final String code;
  final bool rememberMe;
  const AuthOtpLoginSubmitted({
    required this.email,
    required this.code,
    required this.rememberMe,
  });
  @override
  // OTP code excluded — must not appear in Equatable toString() output.
  List<Object?> get props => [email, rememberMe];
}

/// Dispatched when the user taps logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Step 1 of accept-invite: validate token and send OTP to invite email.
class AuthAcceptInviteRequested extends AuthEvent {
  final String token;
  final String name;
  const AuthAcceptInviteRequested({required this.token, required this.name});
  @override
  // Token excluded — sensitive credential.
  List<Object?> get props => [name];
}

/// Step 2 of accept-invite: confirm OTP and activate the account.
class AuthAcceptInviteOtpConfirmed extends AuthEvent {
  final String token;
  final String code;
  const AuthAcceptInviteOtpConfirmed({required this.token, required this.code});
  @override
  // Token and OTP code excluded — sensitive credentials.
  List<Object?> get props => [];
}

/// Triggers a forgot-password email to be sent.
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Submits a new password using the reset token received by email.
class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  const AuthResetPasswordRequested({required this.token, required this.newPassword});
  @override
  // Reset token and new password excluded — sensitive credentials.
  List<Object?> get props => [];
}

/// Legacy event — password_login_page.dart is unreachable in the current flow.
/// Kept to avoid a compile error until the page is removed.
class AuthPasswordLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  const AuthPasswordLoginRequested({
    required this.email,
    required this.password,
    required this.rememberMe,
  });
  @override
  List<Object?> get props => [email, rememberMe];
}
