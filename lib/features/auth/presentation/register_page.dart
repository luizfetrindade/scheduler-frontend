import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
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
              return _MobileRegister(
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                onSubmit: _submit,
              );
            }
            return _DesktopRegister(
              nameController: _nameController,
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

// ─── Mobile layout ──────────────────────────────────────────────────────────

class _MobileRegister extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _MobileRegister({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxxl),
            Text(context.l10n.registerTitle, style: AppTypography.displayLg),
            const SizedBox(height: AppSpacing.xl),
            _RegisterForm(
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              onSubmit: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop layout ─────────────────────────────────────────────────────────

class _DesktopRegister extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _DesktopRegister({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left panel: branding ──
        Expanded(
          child: Container(
            color: context.appColors.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.appColors.primaryDark,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: context.appColors.textPrimary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Scheduler',
                      style: AppTypography.displayLg.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gerencie seus agendamentos\nde forma simples e eficiente.',
                      style: AppTypography.bodyMd.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Right panel: form ──
        Expanded(
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
                      context.l10n.registerTitle,
                      style: AppTypography.displayLg,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Preencha os dados para criar sua conta.',
                      style: AppTypography.bodyMd.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _RegisterForm(
                      nameController: nameController,
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
      ],
    );
  }
}

// ─── Shared form ────────────────────────────────────────────────────────────

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _RegisterForm({
    required this.nameController,
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
          label: context.l10n.registerNameLabel,
          controller: nameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
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
            label: context.l10n.registerButton,
            isLoading: state is AuthLoading,
            onPressed: state is AuthLoading ? null : onSubmit,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(
              context.l10n.registerHaveAccount,
              style: AppTypography.bodySm.copyWith(color: context.appColors.primaryLight),
            ),
          ),
        ),
      ],
    );
  }
}
