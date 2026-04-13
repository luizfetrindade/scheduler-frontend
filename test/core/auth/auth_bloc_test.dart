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

  // ─── AuthLoginInitiateRequested ─────────────────────────────────────────────

  group('AuthBloc — AuthLoginInitiateRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthLoginOtpSent] when OTP is sent successfully',
      build: () {
        when(() => mockRepo.loginInitiate(email: 'j@j.com'))
            .thenAnswer((_) async => const Success(null));
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthLoginInitiateRequested(email: 'j@j.com')),
      expect: () => [
        const AuthLoading(),
        const AuthLoginOtpSent(email: 'j@j.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.loginInitiate(email: any(named: 'email')))
            .thenAnswer((_) async =>
                const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthLoginInitiateRequested(email: 'x@x.com')),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] when email is not found',
      build: () {
        when(() => mockRepo.loginInitiate(email: any(named: 'email')))
            .thenAnswer((_) async =>
                const HttpFailure(NotFoundFailure('not found')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const AuthLoginInitiateRequested(email: 'x@x.com')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  // ─── AuthOtpLoginSubmitted ──────────────────────────────────────────────────

  group('AuthBloc — AuthOtpLoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on valid OTP code',
      build: () {
        when(() => mockRepo.loginConfirm(
              email: 'j@j.com',
              code: '123456',
              rememberMe: false,
            )).thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        when(() => mockRepo.clearRememberMe()).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthOtpLoginSubmitted(
          email: 'j@j.com', code: '123456', rememberMe: false)),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid OTP code',
      build: () {
        when(() => mockRepo.loginConfirm(
              email: any(named: 'email'),
              code: any(named: 'code'),
              rememberMe: any(named: 'rememberMe'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid code')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthOtpLoginSubmitted(
          email: 'j@j.com', code: '000000', rememberMe: false)),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.loginConfirm(
              email: any(named: 'email'),
              code: any(named: 'code'),
              rememberMe: any(named: 'rememberMe'),
            )).thenAnswer((_) async =>
            const HttpFailure(NetworkFailure('no internet')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthOtpLoginSubmitted(
          email: 'j@j.com', code: '123456', rememberMe: false)),
      expect: () => [
        const AuthLoading(),
        const AuthError('Sem conexão com a internet'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'saves remember-me on successful OTP login when rememberMe=true',
      setUp: () {
        when(() => mockRepo.loginConfirm(
              email: 'j@j.com',
              code: '123456',
              rememberMe: true,
            )).thenAnswer((_) async => const Success((accessToken: 'a')));
        when(() => mockRepo.saveTokens(any())).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        when(() => mockRepo.saveRememberMe(any())).thenAnswer((_) async {});
      },
      build: () => AuthBloc(mockRepo),
      act: (bloc) => bloc.add(const AuthOtpLoginSubmitted(
        email: 'j@j.com',
        code: '123456',
        rememberMe: true,
      )),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
      verify: (_) {
        verify(() => mockRepo.saveRememberMe('j@j.com')).called(1);
        verifyNever(() => mockRepo.clearRememberMe());
      },
    );

    blocTest<AuthBloc, AuthState>(
      'clears remember-me on successful OTP login when rememberMe=false',
      setUp: () {
        when(() => mockRepo.loginConfirm(
              email: 'j@j.com',
              code: '123456',
              rememberMe: false,
            )).thenAnswer((_) async => const Success((accessToken: 'a')));
        when(() => mockRepo.saveTokens(any())).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        when(() => mockRepo.clearRememberMe()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(mockRepo),
      act: (bloc) => bloc.add(const AuthOtpLoginSubmitted(
        email: 'j@j.com',
        code: '123456',
        rememberMe: false,
      )),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
      verify: (_) {
        verify(() => mockRepo.clearRememberMe()).called(1);
        verifyNever(() => mockRepo.saveRememberMe(any()));
      },
    );
  });

  // ─── AuthRegisterRequested ──────────────────────────────────────────────────

  group('AuthBloc — AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthRegisterOtpSent] on successful registration',
      build: () {
        when(() => mockRepo.register(
              name: 'Ana',
              email: 'a@a.com',
              phone: '11999990000',
            )).thenAnswer((_) async => const Success(null));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        name: 'Ana',
        email: 'a@a.com',
        phone: '11999990000',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthRegisterOtpSent('a@a.com'),
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

  // ─── AuthRegisterOtpConfirmed ───────────────────────────────────────────────

  group('AuthBloc — AuthRegisterOtpConfirmed', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on valid OTP code',
      build: () {
        when(() => mockRepo.registerConfirm(
              email: 'a@a.com',
              code: '654321',
            )).thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        when(() => mockRepo.getMe())
            .thenAnswer((_) async => const Success(_user));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterOtpConfirmed(
        email: 'a@a.com',
        code: '654321',
      )),
      expect: () => [const AuthLoading(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid OTP code',
      build: () {
        when(() => mockRepo.registerConfirm(
              email: any(named: 'email'),
              code: any(named: 'code'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid code')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterOtpConfirmed(
        email: 'a@a.com',
        code: '000000',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on network failure',
      build: () {
        when(() => mockRepo.registerConfirm(
                email: any(named: 'email'), code: any(named: 'code')))
            .thenAnswer(
                (_) async => const HttpFailure(NetworkFailure('offline')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthRegisterOtpConfirmed(email: 'a@a.com', code: '000000')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });

  // ─── AuthLogoutRequested ────────────────────────────────────────────────────

  group('AuthBloc — AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'calls logout() and emits [Unauthenticated]',
      build: () {
        when(() => mockRepo.logout()).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) => verify(() => mockRepo.logout()).called(1),
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
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(
          token: 'valid-token', newPassword: 'novaSenha456')),
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
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(
          token: 'expired-token', newPassword: 'newPass')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  // ─── AuthAcceptInviteRequested ───────────────────────────────────────────────

  group('AuthBloc — AuthAcceptInviteRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthInviteOtpSent] on success',
      build: () {
        when(() => mockRepo.acceptInviteInitiate(
              token: any(named: 'token'),
              name: any(named: 'name'),
            )).thenAnswer((_) async => const Success(null));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthAcceptInviteRequested(token: 'invite-token', name: 'Carlos')),
      expect: () => [const AuthLoading(), const AuthInviteOtpSent()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid invite token',
      build: () {
        when(() => mockRepo.acceptInviteInitiate(
              token: any(named: 'token'),
              name: any(named: 'name'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invite expired')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
          const AuthAcceptInviteRequested(token: 'bad-token', name: 'Carlos')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  // ─── AuthAcceptInviteOtpConfirmed ────────────────────────────────────────────

  group('AuthBloc — AuthAcceptInviteOtpConfirmed', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthInviteAccepted] on valid OTP',
      build: () {
        when(() => mockRepo.acceptInviteConfirm(
              token: any(named: 'token'),
              code: any(named: 'code'),
            )).thenAnswer((_) async => const Success((accessToken: 'acc')));
        when(() => mockRepo.saveTokens('acc')).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthAcceptInviteOtpConfirmed(
          token: 'invite-token', code: '123456')),
      expect: () => [const AuthLoading(), const AuthInviteAccepted()],
      verify: (bloc) => verifyNever(() => mockRepo.getMe()),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on invalid OTP',
      build: () {
        when(() => mockRepo.acceptInviteConfirm(
              token: any(named: 'token'),
              code: any(named: 'code'),
            )).thenAnswer((_) async =>
            const HttpFailure(UnauthorizedFailure('invalid code')));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthAcceptInviteOtpConfirmed(
          token: 'invite-token', code: '000000')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });
}
