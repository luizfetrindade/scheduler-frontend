import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class TotpLoginPage extends StatefulWidget {
  final String email;
  final bool rememberMe;

  const TotpLoginPage({
    super.key,
    required this.email,
    required this.rememberMe,
  });

  @override
  State<TotpLoginPage> createState() => _TotpLoginPageState();
}

class _TotpLoginPageState extends State<TotpLoginPage> {
  final _otpController = TextEditingController();

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp(String code) {
    context.read<AuthBloc>().add(
          AuthOtpLoginSubmitted(
            email: widget.email,
            code: code,
            rememberMe: widget.rememberMe,
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
          final hasError = state is AuthError;

          final formWidget = _OtpStep(
            email: widget.email,
            otpController: _otpController,
            isLoading: isLoading,
            hasError: hasError,
            onCompleted: _submitOtp,
            onSubmit: () => _submitOtp(_otpController.text),
            onBack: () => context.pop(),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _kBreakpoint) {
                return _MobileOtpLayout(formWidget: formWidget);
              }
              return _DesktopOtpLayout(formWidget: formWidget);
            },
          );
        },
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileOtpLayout extends StatelessWidget {
  final Widget formWidget;

  const _MobileOtpLayout({required this.formWidget});

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
                  _OtpStepHeader(),
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

class _DesktopOtpLayout extends StatelessWidget {
  final Widget formWidget;

  const _DesktopOtpLayout({required this.formWidget});

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
                      _OtpStepHeader(),
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

class _OtpStepHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.loginTotpTitle,
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Verifique seu e-mail e insira o código de 6 dígitos.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── OTP step form ────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final bool isLoading;
  final bool hasError;
  final void Function(String) onCompleted;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _OtpStep({
    required this.email,
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
          context.l10n.loginTotpInstruction(email),
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
          label: context.l10n.loginButton,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.sm),
        BaseButton(
          label: context.l10n.loginBackButton,
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
