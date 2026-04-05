import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/core/utils/password_strength.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class AcceptInvitePage extends StatefulWidget {
  final String token;

  const AcceptInvitePage({super.key, required this.token});

  @override
  State<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends State<AcceptInvitePage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _validationError;
  String _passwordValue = '';

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty || password.isEmpty || confirm.isEmpty) return;

    if (!PasswordStrength.isStrong(password)) {
      setState(() => _validationError = 'A senha não atende aos requisitos mínimos.');
      return;
    }

    if (password != confirm) {
      setState(() => _validationError = 'As senhas não coincidem.');
      return;
    }

    setState(() => _validationError = null);
    context.read<AuthBloc>().add(
          AuthAcceptInviteRequested(
            token: widget.token,
            name: name,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return const Scaffold(
        body: _ErrorView(
          message: 'Link inválido. Solicite um novo convite ao administrador.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Aceitar convite',
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInviteAccepted) {
            context.go(AppRoutes.home);
          }
        },
        builder: (context, state) {
          if (state is AuthError) {
            return _ErrorView(message: state.message);
          }

          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Preencha seus dados para ativar sua conta.',
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BaseInputField(
                    label: 'Nome completo',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BaseInputField(
                    label: 'Senha',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    onChanged: (v) => setState(() => _passwordValue = v),
                  ),
                  PasswordStrengthIndicator(password: _passwordValue),
                  const SizedBox(height: AppSpacing.md),
                  BaseInputField(
                    label: 'Confirmar senha',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _validationError!,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  BaseButton(
                    label: 'Ativar conta',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}
