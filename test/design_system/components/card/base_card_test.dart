import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/components/card/base_card.dart';
import 'package:scheduler_frontend/design_system/tokens/app_spacing.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';

void main() {
  Widget buildCard({
    Widget? child,
    VoidCallback? onTap,
    bool elevated = false,
    double padding = AppSpacing.lg,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: BaseCard(
          onTap: onTap,
          elevated: elevated,
          padding: padding,
          child: child ?? const Text('content'),
        ),
      ),
    );
  }

  group('BaseCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildCard(child: const Text('Treino A')));
      expect(find.text('Treino A'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.tap(find.byType(BaseCard));
      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await tester.pumpWidget(buildCard(onTap: null));
      await tester.tap(find.byType(BaseCard), warnIfMissed: false);
      expect(find.byType(BaseCard), findsOneWidget);
    });

    testWidgets('applies shadow when elevated=true', (tester) async {
      await tester.pumpWidget(buildCard(elevated: true));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBoxShadow = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.boxShadow != null &&
            decoration.boxShadow!.isNotEmpty;
      });
      expect(hasBoxShadow, isTrue);
    });

    testWidgets('no shadow when elevated=false', (tester) async {
      await tester.pumpWidget(buildCard(elevated: false));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBoxShadow = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.boxShadow != null &&
            decoration.boxShadow!.isNotEmpty;
      });
      expect(hasBoxShadow, isFalse);
    });
  });
}
