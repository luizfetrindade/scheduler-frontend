import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/components/input/base_input_field.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';

void main() {
  Widget buildInput({
    String label = 'Label',
    String? hint,
    TextEditingController? controller,
    String? errorText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool isPassword = false,
    bool isDisabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: BaseInputField(
          label: label,
          hint: hint,
          controller: controller,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isPassword: isPassword,
          isDisabled: isDisabled,
          keyboardType: keyboardType,
        ),
      ),
    );
  }

  group('BaseInputField', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(buildInput(label: 'E-mail'));
      expect(find.text('E-mail'), findsOneWidget);
    });

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(buildInput(hint: 'seu@email.com'));
      expect(find.text('seu@email.com'), findsOneWidget);
    });

    testWidgets('shows error text when provided', (tester) async {
      await tester.pumpWidget(buildInput(errorText: 'Campo obrigatório'));
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('shows prefixIcon when provided', (tester) async {
      await tester.pumpWidget(buildInput(prefixIcon: Icons.email_outlined));
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('text is obscured when isPassword=true', (tester) async {
      final controller = TextEditingController(text: 'secret');
      await tester.pumpWidget(buildInput(isPassword: true, controller: controller));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });

    testWidgets('toggles visibility when eye icon tapped', (tester) async {
      final controller = TextEditingController(text: 'secret');
      await tester.pumpWidget(buildInput(isPassword: true, controller: controller));

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    });

    testWidgets('toggles back to obscured when eye icon tapped twice', (tester) async {
      final controller = TextEditingController(text: 'secret');
      await tester.pumpWidget(buildInput(isPassword: true, controller: controller));

      // First tap: reveal
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);

      // Second tap: hide again
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    });

    testWidgets('shows suffixIcon on non-password field', (tester) async {
      await tester.pumpWidget(buildInput(suffixIcon: Icons.clear));
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('passes keyboardType to TextField', (tester) async {
      await tester.pumpWidget(buildInput(keyboardType: TextInputType.emailAddress));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('is not enabled when isDisabled=true', (tester) async {
      await tester.pumpWidget(buildInput(isDisabled: true));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isFalse);
    });
  });
}
