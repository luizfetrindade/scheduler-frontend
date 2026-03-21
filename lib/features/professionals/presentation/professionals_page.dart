import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professional_roles_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_event.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_card.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_form_sheet.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProfessionalModel> _filtered(List<ProfessionalModel> professionals) {
    if (_query.isEmpty) return professionals;
    final q = _query.toLowerCase();
    return professionals
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.roleName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<ProfessionalsBloc, ProfessionalsState>(
        listener: (context, state) {
          if (state is ProfessionalsError &&
              state.professionals.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfessionalsLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: context.appColors.primary),
            );
          }

          final allProfessionals = switch (state) {
            ProfessionalsLoaded(:final professionals) => professionals,
            ProfessionalsActionInProgress(:final professionals) =>
              professionals,
            ProfessionalsError(:final professionals) => professionals,
            _ => <ProfessionalModel>[],
          };

          final professionals = _filtered(allProfessionals);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────
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
                      Text(
                        'Profissionais',
                        style: AppTypography.headingMd.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (allProfessionals.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _CountBadge(count: allProfessionals.length),
                      ],
                      const Spacer(),
                      BlocBuilder<BusinessBloc, BusinessState>(
                        builder: (context, bizState) {
                          final canManage = bizState is BusinessLoaded &&
                              bizState.policy.canManageTeam;
                          if (!canManage) return const SizedBox.shrink();
                          return Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.tune,
                                  size: 20,
                                  color: context.appColors.textSecondary,
                                ),
                                tooltip: 'Gerenciar cargos',
                                onPressed: () =>
                                    context.push(AppRoutes.professionalRoles),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              BaseButton(
                                label: 'Novo',
                                prefixIcon: Icons.add,
                                onPressed: () =>
                                    _openForm(context, professional: null),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Search ──────────────────────────────────────────
                if (allProfessionals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _SearchField(
                      controller: _searchCtrl,
                      hint: 'Buscar por nome ou cargo…',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),

                Divider(height: 1, color: context.appColors.outline),

                // ── Body ──────────────────────────────────────────
                Expanded(
                  child: allProfessionals.isEmpty
                      ? _EmptyState(
                          onAdd: () =>
                              _openForm(context, professional: null),
                        )
                      : professionals.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.all(AppSpacing.lg),
                              itemCount: professionals.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final prof = professionals[i];
                                return ProfessionalCard(
                                  professional: prof,
                                  onTap: () => context.go(
                                      '${AppRoutes.professionals}/${prof.id}'),
                                  onToggleActive: () =>
                                      _toggleActive(context, prof),
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

  void _openForm(BuildContext context,
      {required ProfessionalModel? professional}) {
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
          BlocProvider.value(value: context.read<ProfessionalsBloc>()),
          BlocProvider.value(
              value: context.read<ProfessionalRolesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: ProfessionalFormSheet(professional: professional),
      ),
    );
  }

  void _toggleActive(BuildContext context, ProfessionalModel prof) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;

    context.read<ProfessionalsBloc>().add(ProfessionalsUpdateRequested(
          businessId: businessState.active.id,
          professionalId: prof.id,
          isActive: !prof.isActive,
        ));
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      color: context.appColors.surfaceHigh,
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTypography.bodySm
              .copyWith(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySm
                .copyWith(color: context.appColors.textDisabled),
            prefixIcon: Icon(Icons.search,
                size: 18, color: context.appColors.textSecondary),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close,
                        size: 16, color: context.appColors.textSecondary),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: context.appColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: context.appColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: context.appColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                  color: context.appColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isFirstTime = onAdd != null;
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
                isFirstTime
                    ? Icons.badge_outlined
                    : Icons.search_off_outlined,
                size: 24,
                color: context.appColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFirstTime
                  ? 'Nenhum profissional cadastrado'
                  : 'Nenhum resultado encontrado',
              style: AppTypography.labelLarge.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isFirstTime
                  ? 'Adicione o primeiro profissional\nda sua equipe.'
                  : 'Tente buscar por outro nome ou cargo.',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFirstTime) ...[
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: 'Adicionar profissional',
                prefixIcon: Icons.add,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
