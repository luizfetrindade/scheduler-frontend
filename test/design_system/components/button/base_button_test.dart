import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/components/button/base_button.dart';
import 'package:scheduler_frontend/design_system/components/button/base_button_variant.dart';

void main() {
  Widget buildButton({
    String label = 'Test',
    VoidCallback? onPressed,
    BaseButtonVariant variant = BaseButtonVariant.primary,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? prefixIcon,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BaseButton(
          label: label,
          onPressed: onPressed,
          variant: variant,
          isLoading: isLoading,
          isDisabled: isDisabled,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }

  group('BaseButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(buildButton(label: 'Iniciar Treino'));
      expect(find.text('Iniciar Treino'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildButton(onPressed: () => pressed = true));
      await tester.tap(find.byType(BaseButton));
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when isDisabled', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildButton(
        onPressed: () => pressed = true,
        isDisabled: true,
      ));
      await tester.tap(find.byType(BaseButton));
      expect(pressed, isFalse);
    });

    testWidgets('does not call onPressed when isLoading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildButton(
        onPressed: () => pressed = true,
        isLoading: true,
      ));
      await tester.tap(find.byType(BaseButton));
      expect(pressed, isFalse);
    });

    testWidgets('shows CircularProgressIndicator when isLoading', (tester) async {
      await tester.pumpWidget(buildButton(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows prefixIcon when provided', (tester) async {
      await tester.pumpWidget(buildButton(prefixIcon: Icons.play_arrow));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('renders all variants without error', (tester) async {
      for (final variant in BaseButtonVariant.values) {
        await tester.pumpWidget(buildButton(variant: variant));
        expect(find.byType(BaseButton), findsOneWidget);
      }
    });

    testWidgets('does not show label when isLoading', (tester) async {
      await tester.pumpWidget(buildButton(label: 'Iniciar Treino', isLoading: true));
      expect(find.text('Iniciar Treino'), findsNothing);
    });

    testWidgets('shows label and prefixIcon together', (tester) async {
      await tester.pumpWidget(buildButton(
        label: 'Play',
        prefixIcon: Icons.play_arrow,
      ));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });
  });
}
