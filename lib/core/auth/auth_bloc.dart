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

  String _message(AppFailure failure) => switch (failure) {
        UnauthorizedFailure() => 'Código inválido ou expirado. Tente novamente.',
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Algo deu errado. Tente novamente',
      };
}
