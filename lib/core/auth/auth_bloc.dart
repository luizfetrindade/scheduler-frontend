import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthUserFetched>(_onUserFetched);
    on<AuthEmailSubmitted>(_onEmailSubmitted);
    on<AuthTotpLoginSubmitted>(_onTotpLoginSubmitted);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthTotpSetupConfirmed>(_onTotpSetupConfirmed);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckEmailRequested>(_onCheckEmailRequested);
    on<AuthPasswordLoginRequested>(_onPasswordLoginRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthAcceptInviteRequested>(_onAcceptInviteRequested);
  }

  /// Checks if there is a stored token and fetches the current user.
  /// Emits AuthUnauthenticated if no token exists or the token is invalid.
  Future<void> _onUserFetched(
    AuthUserFetched event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.getMe();
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(data));
      case HttpFailure():
        emit(const AuthUnauthenticated());
    }
  }

  /// Step 1 of login: validates the email exists before asking for TOTP.
  Future<void> _onEmailSubmitted(
    AuthEmailSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.verifyEmail(email: event.email);
    switch (result) {
      case Success(:final data) when data:
        emit(AuthTotpChallengeReady(email: event.email));
      case Success():
        emit(const AuthError('E-mail não encontrado. Verifique e tente novamente.'));
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 2 of login: verifies the TOTP code and authenticates the user.
  Future<void> _onTotpLoginSubmitted(
    AuthTotpLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final loginResult = await _repository.loginWithTotp(
      email: event.email,
      code: event.code,
    );
    switch (loginResult) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        final meResult = await _repository.getMe();
        switch (meResult) {
          case Success(:final data):
            emit(AuthAuthenticated(data));
          case HttpFailure(:final failure):
            emit(AuthError(_message(failure)));
        }
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 1 of registration: creates the account and returns TOTP setup data.
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.register(
      name: event.name,
      email: event.email,
      phone: event.phone,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthTotpSetupReady(
          qrCodeUrl: data.qrCodeUrl,
          secret: data.secret,
          tempToken: data.tempToken,
        ));
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 3 of registration: confirms TOTP setup and authenticates the user.
  Future<void> _onTotpSetupConfirmed(
    AuthTotpSetupConfirmed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.confirmTotpSetup(
      tempToken: event.tempToken,
      code: event.code,
    );
    switch (result) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        final meResult = await _repository.getMe();
        switch (meResult) {
          case Success(:final data):
            emit(AuthAuthenticated(data));
          case HttpFailure(:final failure):
            emit(AuthError(_message(failure)));
        }
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.clearTokens();
    emit(const AuthUnauthenticated());
  }

  /// Checks which auth method the backend requires for the given email.
  Future<void> _onCheckEmailRequested(
    AuthCheckEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.checkEmail(event.email);
    switch (result) {
      case Success(:final data):
        final authMethod = data['authMethod'];
        if (authMethod is! String) {
          emit(const AuthError('Algo deu errado. Tente novamente'));
          return;
        }
        emit(AuthEmailChecked(event.email, authMethod));
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Authenticates a member/staff user with email + password.
  Future<void> _onPasswordLoginRequested(
    AuthPasswordLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final loginResult = await _repository.loginWithPassword(
      email: event.email,
      password: event.password,
    );
    switch (loginResult) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        final meResult = await _repository.getMe();
        switch (meResult) {
          case Success(:final data):
            emit(AuthAuthenticated(data));
          case HttpFailure(:final failure):
            emit(AuthError(_message(failure)));
        }
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Sends a password-reset email to the given address.
  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.forgotPassword(event.email);
    switch (result) {
      case Success():
        emit(const AuthForgotPasswordSent());
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Resets the user's password using the one-time token from the email.
  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.resetPassword(event.token, event.newPassword);
    switch (result) {
      case Success():
        emit(const AuthPasswordResetSuccess());
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Accepts a staff invite and sets up the account.
  Future<void> _onAcceptInviteRequested(
    AuthAcceptInviteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.acceptInvite(
      event.token,
      event.name,
      event.password,
    );
    switch (result) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        emit(const AuthInviteAccepted());
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  String _message(AppFailure failure) => switch (failure) {
        UnauthorizedFailure() => 'Código inválido ou expirado. Tente novamente.',
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Algo deu errado. Tente novamente',
      };
}
