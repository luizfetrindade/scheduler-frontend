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
import 'package:scheduler_frontend/features/auth/presentation/login_page.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// ─── Helpers ───────────────────────────────────────────────────────────────

Widget _buildLoginPage(MockAuthBloc bloc) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const LoginPage(),
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthLoginInitiateRequested(email: 'test@test.com'));
  });

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
  });

  testWidgets('submitting email dispatches AuthLoginInitiateRequested',
      (tester) async {
    await tester.pumpWidget(_buildLoginPage(authBloc));
    await tester.pump(const Duration(milliseconds: 100));

    final emailField = find.byType(TextField);
    await tester.enterText(emailField, 'user@example.com');
    await tester.pump(const Duration(milliseconds: 100));

    final continueButton = find.text('Continuar');
    await tester.tap(continueButton);
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => authBloc.add(
        const AuthLoginInitiateRequested(email: 'user@example.com'),
      ),
    ).called(1);
  });

  testWidgets('empty email does not dispatch event', (tester) async {
    await tester.pumpWidget(_buildLoginPage(authBloc));
    await tester.pump(const Duration(milliseconds: 100));

    final continueButton = find.text('Continuar');
    await tester.tap(continueButton);
    await tester.pump(const Duration(milliseconds: 100));

    verifyNever(() => authBloc.add(any()));
  });
}
