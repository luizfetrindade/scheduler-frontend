import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_history_tile.dart';

String _formatPhone(String digits) {
  if (digits.isEmpty) return '';
  final d = digits.length > 11 ? digits.substring(0, 11) : digits;
  final isMobile = d.length > 10;
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 0) buf.write('(');
    if (i == 2) buf.write(') ');
    if (isMobile && i == 7) buf.write('-');
    if (!isMobile && i == 6) buf.write('-');
    buf.write(d[i]);
  }
  return buf.toString();
}

class ClientCard extends StatefulWidget {
  final ClientModel client;
  final String businessId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  const ClientCard({
    super.key,
    required this.client,
    required this.businessId,
    required this.onEdit,
    required this.onDelete,
    this.showDivider = true,
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // ── Header row ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name + contact info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.name,
                            style: AppTypography.labelLarge.copyWith(
                              color: context.appColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPhone(widget.client.phone ?? ''),
                            style: AppTypography.caption.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          if (widget.client.email != null)
                            Text(
                              widget.client.email!,
                              style: AppTypography.caption.copyWith(
                                color: context.appColors.textDisabled,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Action icons
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: context.appColors.textSecondary,
                      ),
                      onPressed: widget.onEdit,
                      tooltip: 'Editar',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 17,
                        color: AppColors.error,
                      ),
                      onPressed: widget.onDelete,
                      tooltip: 'Excluir',
                      visualDensity: VisualDensity.compact,
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: context.appColors.textDisabled,
                        ),
                        onPressed: () => _toggleExpand(context, state),
                        tooltip: _expanded ? 'Recolher' : 'Ver histórico',
                        visualDensity: VisualDensity.compact,
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
                          Divider(
                            height: 1,
                            color: context.appColors.outline,
                          ),
                          if (isLoading)
                            LinearProgressIndicator(
                              minHeight: 2,
                              color: context.appColors.primary,
                              backgroundColor: context.appColors.surfaceHigh,
                            )
                          else if (history != null && history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                AppSpacing.xs,
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
              if (widget.showDivider)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.appColors.outline,
                ),
            ],
          );
      },
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<ClientHistoryItem> history;
  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final total = history.length;
    final confirmed =
        history.where((h) => h.status == AppointmentStatus.confirmed).length;
    final cancelled =
        history.where((h) => h.status == AppointmentStatus.cancelled).length;
    final noShow =
        history.where((h) => h.status == AppointmentStatus.noShow).length;
    final completed =
        history.where((h) => h.status == AppointmentStatus.completed).length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _StatChip(
            label: 'Total',
            value: total,
            color: context.appColors.textPrimary),
        _StatChip(
            label: 'Confirmados', value: confirmed, color: AppColors.success),
        _StatChip(
            label: 'Cancelados', value: cancelled, color: AppColors.error),
        _StatChip(
            label: 'Não compareceu',
            value: noShow,
            color: context.appColors.textDisabled),
        _StatChip(
            label: 'Concluídos',
            value: completed,
            color: context.appColors.textSecondary),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      color: color.withValues(alpha: 0.1),
      child: Text(
        '$label: $value',
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}

// ── State extension helpers ───────────────────────────────────────────────────

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
