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

  // ─── AuthUserFetched ────────────────────────────────────────────────────────

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

  // ─── AuthEmailSubmitted ─────────────────────────────────────────────────────

  group('AuthBloc — AuthEmailSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, TotpChallengeReady] when email exists',
      build: () {
        when(() => mockRepo.verifyEmail(email: 'j@j.com'))
            .thenAnswer((_) async => const Success(true));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthEmailSubmitted(email: 'j@j.com')),
      expect: () => [
        const AuthLoading(),
        const AuthTotpChallengeReady(email: 'j@j.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] when email is not found',
      build: () {
        when(() => mockRepo.verifyEmail(email: any(named: 'email')))
            .thenAnswer((_) async => const Success(false));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthEmailSubmitted(email: 'x@x.com')),
      expect: () => [
        const AuthLoading(),
        const AuthError('E-mail não encontrado. Verifique e tente novamente.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.verifyEmail(email: any(named: 'email')))
            .thenAnswer((_) async =>
                const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthEmailSubmitted(email: 'x@x.com')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  // ─── AuthTotpLoginSubmitted ─────────────────────────────────────────────────

  group('AuthBloc — AuthTotpLoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on valid TOTP code',
      build: () {
        when(() => mockRepo.loginWithTotp(email: 'j@j.com', code: '123456'))
            .thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthTotpLoginSubmitted(email: 'j@j.com', code: '123456')),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid TOTP code',
      build: () {
        when(() => mockRepo.loginWithTotp(
              email: any(named: 'email'),
              code: any(named: 'code'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid code')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthTotpLoginSubmitted(email: 'j@j.com', code: '000000')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Código inválido ou expirado. Tente novamente.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.loginWithTotp(
              email: any(named: 'email'),
              code: any(named: 'code'),
            )).thenAnswer((_) async =>
            const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthTotpLoginSubmitted(email: 'j@j.com', code: '123456')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  // ─── AuthRegisterRequested ──────────────────────────────────────────────────

  group('AuthBloc — AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, TotpSetupReady] on successful registration',
      build: () {
        when(() => mockRepo.register(
              name: 'Ana',
              email: 'a@a.com',
              phone: '11999990000',
            )).thenAnswer((_) async => const Success((
              qrCodeUrl: 'otpauth://totp/Scheduler:a@a.com',
              secret: 'BASE32SECRET',
              tempToken: 'tmp-token',
            )));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        name: 'Ana',
        email: 'a@a.com',
        phone: '11999990000',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthTotpSetupReady(
          qrCodeUrl: 'otpauth://totp/Scheduler:a@a.com',
          secret: 'BASE32SECRET',
          tempToken: 'tmp-token',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on registration failure',
      build: () {
        when(() => mockRepo.register(
              name: any(named: 'name'),
              email: any(named: 'email'),
              phone: any(named: 'phone'),
            )).thenAnswer((_) async =>
            const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        name: 'X',
        email: 'x@x.com',
        phone: '11000000000',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  // ─── AuthTotpSetupConfirmed ─────────────────────────────────────────────────

  group('AuthBloc — AuthTotpSetupConfirmed', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on valid confirmation code',
      build: () {
        when(() => mockRepo.confirmTotpSetup(
              tempToken: 'tmp-token',
              code: '654321',
            )).thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthTotpSetupConfirmed(
        tempToken: 'tmp-token',
        code: '654321',
      )),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid confirmation code',
      build: () {
        when(() => mockRepo.confirmTotpSetup(
              tempToken: any(named: 'tempToken'),
              code: any(named: 'code'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid code')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthTotpSetupConfirmed(
        tempToken: 'tmp-token',
        code: '000000',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthError('Código inválido ou expirado. Tente novamente.'),
      ],
    );
  });

  // ─── AuthLogoutRequested ────────────────────────────────────────────────────

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
