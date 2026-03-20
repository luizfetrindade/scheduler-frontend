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

/// Login flow: email validated, waiting for the user to enter their TOTP code.
class AuthTotpChallengeReady extends AuthState {
  final String email;
  const AuthTotpChallengeReady({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Register flow: registration accepted, QR code ready to display for setup.
class AuthTotpSetupReady extends AuthState {
  final String qrCodeUrl;
  final String secret;
  final String tempToken;
  const AuthTotpSetupReady({
    required this.qrCodeUrl,
    required this.secret,
    required this.tempToken,
  });
  @override
  List<Object?> get props => [qrCodeUrl, secret, tempToken];
}

/// check-email flow: email found, backend returned which auth method to use.
class AuthEmailChecked extends AuthState {
  final String email;

  /// Either 'totp' (owner/manager) or 'password' (staff/member).
  final String authMethod;
  const AuthEmailChecked(this.email, this.authMethod);
  @override
  List<Object?> get props => [email, authMethod];
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
