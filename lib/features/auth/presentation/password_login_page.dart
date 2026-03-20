import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class PasswordLoginPage extends StatefulWidget {
  final String email;

  const PasswordLoginPage({super.key, required this.email});

  @override
  State<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends State<PasswordLoginPage> {
  final _passwordController = TextEditingController();

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    context.read<AuthBloc>().add(
          AuthPasswordLoginRequested(
            email: widget.email,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
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
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          final formWidget = _PasswordForm(
            email: widget.email,
            passwordController: _passwordController,
            isLoading: isLoading,
            onSubmit: _submit,
            onForgotPassword: () => context.push('/forgot-password'),
            onBack: () => context.pop(),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _kBreakpoint) {
                return _MobilePasswordLayout(formWidget: formWidget);
              }
              return _DesktopPasswordLayout(formWidget: formWidget);
            },
          );
        },
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobilePasswordLayout extends StatelessWidget {
  final Widget formWidget;

  const _MobilePasswordLayout({required this.formWidget});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const _PasswordStepHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  formWidget,
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

class _DesktopPasswordLayout extends StatelessWidget {
  final Widget formWidget;

  const _DesktopPasswordLayout({required this.formWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
                      const _PasswordStepHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      formWidget,
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

// ─── Step header ──────────────────────────────────────────────────────────────

class _PasswordStepHeader extends StatelessWidget {
  const _PasswordStepHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrar com senha',
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Insira sua senha para continuar.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Password form ────────────────────────────────────────────────────────────

class _PasswordForm extends StatelessWidget {
  final String email;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;

  const _PasswordForm({
    required this.email,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          email,
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BaseInputField(
          label: 'Senha',
          controller: passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: Text(
              'Esqueceu a senha?',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: 'Entrar',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.sm),
        BaseButton(
          label: 'Voltar',
          variant: BaseButtonVariant.ghost,
          onPressed: isLoading ? null : onBack,
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

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
