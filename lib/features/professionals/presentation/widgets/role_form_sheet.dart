import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';

class RoleFormSheet extends StatefulWidget {
  /// If non-null, edit mode — pre-fills name field.
  final ProfessionalRoleModel? role;

  const RoleFormSheet({super.key, this.role});

  @override
  State<RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends State<RoleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _wasSubmitting = false;

  bool get _isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfessionalRolesBloc, ProfessionalRolesState>(
      listener: (context, state) {
        if (state is ProfessionalRolesActionInProgress) {
          _wasSubmitting = true;
        } else if (state is ProfessionalRolesLoaded && _wasSubmitting) {
          Navigator.of(context).pop();
        } else if (state is ProfessionalRolesError && _wasSubmitting) {
          _wasSubmitting = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  color: context.appColors.outline,
                ),
              ),

              // ── Title ──
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    color: context.appColors.primary.withValues(alpha: 0.08),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_outlined
                          : Icons.work_outline,
                      size: 16,
                      color: context.appColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar cargo' : 'Novo cargo',
                    style: AppTypography.headingMd.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Nome do cargo ──
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _inputDecoration(context, 'Nome do cargo *'),
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textPrimary),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                  if (v.trim().length > 50) return 'Máximo 50 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Actions ──
              BlocBuilder<ProfessionalRolesBloc, ProfessionalRolesState>(
                builder: (context, state) {
                  final isLoading =
                      state is ProfessionalRolesActionInProgress;
                  return Row(
                    children: [
                      Expanded(
                        child: BaseButton(
                          label: 'Cancelar',
                          variant: BaseButtonVariant.secondary,
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: BaseButton(
                          label: 'Salvar',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    final businessId = businessState.active.id;
    final name = _nameCtrl.text.trim();

    if (_isEditing) {
      context
          .read<ProfessionalRolesBloc>()
          .add(ProfessionalRolesUpdateRequested(
            businessId: businessId,
            roleId: widget.role!.id,
            name: name,
          ));
    } else {
      context
          .read<ProfessionalRolesBloc>()
          .add(ProfessionalRolesCreateRequested(
            businessId: businessId,
            name: name,
          ));
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
        floatingLabelStyle: AppTypography.caption
            .copyWith(color: context.appColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: context.appColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: context.appColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: context.appColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      );
}
