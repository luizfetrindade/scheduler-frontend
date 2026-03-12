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

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Serviços',
          style: AppTypography.headingMd.copyWith(color: context.appColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.background,
        onPressed: () => _openForm(context, initial: null),
        child: const Icon(Icons.add),
      ),
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
              child: CircularProgressIndicator(color: context.appColors.primary),
            );
          }

          final services = switch (state) {
            ServicesLoaded(:final services) => services,
            ServicesActionInProgress(:final services) => services,
            ServicesError(:final services) => services,
            _ => <ServiceModel>[],
          };

          if (services.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: services.length,
            separatorBuilder: (context, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final svc = services[i];
              return ServiceCard(
                service: svc,
                onEdit: () => _openForm(context, initial: svc),
                onToggleActive: () => _toggleActive(context, svc),
                onDelete: () => _confirmDelete(context, svc),
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
          Icon(Icons.cut_outlined, size: 48, color: context.appColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum serviço cadastrado',
            style: AppTypography.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => _openForm(context, initial: null),
            child: Text(
              'Adicionar serviço',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required ServiceModel? initial}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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

  Future<void> _confirmDelete(BuildContext context, ServiceModel svc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        title: Text(
          'Excluir serviço',
          style: AppTypography.bodySm.copyWith(color: ctx.appColors.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${svc.name}"? Esta ação não pode ser desfeita.',
          style: AppTypography.bodySm.copyWith(color: ctx.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.bodySm.copyWith(
                color: ctx.appColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir',
              style: AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
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
