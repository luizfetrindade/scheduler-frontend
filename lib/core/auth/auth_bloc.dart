import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthUserFetched>(_onUserFetched);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthRegisterOtpConfirmed>(_onRegisterOtpConfirmed);
    on<AuthLoginInitiateRequested>(_onLoginInitiate);
    on<AuthOtpLoginSubmitted>(_onOtpLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthAcceptInviteRequested>(_onAcceptInviteRequested);
    on<AuthAcceptInviteOtpConfirmed>(_onAcceptInviteOtpConfirmed);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
  }

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

  /// Step 1 of registration: sends OTP to email.
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
      case Success():
        emit(AuthRegisterOtpSent(event.email));
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 2 of registration: confirms OTP and authenticates the user.
  Future<void> _onRegisterOtpConfirmed(
    AuthRegisterOtpConfirmed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.registerConfirm(
      email: event.email,
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

  /// Step 1 of login: sends OTP to email.
  Future<void> _onLoginInitiate(
    AuthLoginInitiateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.loginInitiate(email: event.email);
    switch (result) {
      case Success():
        emit(AuthLoginOtpSent(email: event.email));
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 2 of login: confirms OTP and authenticates the user.
  Future<void> _onOtpLoginSubmitted(
    AuthOtpLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.loginConfirm(
      email: event.email,
      code: event.code,
      rememberMe: event.rememberMe,
    );
    switch (result) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        await _persistRememberMe(event.email, event.rememberMe);
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
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  /// Step 1 of accept-invite: validates token and sends OTP.
  Future<void> _onAcceptInviteRequested(
    AuthAcceptInviteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.acceptInviteInitiate(
      token: event.token,
      name: event.name,
    );
    switch (result) {
      case Success():
        emit(const AuthInviteOtpSent());
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

  /// Step 2 of accept-invite: confirms OTP and creates the account.
  Future<void> _onAcceptInviteOtpConfirmed(
    AuthAcceptInviteOtpConfirmed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.acceptInviteConfirm(
      token: event.token,
      code: event.code,
    );
    switch (result) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken);
        emit(const AuthInviteAccepted());
      case HttpFailure(:final failure):
        emit(AuthError(_message(failure)));
    }
  }

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

  Future<void> _persistRememberMe(String email, bool rememberMe) async {
    if (rememberMe) {
      await _repository.saveRememberMe(email);
    } else {
      await _repository.clearRememberMe();
    }
  }

  String _message(AppFailure failure) {
    if (failure is ServerFailure) {
      print('[AUTH_ERROR] ServerFailure: ${failure.message} (Status: ${failure.statusCode})');
    } else if (failure is UnauthorizedFailure) {
      print('[AUTH_ERROR] UnauthorizedFailure: ${failure.message}');
    } else {
      print('[AUTH_ERROR] Generic/Unknown Failure: $failure');
    }

    return switch (failure) {
      UnauthorizedFailure(:final message) => message,
      NetworkFailure() => 'Sem conexão com a internet',
      ServerFailure(:final message) => message,
      _ => 'Algo deu errado ($failure). Tente novamente',
    };
  }
}
