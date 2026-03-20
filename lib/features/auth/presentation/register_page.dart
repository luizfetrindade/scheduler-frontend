import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/core/utils/phone_formatter.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  int _step = 0;
  Map<String, String?> _errors = {};

  // Captured from AuthTotpSetupReady — kept in memory only, never persisted.
  String? _tempToken;
  String? _qrCodeUrl;
  String? _secret;

  static const _kBreakpoint = 720.0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validateProfileFields() {
    final errors = <String, String?>{};

    final name = _nameController.text.trim();
    if (name.isEmpty) errors['name'] = 'Nome é obrigatório';

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      errors['email'] = 'E-mail é obrigatório';
    } else if (!emailRegex.hasMatch(email)) {
      errors['email'] = 'Informe um e-mail válido';
    }

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      errors['phone'] = 'Telefone é obrigatório';
    } else if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      errors['phone'] = 'Informe um telefone válido com DDD';
    }

    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _submitProfile() {
    if (!_validateProfileFields()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
  }

  void _confirmTotp(String code) {
    if (_tempToken == null) return;
    context.read<AuthBloc>().add(
          AuthTotpSetupConfirmed(tempToken: _tempToken!, code: code),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthTotpSetupReady) {
            setState(() {
              _tempToken = state.tempToken;
              _qrCodeUrl = state.qrCodeUrl;
              _secret = state.secret;
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
          final hasOtpError = state is AuthError && _step == 2;

          final formWidget = AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: switch (_step) {
              0 => _ProfileStep(
                  key: const ValueKey(0),
                  nameController: _nameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  errors: _errors,
                  isLoading: isLoading,
                  onSubmit: _submitProfile,
                ),
              1 => _QrStep(
                  key: const ValueKey(1),
                  qrCodeUrl: _qrCodeUrl ?? '',
                  secret: _secret ?? '',
                  onContinue: () => setState(() => _step = 2),
                ),
              _ => _ConfirmTotpStep(
                  key: const ValueKey(2),
                  otpController: _otpController,
                  isLoading: isLoading,
                  hasError: hasOtpError,
                  onCompleted: _confirmTotp,
                  onSubmit: () => _confirmTotp(_otpController.text),
                  onBack: () {
                    _otpController.clear();
                    setState(() => _step = 1);
                  },
                ),
            },
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _kBreakpoint) {
                return _MobileRegister(formWidget: formWidget, step: _step);
              }
              return _DesktopRegister(formWidget: formWidget, step: _step);
            },
          );
        },
      ),
    );
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileRegister extends StatelessWidget {
  final Widget formWidget;
  final int step;

  const _MobileRegister({required this.formWidget, required this.step});

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
                    'Crie sua conta e comece\na gerenciar seus agendamentos.',
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

class _DesktopRegister extends StatelessWidget {
  final Widget formWidget;
  final int step;

  const _DesktopRegister({required this.formWidget, required this.step});

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
                  'Crie sua conta e comece\na gerenciar seus agendamentos.',
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
    final (title, subtitle) = switch (step) {
      0 => (
          context.l10n.registerTitle,
          'Preencha os dados para criar sua conta.',
        ),
      1 => (
          context.l10n.registerQrTitle,
          context.l10n.registerQrInstruction,
        ),
      _ => (
          context.l10n.registerConfirmTitle,
          context.l10n.registerConfirmInstruction,
        ),
    };

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
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ─── Step 0: profile fields ───────────────────────────────────────────────────

class _ProfileStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Map<String, String?> errors;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _ProfileStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.errors,
    required this.isLoading,
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
          errorText: errors['name'],
        ),
        const SizedBox(height: AppSpacing.md),
        BaseInputField(
          label: context.l10n.loginEmailLabel,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          errorText: errors['email'],
        ),
        const SizedBox(height: AppSpacing.md),
        BaseInputField(
          label: 'Telefone celular',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          inputFormatters: [PhoneInputFormatter()],
          errorText: errors['phone'],
        ),
        const SizedBox(height: AppSpacing.xl),
        BaseButton(
          label: context.l10n.registerButton,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.md),
        _OrDivider(),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: context.l10n.registerHaveAccount,
          variant: BaseButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}

// ─── Step 1: QR code scan ─────────────────────────────────────────────────────

class _QrStep extends StatefulWidget {
  final String qrCodeUrl;
  final String secret;
  final VoidCallback onContinue;

  const _QrStep({
    super.key,
    required this.qrCodeUrl,
    required this.secret,
    required this.onContinue,
  });

  @override
  State<_QrStep> createState() => _QrStepState();
}

class _QrStepState extends State<_QrStep> {
  bool _showManual = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BaseCard(
            padding: AppSpacing.xl,
            child: QrImageView(
              data: widget.qrCodeUrl,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () => setState(() => _showManual = !_showManual),
          child: Row(
            children: [
              Text(
                context.l10n.registerManualEntry,
                style: AppTypography.bodySm.copyWith(
                  color: context.appColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                _showManual ? Icons.expand_less : Icons.expand_more,
                color: context.appColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
        if (_showManual) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.registerManualSecretLabel,
            style: AppTypography.caption.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: context.appColors.surface,
            child: Text(
              widget.secret,
              style: AppTypography.bodyMd.copyWith(
                color: context.appColors.textPrimary,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        BaseButton(
          label: context.l10n.registerContinueAfterQr,
          onPressed: widget.onContinue,
        ),
      ],
    );
  }
}

// ─── Step 2: confirm TOTP ─────────────────────────────────────────────────────

class _ConfirmTotpStep extends StatelessWidget {
  final TextEditingController otpController;
  final bool isLoading;
  final bool hasError;
  final void Function(String) onCompleted;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ConfirmTotpStep({
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
          label: context.l10n.registerConfirmButton,
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.sm),
        BaseButton(
          label: context.l10n.registerBackButton,
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
