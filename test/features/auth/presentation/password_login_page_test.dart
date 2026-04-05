import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/auth/presentation/password_login_page.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// ─── Helpers ───────────────────────────────────────────────────────────────

Widget _buildPage(MockAuthBloc bloc, {String email = 'user@example.com'}) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: PasswordLoginPage(email: email, rememberMe: false),
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(
      const AuthPasswordLoginRequested(
        email: 'test@test.com',
        password: 'secret',
        rememberMe: false,
      ),
    );
  });

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
  });

  testWidgets('submitting password dispatches AuthPasswordLoginRequested',
      (tester) async {
    await tester.pumpWidget(_buildPage(authBloc));
    await tester.pump(const Duration(milliseconds: 100));

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.first, 'mypassword123');
    await tester.pump(const Duration(milliseconds: 100));

    final enterButton = find.text('Entrar');
    await tester.tap(enterButton);
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => authBloc.add(
        const AuthPasswordLoginRequested(
          email: 'user@example.com',
          password: 'mypassword123',
          rememberMe: false,
        ),
      ),
    ).called(1);
  });

  testWidgets('empty password does not dispatch event', (tester) async {
    await tester.pumpWidget(_buildPage(authBloc));
    await tester.pump(const Duration(milliseconds: 100));

    final enterButton = find.text('Entrar');
    await tester.tap(enterButton);
    await tester.pump(const Duration(milliseconds: 100));

    verifyNever(() => authBloc.add(any()));
  });
}
