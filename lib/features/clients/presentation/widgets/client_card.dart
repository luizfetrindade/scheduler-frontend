import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_history_tile.dart';

class ClientCard extends StatefulWidget {
  final ClientModel client;
  final String businessId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClientCard({
    super.key,
    required this.client,
    required this.businessId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  bool _expanded = false;

  void _toggleExpand(BuildContext context, ClientsState state) {
    final willExpand = !_expanded;
    setState(() => _expanded = willExpand);

    if (willExpand && !state._historyContainsKey(widget.client.id)) {
      context.read<ClientsBloc>().add(ClientHistoryLoadRequested(
            businessId: widget.businessId,
            clientId: widget.client.id,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsBloc, ClientsState>(
      builder: (context, state) {
        final history = state._historyFor(widget.client.id);
        final isLoading = _expanded && history == null;

        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.appColors.surfaceHigh),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Collapsed header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.appColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        widget.client.name.isNotEmpty
                            ? widget.client.name[0].toUpperCase()
                            : '?',
                        style: AppTypography.bodyMd.copyWith(
                          color: context.appColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Name + phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.name,
                            style: AppTypography.bodyMd.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.client.phone,
                            style: AppTypography.caption.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: context.appColors.textSecondary),
                      onPressed: widget.onEdit,
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      onPressed: widget.onDelete,
                      tooltip: 'Excluir',
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(Icons.keyboard_arrow_down,
                            size: 20, color: context.appColors.textSecondary),
                        onPressed: () => _toggleExpand(context, state),
                        tooltip: _expanded ? 'Recolher' : 'Ver histórico',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Expanded section ──────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 1, color: context.appColors.surfaceHigh),
                          if (isLoading)
                            LinearProgressIndicator(
                              color: context.appColors.primary,
                              backgroundColor: context.appColors.surfaceHigh,
                            )
                          else if (history != null && history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Center(
                                child: Text(
                                  'Nenhum agendamento encontrado',
                                  style: AppTypography.bodySm.copyWith(
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else if (history != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.xs,
                              ),
                              child: _StatsRow(history: history),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.sm,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: history.length,
                                itemBuilder: (_, i) =>
                                    ClientHistoryTile(item: history[i]),
                              ),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<ClientHistoryItem> history;
  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final total = history.length;
    final confirmed = history.where((h) => h.status == AppointmentStatus.confirmed).length;
    final cancelled = history.where((h) => h.status == AppointmentStatus.cancelled).length;
    final noShow = history.where((h) => h.status == AppointmentStatus.noShow).length;
    final completed = history.where((h) => h.status == AppointmentStatus.completed).length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _StatChip(label: 'Total', value: total, color: context.appColors.textPrimary),
        _StatChip(label: 'Confirmados', value: confirmed, color: AppColors.success),
        _StatChip(label: 'Cancelados', value: cancelled, color: AppColors.error),
        _StatChip(label: 'Não compareceu', value: noShow, color: context.appColors.textDisabled),
        _StatChip(label: 'Concluídos', value: completed, color: context.appColors.textSecondary),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}

// ── State extension helpers ────────────────────────────────────────────────
extension _ClientsStateX on ClientsState {
  List<ClientHistoryItem>? _historyFor(String clientId) => switch (this) {
    ClientsLoaded(:final history) => history[clientId],
    ClientsActionInProgress(:final history) => history[clientId],
    ClientsError(:final history) => history[clientId],
    _ => null,
  };

  bool _historyContainsKey(String clientId) => switch (this) {
    ClientsLoaded(:final history) => history.containsKey(clientId),
    ClientsActionInProgress(:final history) => history.containsKey(clientId),
    ClientsError(:final history) => history.containsKey(clientId),
    _ => false,
  };
}
