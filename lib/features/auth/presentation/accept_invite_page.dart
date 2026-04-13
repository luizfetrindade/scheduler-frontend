import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class AcceptInvitePage extends StatefulWidget {
  final String token;

  const AcceptInvitePage({super.key, required this.token});

  @override
  State<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends State<AcceptInvitePage> {
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AuthBloc>().add(
          AuthAcceptInviteRequested(token: widget.token, name: name),
        );
  }

  void _confirmOtp(String code) {
    context.read<AuthBloc>().add(
          AuthAcceptInviteOtpConfirmed(token: widget.token, code: code),
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
          if (state is AuthInviteOtpSent) {
            setState(() => _step = 1);
          }
          if (state is AuthInviteAccepted) {
            context.go(AppRoutes.home);
          }
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
          final hasOtpError = state is AuthError && _step == 1;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: switch (_step) {
                      0 => _NameStep(
                          key: const ValueKey(0),
                          nameController: _nameController,
                          isLoading: isLoading,
                          onSubmit: _submitName,
                        ),
                      _ => _OtpStep(
                          key: const ValueKey(1),
                          otpController: _otpController,
                          isLoading: isLoading,
                          hasError: hasOtpError,
                          onCompleted: _confirmOtp,
                          onSubmit: () => _confirmOtp(_otpController.text),
                          onBack: () {
                            _otpController.clear();
                            setState(() => _step = 0);
                          },
                        ),
                    },
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

// ─── Step 0: name entry ───────────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  final TextEditingController nameController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _NameStep({
    super.key,
    required this.nameController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informe seu nome para ativar a conta.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BaseInputField(
          label: 'Nome completo',
          controller: nameController,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: AppSpacing.xl),
        BaseButton(
          label: 'Continuar',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
      ],
    );
  }
}

// ─── Step 1: OTP confirmation ─────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final TextEditingController otpController;
  final bool isLoading;
  final bool hasError;
  final void Function(String) onCompleted;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _OtpStep({
    super.key,
    required this.otpController,
    required this.isLoading,
    required this.hasError,
    required this.onCompleted,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enviamos um código de 6 dígitos para o e-mail do convite. Insira-o abaixo para ativar sua conta.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: OtpInputField(
            controller: otpController,
            hasError: hasError,
            isDisabled: isLoading,
            onCompleted: onCompleted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BaseButton(
          label: 'Ativar conta',
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
