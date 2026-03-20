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

    blocTest<AuthBloc, AuthState>(
      'AuthTotpSetupConfirmed emits [Loading, Error] on network failure',
      build: () {
        when(() => mockRepo.confirmTotpSetup(tempToken: any(named: 'tempToken'), code: any(named: 'code')))
            .thenAnswer((_) async => const HttpFailure(NetworkFailure('offline')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthTotpSetupConfirmed(tempToken: 'tmp', code: '000000')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
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

  // ─── AuthCheckEmailRequested ─────────────────────────────────────────────────

  group('AuthBloc — AuthCheckEmailRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthEmailChecked(totp)] when backend returns totp',
      build: () {
        when(() => mockRepo.checkEmail(any())).thenAnswer(
          (_) async => const Success({'authMethod': 'totp'}),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthCheckEmailRequested(email: 'owner@test.com')),
      expect: () => [
        const AuthLoading(),
        isA<AuthEmailChecked>()
            .having((s) => s.authMethod, 'authMethod', 'totp')
            .having((s) => s.email, 'email', 'owner@test.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthEmailChecked(password)] when backend returns password',
      build: () {
        when(() => mockRepo.checkEmail(any())).thenAnswer(
          (_) async => const Success({'authMethod': 'password'}),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthCheckEmailRequested(email: 'member@test.com')),
      expect: () => [
        const AuthLoading(),
        isA<AuthEmailChecked>()
            .having((s) => s.authMethod, 'authMethod', 'password')
            .having((s) => s.email, 'email', 'member@test.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.checkEmail(any())).thenAnswer(
          (_) async => const HttpFailure(NetworkFailure('no internet')),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthCheckEmailRequested(email: 'x@x.com')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  // ─── AuthPasswordLoginRequested ──────────────────────────────────────────────

  group('AuthBloc — AuthPasswordLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on valid credentials',
      build: () {
        when(() => mockRepo.loginWithPassword(
              email: 'member@test.com',
              password: 'correctPass',
            )).thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthPasswordLoginRequested(email: 'member@test.com', password: 'correctPass')),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid credentials',
      build: () {
        when(() => mockRepo.loginWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid credentials')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthPasswordLoginRequested(email: 'member@test.com', password: 'wrongPass')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Código inválido ou expirado. Tente novamente.'),
      ],
    );
  });

  // ─── AuthForgotPasswordRequested ─────────────────────────────────────────────

  group('AuthBloc — AuthForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthForgotPasswordSent] on success',
      build: () {
        when(() => mockRepo.forgotPassword(any())).thenAnswer(
          (_) async => const Success(null),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthForgotPasswordRequested(email: 'member@test.com')),
      expect: () => [const AuthLoading(), const AuthForgotPasswordSent()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.forgotPassword(any())).thenAnswer(
          (_) async => const HttpFailure(NetworkFailure('no internet')),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthForgotPasswordRequested(email: 'member@test.com')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );
  });

  // ─── AuthResetPasswordRequested ──────────────────────────────────────────────

  group('AuthBloc — AuthResetPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthPasswordResetSuccess] on success',
      build: () {
        when(() => mockRepo.resetPassword(any(), any())).thenAnswer(
          (_) async => const Success(null),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthResetPasswordRequested(token: 'valid-token', newPassword: 'novaSenha456')),
      expect: () => [const AuthLoading(), const AuthPasswordResetSuccess()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid/expired token',
      build: () {
        when(() => mockRepo.resetPassword(any(), any())).thenAnswer(
          (_) async =>
              const HttpFailure(UnauthorizedFailure('token expired')),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc
          .add(const AuthResetPasswordRequested(token: 'expired-token', newPassword: 'newPass')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Código inválido ou expirado. Tente novamente.'),
      ],
    );
  });

  // ─── AuthAcceptInviteRequested ───────────────────────────────────────────────

  group('AuthBloc — AuthAcceptInviteRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthInviteAccepted] on success',
      build: () {
        when(() => mockRepo.acceptInvite(any(), any(), any())).thenAnswer(
          (_) async => const Success((accessToken: 'acc')),
        );
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthAcceptInviteRequested(token: 'invite-token', name: 'Carlos', password: 'pass123')),
      expect: () => [const AuthLoading(), const AuthInviteAccepted()],
      verify: (bloc) => verifyNever(() => mockRepo.getMe()),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid invite token',
      build: () {
        when(() => mockRepo.acceptInvite(any(), any(), any())).thenAnswer(
          (_) async =>
              const HttpFailure(UnauthorizedFailure('invite expired')),
        );
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthAcceptInviteRequested(token: 'bad-token', name: 'Carlos', password: 'pass123')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Código inválido ou expirado. Tente novamente.'),
      ],
    );
  });
}
