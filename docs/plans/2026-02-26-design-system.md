# Flutter Base App Design System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a scalable design system with tokens (colors, typography, spacing, radius, shadows) and three components — BaseButton (4 variants), BaseInputField (completo) e BaseCard (genérico).

**Architecture:** Tokens são classes com constantes estáticas em `lib/design_system/tokens/`. Componentes em `lib/design_system/components/` consomem apenas os tokens — nunca valores hardcoded. Barrel file `base_design_system.dart` exporta tudo.

**Tech Stack:** Flutter/Dart 3.10+, flutter_test (widget tests)

---

## Task 1: Create design tokens

**Files:**
- Create: `lib/design_system/tokens/app_colors.dart`
- Create: `lib/design_system/tokens/app_typography.dart`
- Create: `lib/design_system/tokens/app_spacing.dart`
- Create: `lib/design_system/tokens/app_radius.dart`
- Create: `lib/design_system/tokens/app_shadows.dart`

> Tokens são constantes puras — sem lógica, sem testes.

**Step 1: Create `lib/design_system/tokens/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background  = Color(0xFF0D0D0D);
  static const Color surface     = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF242424);

  static const Color purple300 = Color(0xFFC084FC);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple700 = Color(0xFF7E22CE);

  static const Color textPrimary   = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textDisabled  = Color(0xFF525252);

  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
}
```

**Step 2: Create `lib/design_system/tokens/app_typography.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/design_system/tokens/app_colors.dart';

abstract final class AppTypography {
  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}
```

**Step 3: Create `lib/design_system/tokens/app_spacing.dart`**

```dart
abstract final class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 48;
}
```

**Step 4: Create `lib/design_system/tokens/app_radius.dart`**

```dart
abstract final class AppRadius {
  static const double sm   = 4;
  static const double md   = 8;
  static const double lg   = 12;
  static const double xl   = 16;
  static const double full = 999;
}
```

**Step 5: Create `lib/design_system/tokens/app_shadows.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
```

**Step 6: Commit**

```bash
git add lib/design_system/tokens/
git commit -m "feat: add design system tokens (colors, typography, spacing, radius, shadows)"
```

---

## Task 2: Create BaseButton

**Files:**
- Create: `lib/design_system/components/button/base_button_variant.dart`
- Create: `lib/design_system/components/button/base_button.dart`
- Create: `test/design_system/components/button/base_button_test.dart`

**Step 1: Create `lib/design_system/components/button/base_button_variant.dart`**

```dart
enum BaseButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}
```

**Step 2: Write the failing test**

Create `test/design_system/components/button/base_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/design_system/components/button/base_button.dart';
import 'package:flutter_base_app/design_system/components/button/base_button_variant.dart';

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
  });
}
```

**Step 3: Run test to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/button/base_button_test.dart
```

Expected: FAIL — import error.

**Step 4: Create `lib/design_system/components/button/base_button.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/design_system/components/button/base_button_variant.dart';
import 'package:flutter_base_app/design_system/tokens/app_colors.dart';
import 'package:flutter_base_app/design_system/tokens/app_radius.dart';
import 'package:flutter_base_app/design_system/tokens/app_spacing.dart';
import 'package:flutter_base_app/design_system/tokens/app_typography.dart';

class BaseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BaseButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;

  const BaseButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BaseButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
  });

  bool get _isInteractive => !isDisabled && !isLoading;

  Color get _backgroundColor => switch (variant) {
        BaseButtonVariant.primary     => AppColors.purple500,
        BaseButtonVariant.secondary   => Colors.transparent,
        BaseButtonVariant.ghost       => Colors.transparent,
        BaseButtonVariant.destructive => AppColors.error,
      };

  Color get _foregroundColor => switch (variant) {
        BaseButtonVariant.primary     => AppColors.textPrimary,
        BaseButtonVariant.secondary   => AppColors.purple500,
        BaseButtonVariant.ghost       => AppColors.purple500,
        BaseButtonVariant.destructive => AppColors.textPrimary,
      };

  Border? get _border => variant == BaseButtonVariant.secondary
      ? Border.all(color: AppColors.purple500, width: 1.5)
      : null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: _isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: AppColors.purple300.withValues(alpha: 0.2),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              border: _border,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: isLoading ? _buildLoading() : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_foregroundColor),
        ),
      );

  Widget _buildContent() {
    final label = Text(
      this.label,
      style: AppTypography.bodyMd.copyWith(color: _foregroundColor),
    );

    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prefixIcon, color: _foregroundColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          label,
        ],
      );
    }

    return label;
  }
}
```

**Step 5: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/button/base_button_test.dart
```

Expected: All 7 tests PASS.

**Step 6: Commit**

```bash
git add lib/design_system/components/button/ test/design_system/components/button/
git commit -m "feat: add BaseButton with primary, secondary, ghost and destructive variants"
```

---

## Task 3: Create BaseInputField

**Files:**
- Create: `lib/design_system/components/input/base_input_field.dart`
- Create: `test/design_system/components/input/base_input_field_test.dart`

**Step 1: Write the failing test**

Create `test/design_system/components/input/base_input_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/design_system/components/input/base_input_field.dart';

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
  }) {
    return MaterialApp(
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

    testWidgets('is not enabled when isDisabled=true', (tester) async {
      await tester.pumpWidget(buildInput(isDisabled: true));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isFalse);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/input/base_input_field_test.dart
```

Expected: FAIL — import error.

**Step 3: Create `lib/design_system/components/input/base_input_field.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/design_system/tokens/app_colors.dart';
import 'package:flutter_base_app/design_system/tokens/app_radius.dart';
import 'package:flutter_base_app/design_system/tokens/app_spacing.dart';
import 'package:flutter_base_app/design_system/tokens/app_typography.dart';

class BaseInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isPassword;
  final bool isDisabled;
  final TextInputType keyboardType;

  const BaseInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.isDisabled = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<BaseInputField> createState() => _BaseInputFieldState();
}

class _BaseInputFieldState extends State<BaseInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodySm.copyWith(
            color: widget.isDisabled
                ? AppColors.textDisabled
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          enabled: !widget.isDisabled,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            filled: true,
            fillColor: widget.isDisabled
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.surface,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon,
                    color: AppColors.textSecondary, size: 20)
                : null,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.surfaceHigh),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.surfaceHigh),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.purple500,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.surfaceHigh),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, color: AppColors.textSecondary, size: 20);
    }
    return null;
  }
}
```

**Step 4: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/input/base_input_field_test.dart
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
git add lib/design_system/components/input/ test/design_system/components/input/
git commit -m "feat: add BaseInputField with label, error, password toggle and disabled state"
```

---

## Task 4: Create BaseCard

**Files:**
- Create: `lib/design_system/components/card/base_card.dart`
- Create: `test/design_system/components/card/base_card_test.dart`

**Step 1: Write the failing test**

Create `test/design_system/components/card/base_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_base_app/design_system/components/card/base_card.dart';

void main() {
  Widget buildCard({
    Widget? child,
    VoidCallback? onTap,
    bool elevated = false,
    double padding = 16,
  }) {
    return MaterialApp(
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

    testWidgets('renders without error when elevated=true', (tester) async {
      await tester.pumpWidget(buildCard(elevated: true));
      expect(find.byType(BaseCard), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/card/base_card_test.dart
```

Expected: FAIL — import error.

**Step 3: Create `lib/design_system/components/card/base_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/design_system/tokens/app_colors.dart';
import 'package:flutter_base_app/design_system/tokens/app_radius.dart';
import 'package:flutter_base_app/design_system/tokens/app_shadows.dart';
import 'package:flutter_base_app/design_system/tokens/app_spacing.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool elevated;
  final double padding;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevated = false,
    this.padding = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashColor: AppColors.purple300.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: elevated ? AppShadows.card : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
```

**Step 4: Run tests**

```bash
cd ~/Flutter Base App && flutter test test/design_system/components/card/base_card_test.dart
```

Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
git add lib/design_system/components/card/ test/design_system/components/card/
git commit -m "feat: add BaseCard with optional tap handler and elevated variant"
```

---

## Task 5: Create barrel file and run full suite

**Files:**
- Create: `lib/design_system/base_design_system.dart`

**Step 1: Create `lib/design_system/base_design_system.dart`**

```dart
// Tokens
export 'tokens/app_colors.dart';
export 'tokens/app_typography.dart';
export 'tokens/app_spacing.dart';
export 'tokens/app_radius.dart';
export 'tokens/app_shadows.dart';

// Components
export 'components/button/base_button.dart';
export 'components/button/base_button_variant.dart';
export 'components/input/base_input_field.dart';
export 'components/card/base_card.dart';
```

**Step 2: Update `lib/main.dart` to use the design system**

Replace contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_base_app/design_system/base_design_system.dart';

void main() {
  runApp(const Flutter Base AppApp());
}

class Flutter Base AppApp extends StatelessWidget {
  const Flutter Base AppApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Base App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple500,
          surface: AppColors.surface,
        ),
      ),
      home: const _DesignSystemShowcase(),
    );
  }
}

class _DesignSystemShowcase extends StatelessWidget {
  const _DesignSystemShowcase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design System', style: AppTypography.displayLg),
              const SizedBox(height: AppSpacing.xl),

              Text('Buttons', style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              BaseButton(label: 'Primary', onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(label: 'Secondary', onPressed: () {}, variant: BaseButtonVariant.secondary),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(label: 'Ghost', onPressed: () {}, variant: BaseButtonVariant.ghost),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(label: 'Destructive', onPressed: () {}, variant: BaseButtonVariant.destructive),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(label: 'Loading', onPressed: () {}, isLoading: true),
              const SizedBox(height: AppSpacing.sm),
              BaseButton(label: 'Disabled', onPressed: () {}, isDisabled: true),
              const SizedBox(height: AppSpacing.xl),

              Text('Inputs', style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              const BaseInputField(label: 'E-mail', hint: 'seu@email.com', prefixIcon: Icons.email_outlined),
              const SizedBox(height: AppSpacing.md),
              const BaseInputField(label: 'Senha', isPassword: true),
              const SizedBox(height: AppSpacing.md),
              const BaseInputField(label: 'Com erro', errorText: 'Campo obrigatório'),
              const SizedBox(height: AppSpacing.md),
              const BaseInputField(label: 'Desabilitado', isDisabled: true),
              const SizedBox(height: AppSpacing.xl),

              Text('Cards', style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              BaseCard(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treino A', style: AppTypography.headingMd),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Peito · Ombro · Tríceps', style: AppTypography.bodySm),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BaseCard(
                elevated: true,
                child: Text('Card elevado', style: AppTypography.bodyMd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Run full test suite**

```bash
cd ~/Flutter Base App && flutter test
```

Expected: All tests PASS.

**Step 4: Run flutter analyze**

```bash
cd ~/Flutter Base App && flutter analyze
```

Expected: `No issues found!`

**Step 5: Commit**

```bash
git add lib/design_system/base_design_system.dart lib/main.dart
git commit -m "feat: add design system barrel file and update main.dart with showcase"
```
