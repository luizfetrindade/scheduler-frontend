import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_card.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_form_sheet.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Clientes',
          style: AppTypography.headingMd
              .copyWith(color: context.appColors.textPrimary),
        ),
      ),
      // TODO: hide FAB for staff role
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        foregroundColor: context.appColors.background,
        onPressed: () => _openForm(context, initial: null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ClientsBloc, ClientsState>(
        listener: (context, state) {
          if (state is ClientsError && state.clients.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientsLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: context.appColors.primary),
            );
          }

          final clients = switch (state) {
            ClientsLoaded(:final clients) => clients,
            ClientsActionInProgress(:final clients) => clients,
            ClientsError(:final clients) => clients,
            _ => <ClientModel>[],
          };

          if (clients.isEmpty) {
            return _buildEmptyState(context);
          }

          final businessState = context.read<BusinessBloc>().state;
          final businessId = businessState is BusinessLoaded
              ? businessState.active.id
              : '';

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: clients.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final client = clients[i];
              return ClientCard(
                client: client,
                businessId: businessId,
                onEdit: () => _openForm(context, initial: client),
                onDelete: () => _confirmDelete(context, client),
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
          Icon(Icons.people_outline,
              size: 48, color: context.appColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum cliente cadastrado',
            style: AppTypography.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openForm(context, initial: null),
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
              'Adicionar cliente',
              style: AppTypography.bodySm,
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required ClientModel? initial}) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return; // guard: no-op if business not loaded
    final businessId = businessState.active.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ClientsBloc>(),
        child: ClientFormSheet(initial: initial, businessId: businessId),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        title: Text(
          'Excluir cliente',
          style: AppTypography.bodySm
              .copyWith(color: ctx.appColors.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${client.name}"? '
          'O vínculo com este negócio será removido, '
          'mas a conta do cliente será preservada.',
          style: AppTypography.bodySm
              .copyWith(color: ctx.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.bodySm.copyWith(
                  color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir',
              style:
                  AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final businessState = context.read<BusinessBloc>().state;
      if (businessState is! BusinessLoaded) return;

      context.read<ClientsBloc>().add(ClientDeleteRequested(
            businessId: businessState.active.id,
            clientId: client.id,
          ));
    }
  }
}
