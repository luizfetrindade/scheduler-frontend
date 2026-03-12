import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthUserFetched>(_onUserFetched);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
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

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final loginResult = await _repository.login(
      email: event.email,
      password: event.password,
    );
    switch (loginResult) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken, data.refreshToken);
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

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final registerResult = await _repository.register(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    switch (registerResult) {
      case Success(:final data):
        await _repository.saveTokens(data.accessToken, data.refreshToken);
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
        UnauthorizedFailure() => 'Email ou senha incorretos',
        NetworkFailure() => 'Sem conexão com a internet',
        _ => 'Algo deu errado. Tente novamente',
      };
}
