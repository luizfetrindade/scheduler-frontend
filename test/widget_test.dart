import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/core/auth/auth_service.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/router/app_router.dart';

void main() {
  testWidgets('FlutterBaseApp smoke test — unauthenticated shows login', (tester) async {
    final auth = AuthService();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createAppRouter(auth),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
