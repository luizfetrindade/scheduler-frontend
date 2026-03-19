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

class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Profissionais',
          style: AppTypography.headingMd
              .copyWith(color: context.appColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: context.appColors.textPrimary),
            tooltip: 'Gerenciar cargos',
            onPressed: () => context.push(AppRoutes.professionalRoles),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.background,
        onPressed: () => _openForm(context, professional: null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ProfessionalsBloc, ProfessionalsState>(
        listener: (context, state) {
          if (state is ProfessionalsError && state.professionals.isNotEmpty) {
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
              child: CircularProgressIndicator(color: context.appColors.primary),
            );
          }

          final professionals = switch (state) {
            ProfessionalsLoaded(:final professionals) => professionals,
            ProfessionalsActionInProgress(:final professionals) => professionals,
            ProfessionalsError(:final professionals) => professionals,
            _ => <ProfessionalModel>[],
          };

          if (professionals.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: professionals.length,
            separatorBuilder: (context2, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final i = index;
              final prof = professionals[i];
              return ProfessionalCard(
                professional: prof,
                onTap: () => context.go('${AppRoutes.professionals}/${prof.id}'),
                onToggleActive: () => _toggleActive(context, prof),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined,
              size: 48, color: context.appColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum profissional cadastrado',
            style: AppTypography.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openForm(context, professional: null),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appColors.primary,
              side: BorderSide(color: context.appColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Adicionar profissional',
              style: AppTypography.bodySm,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ProfessionalsBloc>()),
          BlocProvider.value(value: context.read<ProfessionalRolesBloc>()),
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
