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
  final _otpController = TextEditingController();

  int _step = 0;
  String? _emailForTotp;

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    context.read<AuthBloc>().add(AuthEmailSubmitted(email: email));
  }

  void _submitTotp(String code) {
    if (_emailForTotp == null) return;
    context.read<AuthBloc>().add(
          AuthTotpLoginSubmitted(email: _emailForTotp!, code: code),
        );
  }

  void _goBack() {
    _otpController.clear();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthTotpChallengeReady) {
            setState(() {
              _emailForTotp = state.email;
              _step = 1;
            });
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

          final formWidget = AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _step == 0
                ? _EmailStep(
                    key: const ValueKey(0),
                    emailController: _emailController,
                    isLoading: isLoading,
                    onSubmit: _submitEmail,
                  )
                : _TotpStep(
                    key: const ValueKey(1),
                    email: _emailForTotp ?? '',
                    otpController: _otpController,
                    isLoading: isLoading,
                    hasError: hasOtpError,
                    onCompleted: _submitTotp,
                    onSubmit: () => _submitTotp(_otpController.text),
                    onBack: _goBack,
                  ),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _kBreakpoint) {
                return _MobileLogin(formWidget: formWidget, step: _step);
              }
              return _DesktopLogin(formWidget: formWidget, step: _step);
            },
          );
        },
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileLogin extends StatelessWidget {
  final Widget formWidget;
  final int step;

  const _MobileLogin({required this.formWidget, required this.step});

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
                  _StepHeader(step: step),
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

class _DesktopLogin extends StatelessWidget {
  final Widget formWidget;
  final int step;

  const _DesktopLogin({required this.formWidget, required this.step});

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
                      _StepHeader(step: step),
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

class _StepHeader extends StatelessWidget {
  final int step;
  const _StepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final title = step == 0
        ? context.l10n.loginTitle
        : context.l10n.loginTotpTitle;
    final subtitle = step == 0
        ? 'Informe seu e-mail para continuar.'
        : 'Use o Google Authenticator para confirmar sua identidade.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Step 0: email ────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailStep({
    super.key,
    required this.emailController,
    required this.isLoading,
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
        const SizedBox(height: AppSpacing.xl),
        BaseButton(
          label: context.l10n.loginContinueButton,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.md),
        _OrDivider(),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: context.l10n.loginNoAccount,
          variant: BaseButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.register),
        ),
      ],
    );
  }
}

// ─── Step 1: TOTP code ────────────────────────────────────────────────────────

class _TotpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final bool isLoading;
  final bool hasError;
  final void Function(String) onCompleted;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _TotpStep({
    super.key,
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

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: context.appColors.outline, thickness: 1),
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
          child: Divider(color: context.appColors.outline, thickness: 1),
        ),
      ],
    );
  }
}
