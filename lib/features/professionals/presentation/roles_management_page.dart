import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_role_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/role_form_sheet.dart';

class RolesManagementPage extends StatelessWidget {
  const RolesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<ProfessionalRolesBloc, ProfessionalRolesState>(
        listener: (context, state) {
          if (state is ProfessionalRolesError && state.roles.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfessionalRolesLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: context.appColors.primary),
            );
          }

          final bizState = context.watch<BusinessBloc>().state;
          final canManage =
              bizState is BusinessLoaded && bizState.policy.canManageTeam;

          final roles = switch (state) {
            ProfessionalRolesLoaded(:final roles) => roles,
            ProfessionalRolesActionInProgress(:final roles) => roles,
            ProfessionalRolesError(:final roles) => roles,
            _ => <ProfessionalRoleModel>[],
          };

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: context.appColors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Voltar',
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Cargos',
                        style: AppTypography.headingMd.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (roles.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          color: context.appColors.surfaceHigh,
                          child: Text(
                            '${roles.length}',
                            style: AppTypography.caption.copyWith(
                              color: context.appColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (canManage)
                        BaseButton(
                          label: 'Novo cargo',
                          prefixIcon: Icons.add,
                          onPressed: () => _openForm(context, role: null),
                        ),
                    ],
                  ),
                ),

                Divider(height: 1, color: context.appColors.outline),

                // ── Body ──────────────────────────────────────────
                Expanded(
                  child: roles.isEmpty
                      ? _buildEmptyState(context, canManage: canManage)
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: roles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            return _RoleListItem(
                              role: role,
                              onEdit: canManage
                                  ? () => _openForm(context, role: role)
                                  : null,
                              onDelete: canManage
                                  ? () => _onDeleteTapped(context, role)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool canManage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              color: context.appColors.surfaceHigh,
              child: Icon(
                Icons.work_outline,
                size: 24,
                color: context.appColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum cargo cadastrado',
              style: AppTypography.labelLarge.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crie cargos para organizar\nos profissionais da equipe.',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (canManage)
              BaseButton(
                label: 'Adicionar cargo',
                prefixIcon: Icons.add,
                onPressed: () => _openForm(context, role: null),
              ),
          ],
        ),
      ),
    );
  }

  void _onDeleteTapped(
      BuildContext context, ProfessionalRoleModel role) {
    final count = role.professionalCount ?? 0;
    if (count == 0) {
      _dispatchDelete(context, role);
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Excluir cargo',
                    style: AppTypography.labelLarge.copyWith(
                      color: ctx.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$count profissional(is) usa(m) este cargo. '
                'Deseja excluir mesmo assim?',
                style: AppTypography.bodySm.copyWith(
                  color: ctx.appColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: BaseButton(
                      label: 'Cancelar',
                      variant: BaseButtonVariant.secondary,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: BaseButton(
                      label: 'Excluir',
                      variant: BaseButtonVariant.destructive,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        _dispatchDelete(context, role);
      }
    });
  }

  void _dispatchDelete(
      BuildContext context, ProfessionalRoleModel role) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    context.read<ProfessionalRolesBloc>().add(
          ProfessionalRolesDeleteRequested(
            businessId: businessState.active.id,
            roleId: role.id,
          ),
        );
  }

  void _openForm(BuildContext context,
      {required ProfessionalRoleModel? role}) {
    showModalBottomSheet(
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
        child: RoleFormSheet(role: role),
      ),
    );
  }
}

// ── Role list item ────────────────────────────────────────────────────────────

class _RoleListItem extends StatelessWidget {
  final ProfessionalRoleModel role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RoleListItem({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final count = role.professionalCount ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            color: context.appColors.primary.withValues(alpha: 0.08),
            child: Icon(
              Icons.work_outline,
              size: 16,
              color: context.appColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1
                      ? '1 profissional'
                      : '$count profissionais',
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 17,
              color: context.appColors.textSecondary,
            ),
            onPressed: onEdit,
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            key: Key('delete-${role.id}'),
            icon: const Icon(
              Icons.delete_outline,
              size: 17,
              color: AppColors.error,
            ),
            onPressed: onDelete,
            tooltip: 'Excluir',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
