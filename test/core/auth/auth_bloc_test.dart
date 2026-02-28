import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_repository.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/models/user_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _user = UserModel(id: '1', name: 'João Silva', email: 'j@j.com', roles: []);

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthBloc — AuthUserFetched', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when getMe succeeds',
      build: () {
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthUserFetched()),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when getMe returns 401',
      build: () {
        when(() => mockRepo.getMe()).thenAnswer(
            (_) async => const HttpFailure(UnauthorizedFailure('401')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthUserFetched()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });

  group('AuthBloc — AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful login',
      build: () {
        when(() => mockRepo.login(email: 'j@j.com', password: '123'))
            .thenAnswer((_) async =>
                const Success((accessToken: 'acc', refreshToken: 'ref')));
        when(() => mockRepo.saveTokens('acc', 'ref'))
            .thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthLoginRequested(email: 'j@j.com', password: '123')),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on wrong credentials',
      build: () {
        when(() => mockRepo.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('wrong credentials')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthLoginRequested(email: 'x@x.com', password: 'bad')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Email ou senha incorretos'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async =>
            const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthLoginRequested(email: 'x@x.com', password: '123')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  group('AuthBloc — AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] and clears tokens',
      build: () {
        when(() => mockRepo.clearTokens()).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) => verify(() => mockRepo.clearTokens()).called(1),
    );
  });
}
