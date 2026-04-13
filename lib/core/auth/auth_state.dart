import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state before the startup token check completes.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Register flow: OTP sent to email, waiting for user to enter code.
class AuthRegisterOtpSent extends AuthState {
  final String email;
  const AuthRegisterOtpSent(this.email);
  @override
  List<Object?> get props => [email];
}

/// Login flow: OTP sent to email, waiting for user to enter code.
class AuthLoginOtpSent extends AuthState {
  final String email;
  const AuthLoginOtpSent({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Accept-invite flow: OTP sent, waiting for user to enter code.
class AuthInviteOtpSent extends AuthState {
  const AuthInviteOtpSent();
}

/// forgot-password flow: reset email has been dispatched successfully.
class AuthForgotPasswordSent extends AuthState {
  const AuthForgotPasswordSent();
}

/// reset-password flow: password was reset successfully.
class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

/// accept-invite flow: invite accepted, account created — ready to welcome user.
class AuthInviteAccepted extends AuthState {
  const AuthInviteAccepted();
}
