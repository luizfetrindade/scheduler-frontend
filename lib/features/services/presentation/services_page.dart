import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/presentation/widgets/service_card.dart';
import 'package:scheduler_frontend/features/services/presentation/widgets/service_form_sheet.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ServiceModel> _filtered(List<ServiceModel> services) {
    if (_query.isEmpty) return services;
    final q = _query.toLowerCase();
    return services.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is ServicesError && state.services.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ServicesLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: context.appColors.primary),
            );
          }

          final allServices = switch (state) {
            ServicesLoaded(:final services) => services,
            ServicesActionInProgress(:final services) => services,
            ServicesError(:final services) => services,
            _ => <ServiceModel>[],
          };

          final services = _filtered(allServices);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
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
                        'Serviços',
                        style: AppTypography.headingMd.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (allServices.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _CountBadge(count: allServices.length),
                      ],
                      const Spacer(),
                      BaseButton(
                        label: 'Novo serviço',
                        prefixIcon: Icons.add,
                        onPressed: () => _openForm(context, initial: null),
                      ),
                    ],
                  ),
                ),

                // ── Search ──────────────────────────────────────────────
                if (allServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _SearchField(
                      controller: _searchCtrl,
                      hint: 'Buscar serviço…',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),

                Divider(height: 1, color: context.appColors.outline),

                // ── Body ────────────────────────────────────────────────
                Expanded(
                  child: allServices.isEmpty
                      ? _EmptyState(
                          isFirstTime: true,
                          onAdd: () => _openForm(context, initial: null),
                        )
                      : services.isEmpty
                          ? const _EmptyState(isFirstTime: false)
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: services.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final svc = services[i];
                                return ServiceCard(
                                  service: svc,
                                  onEdit: () =>
                                      _openForm(context, initial: svc),
                                  onToggleActive: () =>
                                      _toggleActive(context, svc),
                                  onDelete: () =>
                                      _confirmDelete(context, svc),
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

  void _openForm(BuildContext context, {required ServiceModel? initial}) {
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
          BlocProvider.value(value: context.read<ServicesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: ServiceFormSheet(initial: initial),
      ),
    );
  }

  void _toggleActive(BuildContext context, ServiceModel svc) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;

    context.read<ServicesBloc>().add(ServiceUpdateRequested(
          businessId: businessState.active.id,
          serviceId: svc.id,
          isActive: !svc.isActive,
        ));
  }

  Future<void> _confirmDelete(
      BuildContext context, ServiceModel svc) async {
    final confirmed = await showDialog<bool>(
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
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Excluir serviço',
                    style: AppTypography.labelLarge.copyWith(
                      color: ctx.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tem certeza que deseja excluir "${svc.name}"? '
                'Esta ação não pode ser desfeita.',
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
    );

    if (confirmed == true && context.mounted) {
      final businessState = context.read<BusinessBloc>().state;
      if (businessState is! BusinessLoaded) return;

      context.read<ServicesBloc>().add(ServiceDeleteRequested(
            businessId: businessState.active.id,
            serviceId: svc.id,
          ));
    }
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
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
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySm
                .copyWith(color: context.appColors.textDisabled),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: context.appColors.textSecondary,
            ),
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
              borderSide:
                  BorderSide(color: context.appColors.primary, width: 1.5),
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
  final bool isFirstTime;
  final VoidCallback? onAdd;

  const _EmptyState({required this.isFirstTime, this.onAdd});

  @override
  Widget build(BuildContext context) {
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
                    ? Icons.cut_outlined
                    : Icons.search_off_outlined,
                size: 24,
                color: context.appColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFirstTime
                  ? 'Nenhum serviço cadastrado'
                  : 'Nenhum resultado encontrado',
              style: AppTypography.labelLarge.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isFirstTime
                  ? 'Crie seu primeiro serviço para disponibilizá-lo\nnos agendamentos.'
                  : 'Tente buscar por outro nome.',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFirstTime && onAdd != null) ...[
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: 'Adicionar serviço',
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
