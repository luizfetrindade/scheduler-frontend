import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_event.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/profile/bloc/profile_bloc.dart';
import 'package:scheduler_frontend/features/profile/bloc/profile_event.dart';
import 'package:scheduler_frontend/features/profile/bloc/profile_state.dart';

/// Profile editing content — user data + business name.
///
/// Wrap with [ProfileBlocListener] so that snackbars and data refreshes
/// fire after each successful update.
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _UserSection(),
        const SizedBox(height: AppSpacing.xl),
        _BusinessSection(),
      ],
    );
  }
}

/// Handles [ProfileBloc] state side-effects: snackbars + data refresh.
///
/// Wrap [ProfileBody] (or its ancestor) with this listener.
class ProfileBlocListener extends StatelessWidget {
  final Widget child;
  const ProfileBlocListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileNameUpdated ||
            state is ProfilePhoneUpdated ||
            state is ProfileEmailUpdated) {
          context.read<AuthBloc>().add(const AuthUserRefreshRequested());
        }
        if (state is ProfileBusinessNameUpdated) {
          context.read<BusinessBloc>().add(const BusinessLoadRequested());
        }
        if (state is ProfileNameUpdated) {
          _showSnackBar(context, 'Nome atualizado com sucesso');
        }
        if (state is ProfilePhoneUpdated) {
          _showSnackBar(context, 'Telefone atualizado com sucesso');
        }
        if (state is ProfileEmailUpdated) {
          _showSnackBar(context, 'E-mail atualizado com sucesso');
        }
        if (state is ProfileBusinessNameUpdated) {
          _showSnackBar(context, 'Nome do estabelecimento atualizado');
        }
        if (state is ProfileError) {
          _showSnackBar(context, state.message, isError: true);
          context.read<ProfileBloc>().add(const ProfileReset());
        }
      },
      child: child,
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : context.appColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── User section ──────────────────────────────────────────────────────────────

class _UserSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();
        final user = authState.user;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: 'Dados pessoais'),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              icon: Icons.person_outline,
              label: 'Nome',
              value: user.name,
              onEdit: () => _showEditNameSheet(context, user.name),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ProfileField(
              icon: Icons.email_outlined,
              label: 'E-mail',
              value: user.email,
              onEdit: () => _showEditEmailSheet(context, user.email),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ProfileField(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: user.phone ?? 'Não informado',
              onEdit: () => _showEditPhoneSheet(context, user.phone ?? ''),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameSheet(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _EditFieldSheet(
          title: 'Editar nome',
          label: 'Nome completo',
          initialValue: current,
          keyboardType: TextInputType.name,
          validator: (v) {
            if (v == null || v.trim().length < 2) {
              return 'Nome deve ter ao menos 2 caracteres';
            }
            return null;
          },
          onSave: (value) => context
              .read<ProfileBloc>()
              .add(ProfileUpdateNameRequested(value.trim())),
        ),
      ),
    );
  }

  void _showEditEmailSheet(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _EditEmailSheet(currentEmail: current),
      ),
    );
  }

  void _showEditPhoneSheet(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _EditFieldSheet(
          title: 'Editar telefone',
          label: 'Telefone',
          initialValue: current,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().length < 10) {
              return 'Telefone deve ter ao menos 10 dígitos';
            }
            return null;
          },
          onSave: (value) => context
              .read<ProfileBloc>()
              .add(ProfileUpdatePhoneRequested(value.trim())),
        ),
      ),
    );
  }
}

// ── Business section ──────────────────────────────────────────────────────────

class _BusinessSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state is! BusinessLoaded) return const SizedBox.shrink();
        if (!state.policy.isAdmin) return const SizedBox.shrink();
        final business = state.active;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: 'Estabelecimento'),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              icon: Icons.store_outlined,
              label: 'Nome do estabelecimento',
              value: business.name,
              onEdit: () => _showEditBusinessNameSheet(
                  context, business.id, business.name),
            ),
          ],
        );
      },
    );
  }

  void _showEditBusinessNameSheet(
      BuildContext context, String businessId, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: _EditFieldSheet(
          title: 'Editar nome do estabelecimento',
          label: 'Nome',
          initialValue: current,
          keyboardType: TextInputType.text,
          validator: (v) {
            if (v == null || v.trim().length < 2) {
              return 'Nome deve ter ao menos 2 caracteres';
            }
            return null;
          },
          onSave: (value) => context.read<ProfileBloc>().add(
                ProfileUpdateBusinessNameRequested(
                  businessId: businessId,
                  name: value.trim(),
                ),
              ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelLarge
          .copyWith(color: context.appColors.textSecondary),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(),
      leading: Icon(icon, color: context.appColors.primary),
      title: Text(
        label,
        style: AppTypography.caption
            .copyWith(color: context.appColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style:
            AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
      ),
      trailing: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return Icon(Icons.edit_outlined,
              size: 18, color: context.appColors.textSecondary);
        },
      ),
      onTap: onEdit,
    );
  }
}

// ── Generic edit sheet ────────────────────────────────────────────────────────

class _EditFieldSheet extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final void Function(String value) onSave;

  const _EditFieldSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.keyboardType,
    required this.validator,
    required this.onSave,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileNameUpdated ||
            state is ProfilePhoneUpdated ||
            state is ProfileBusinessNameUpdated ||
            state is ProfileError) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: AppTypography.headingMd
                    .copyWith(color: context.appColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                autofocus: true,
                validator: widget.validator,
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: widget.label,
                  labelStyle: AppTypography.caption
                      .copyWith(color: context.appColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide:
                        BorderSide(color: context.appColors.textSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide:
                        BorderSide(color: context.appColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final isLoading = state is ProfileLoading;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      foregroundColor: context.appColors.background,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              widget.onSave(_controller.text);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Salvar', style: AppTypography.labelLarge),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email change sheet (2-step) ────────────────────────────────────────────────

class _EditEmailSheet extends StatefulWidget {
  final String currentEmail;
  const _EditEmailSheet({required this.currentEmail});

  @override
  State<_EditEmailSheet> createState() => _EditEmailSheetState();
}

class _EditEmailSheetState extends State<_EditEmailSheet> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  String? _pendingEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileEmailOtpSent) {
          setState(() => _pendingEmail = state.newEmail);
        }
        // Fecha o sheet só no sucesso ou se o erro for na etapa do email
        // (antes do OTP ser enviado). Na etapa do OTP o usuário pode tentar novamente.
        if (state is ProfileEmailUpdated) {
          Navigator.of(context).pop();
        }
        if (state is ProfileError && _pendingEmail == null) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        final isOtpStep = _pendingEmail != null;

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: isOtpStep
              ? _buildOtpStep(context, isLoading)
              : _buildEmailStep(context, isLoading),
        );
      },
    );
  }

  Widget _buildEmailStep(BuildContext context, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alterar e-mail',
            style: AppTypography.headingMd
                .copyWith(color: context.appColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Insira o novo e-mail. Enviaremos um código de verificação.',
            style: AppTypography.caption
                .copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.textPrimary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
              if (!v.contains('@')) return 'E-mail inválido';
              if (v.trim() == widget.currentEmail) {
                return 'Novo e-mail deve ser diferente do atual';
              }
              return null;
            },
            decoration: _inputDecoration(context, 'Novo e-mail'),
          ),
          const SizedBox(height: AppSpacing.md),
          _SaveButton(
            isLoading: isLoading,
            label: 'Enviar código',
            onPressed: () {
              if (_emailFormKey.currentState?.validate() ?? false) {
                context.read<ProfileBloc>().add(
                      ProfileChangeEmailRequested(
                          _emailController.text.trim()),
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context, bool isLoading) {
    return Form(
      key: _codeFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirmar novo e-mail',
            style: AppTypography.headingMd
                .copyWith(color: context.appColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enviamos um código de 6 dígitos para $_pendingEmail.',
            style: AppTypography.caption
                .copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 6,
            style: AppTypography.bodySm
                .copyWith(color: context.appColors.textPrimary),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'O código deve ter 6 dígitos';
              }
              return null;
            },
            decoration: _inputDecoration(context, 'Código de verificação'),
          ),
          const SizedBox(height: AppSpacing.md),
          _SaveButton(
            isLoading: isLoading,
            label: 'Confirmar',
            onPressed: () {
              if (_codeFormKey.currentState?.validate() ?? false) {
                context.read<ProfileBloc>().add(
                      ProfileConfirmEmailChangeRequested(
                          _codeController.text.trim()),
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.caption
          .copyWith(color: context.appColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: context.appColors.textSecondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: context.appColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error, width: 2),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.background,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label, style: AppTypography.labelLarge),
    );
  }
}
