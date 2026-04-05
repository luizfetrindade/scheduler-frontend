import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';

final _hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

const _kPresetColors = [
  '#3D3935', // Charcoal (brand)
  '#4A90E2', // Blue
  '#7ED321', // Green
  '#F5A623', // Amber
  '#D0021B', // Red
  '#9B59B6', // Purple
  '#1ABC9C', // Teal
  '#E74C3C', // Coral
  '#27AE60', // Emerald
  '#F39C12', // Orange
];

class ProfessionalFormSheet extends StatefulWidget {
  final ProfessionalModel? professional;

  const ProfessionalFormSheet({super.key, this.professional});

  @override
  State<ProfessionalFormSheet> createState() =>
      _ProfessionalFormSheetState();
}

class _ProfessionalFormSheetState extends State<ProfessionalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _colorCtrl;

  String? _selectedRoleId;
  bool _wasSubmitting = false;
  bool _wasCreatingRole = false;
  Set<String> _previousRoleIds = {};

  bool get _isEditing => widget.professional != null;

  @override
  void initState() {
    super.initState();
    final p = widget.professional;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _colorCtrl = TextEditingController(text: p?.color ?? '#4A90E2');
    _selectedRoleId = p?.roleId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfessionalRolesBloc, ProfessionalRolesState>(
      listener: (context, state) {
        if (state is ProfessionalRolesLoaded && _wasCreatingRole) {
          final newRole = state.roles
              .where((r) => !_previousRoleIds.contains(r.id))
              .firstOrNull;
          if (newRole != null) {
            setState(() {
              _selectedRoleId = newRole.id;
              _wasCreatingRole = false;
            });
          }
        }
      },
      child: BlocListener<ProfessionalsBloc, ProfessionalsState>(
        listener: (context, state) {
          if (state is ProfessionalsActionInProgress) {
            _wasSubmitting = true;
          } else if (state is ProfessionalsLoaded && _wasSubmitting) {
            Navigator.of(context).pop();
          } else if (state is ProfessionalsError && _wasSubmitting) {
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
            child: SingleChildScrollView(
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
                        color: context.appColors.primary
                            .withValues(alpha: 0.08),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_outlined
                              : Icons.person_add_outlined,
                          size: 16,
                          color: context.appColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isEditing
                            ? 'Editar profissional'
                            : 'Novo profissional',
                        style: AppTypography.headingMd.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      _isEditing
                          ? 'Atualize os dados do profissional.'
                          : 'Preencha os dados para adicionar à equipe.',
                      style: AppTypography.bodySm.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Nome ──
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration(context, 'Nome *'),
                    style: AppTypography.bodySm
                        .copyWith(color: context.appColors.textPrimary),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Cargo ──
                  _buildRoleDropdown(context),
                  const SizedBox(height: AppSpacing.md),

                  // ── Telefone ──
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration:
                        _inputDecoration(context, 'Telefone (opcional)'),
                    keyboardType: TextInputType.phone,
                    style: AppTypography.bodySm
                        .copyWith(color: context.appColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Bio ──
                  TextFormField(
                    controller: _bioCtrl,
                    decoration:
                        _inputDecoration(context, 'Bio (opcional)'),
                    maxLines: 3,
                    style: AppTypography.bodySm
                        .copyWith(color: context.appColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Cor ──
                  _buildColorField(context),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Submit ──
                  BlocBuilder<ProfessionalsBloc, ProfessionalsState>(
                    builder: (context, state) {
                      final isLoading =
                          state is ProfessionalsActionInProgress;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BaseButton(
                            label: _isEditing
                                ? 'Salvar alterações'
                                : 'Criar profissional',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          BaseButton(
                            label: 'Cancelar',
                            variant: BaseButtonVariant.secondary,
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Color field with live preview + presets ────────────────────────────────

  Widget _buildColorField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _colorCtrl,
                decoration:
                    _inputDecoration(context, 'Cor no calendário (ex: #4A90E2)'),
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textPrimary),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || !_hexColorRegex.hasMatch(v.trim())) {
                    return 'Use o formato #RRGGBB (ex: #4A90E2)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Live preview swatch
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _colorCtrl,
              builder: (context, value, _) {
                final hex = value.text.trim();
                Color? previewColor;
                if (_hexColorRegex.hasMatch(hex)) {
                  previewColor = Color(int.parse(
                      'FF${hex.replaceAll('#', '')}',
                      radix: 16));
                }
                return Container(
                  width: 52,
                  height: 52,
                  color: previewColor ?? context.appColors.surfaceHigh,
                  child: previewColor == null
                      ? Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: context.appColors.textDisabled,
                        )
                      : null,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Preset swatches
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _kPresetColors.map((hex) {
            final color = Color(
                int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
            final isSelected = _colorCtrl.text.trim().toLowerCase() ==
                hex.toLowerCase();
            return GestureDetector(
              onTap: () => setState(() {
                _colorCtrl.value = TextEditingValue(
                  text: hex,
                  selection:
                      TextSelection.collapsed(offset: hex.length),
                );
              }),
              child: Container(
                width: 28,
                height: 28,
                color: color,
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Role dropdown ──────────────────────────────────────────────────────────

  Widget _buildRoleDropdown(BuildContext context) {
    return BlocBuilder<ProfessionalRolesBloc, ProfessionalRolesState>(
      builder: (context, state) {
        if (state is ProfessionalRolesLoading) {
          return Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    color: context.appColors.primary, strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Carregando cargos…',
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textSecondary),
              ),
            ],
          );
        }

        if (state is ProfessionalRolesError) {
          return Text(
            'Erro ao carregar cargos. Tente novamente.',
            style: AppTypography.bodySm.copyWith(color: AppColors.error),
          );
        }

        final roles = state is ProfessionalRolesLoaded
            ? state.roles
            : <ProfessionalRoleModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRoleId,
              decoration: _inputDecoration(context, 'Cargo (opcional)'),
              style: AppTypography.bodySm
                  .copyWith(color: context.appColors.textPrimary),
              dropdownColor: context.appColors.surface,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Sem cargo',
                    style: AppTypography.bodySm.copyWith(
                        color: context.appColors.textSecondary),
                  ),
                ),
                ...roles.map(
                  (r) => DropdownMenuItem<String>(
                    value: r.id,
                    child: Text(r.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedRoleId = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => _openRoleForm(context, roles),
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: context.appColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Criar novo cargo',
                    style: AppTypography.caption.copyWith(
                      color: context.appColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openRoleForm(
    BuildContext context,
    List<ProfessionalRoleModel> currentRoles,
  ) {
    setState(() {
      _wasCreatingRole = true;
      _previousRoleIds = currentRoles.map((r) => r.id).toSet();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
              value: context.read<ProfessionalRolesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: const RoleFormSheet(),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _wasCreatingRole = false);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    final businessId = businessState.active.id;

    final name = _nameCtrl.text.trim();
    final phone =
        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    final bio =
        _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim();
    final color = _colorCtrl.text.trim();

    if (_isEditing) {
      context.read<ProfessionalsBloc>().add(ProfessionalsUpdateRequested(
            businessId: businessId,
            professionalId: widget.professional!.id,
            name: name,
            roleId: _selectedRoleId,
            phone: phone,
            bio: bio,
            color: color,
          ));
    } else {
      context.read<ProfessionalsBloc>().add(ProfessionalsCreateRequested(
            businessId: businessId,
            name: name,
            roleId: _selectedRoleId,
            phone: phone,
            bio: bio,
            color: color,
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
