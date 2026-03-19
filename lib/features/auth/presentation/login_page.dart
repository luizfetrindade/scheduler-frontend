import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _kBreakpoint) {
              return _MobileLogin(
                emailController: _emailController,
                passwordController: _passwordController,
                onSubmit: _submit,
              );
            }
            return _DesktopLogin(
              emailController: _emailController,
              passwordController: _passwordController,
              onSubmit: _submit,
            );
          },
        ),
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileLogin extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _MobileLogin({
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header band ──
            Container(
              color: context.appColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppMark(
                    iconColor: context.appColors.background,
                    iconBg: context.appColors.background.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Scheduler',
                    style: AppTypography.displayLg.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Gerencie agendamentos\nde forma simples e eficiente.',
                    style: AppTypography.bodySm.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            // ── Form ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.loginTitle,
                    style: AppTypography.headingMd.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Entre com suas credenciais para continuar.',
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _LoginForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    onSubmit: onSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop layout ───────────────────────────────────────────────────────────

class _DesktopLogin extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _DesktopLogin({
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left: brand panel ──
        SizedBox(
          width: 420,
          child: Container(
            color: context.appColors.primary,
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppMark(
                  iconColor: context.appColors.background,
                  iconBg: context.appColors.background.withValues(alpha: 0.15),
                ),
                const Spacer(),
                Text(
                  'Scheduler',
                  style: AppTypography.displayLg.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 40,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 32,
                  height: 2,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gerencie seus agendamentos\nde forma simples e eficiente.',
                  style: AppTypography.bodyMd.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.65),
                    height: 1.7,
                  ),
                ),
                const Spacer(),
                // ── bottom accent strip ──
                Row(
                  children: List.generate(
                    4,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: i == 0 ? 0.8 : 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Right: form panel ──
        Expanded(
          child: Container(
            color: context.appColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.loginTitle,
                        style: AppTypography.displayLg.copyWith(
                          color: context.appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Entre com suas credenciais para continuar.',
                        style: AppTypography.bodyMd.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _LoginForm(
                        emailController: emailController,
                        passwordController: passwordController,
                        onSubmit: onSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── App mark (logo icon) ─────────────────────────────────────────────────────

class _AppMark extends StatelessWidget {
  final Color iconColor;
  final Color iconBg;

  const _AppMark({required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: iconBg,
      child: Icon(
        Icons.calendar_today_outlined,
        color: iconColor,
        size: 22,
      ),
    );
  }
}

// ─── Shared form ──────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BaseInputField(
          label: context.l10n.loginEmailLabel,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        BaseInputField(
          label: context.l10n.loginPasswordLabel,
          controller: passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => BaseButton(
            label: context.l10n.loginButton,
            isLoading: state is AuthLoading,
            onPressed: state is AuthLoading ? null : onSubmit,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // ── divider + link ──
        Row(
          children: [
            Expanded(
              child: Divider(
                color: context.appColors.outline,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'ou',
                style: AppTypography.caption.copyWith(
                  color: context.appColors.textDisabled,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: context.appColors.outline,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.register),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.appColors.textPrimary,
            side: BorderSide(color: context.appColors.outline, width: 1.5),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            minimumSize: const Size.fromHeight(56),
            textStyle: AppTypography.bodySm,
          ),
          child: Text(context.l10n.loginNoAccount),
        ),
      ],
    );
  }
}
