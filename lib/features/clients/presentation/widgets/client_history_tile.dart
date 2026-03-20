import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';

class ClientHistoryTile extends StatelessWidget {
  final ClientHistoryItem item;

  const ClientHistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM', 'pt_BR').format(item.startsAt.toLocal());
    final timeStr = DateFormat('HH:mm').format(item.startsAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Date + time block ──
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 3,
            ),
            color: context.appColors.surfaceHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  timeStr,
                  style: AppTypography.caption.copyWith(
                    color: context.appColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Service name ──
          Expanded(
            child: Text(
              item.serviceName ?? '—',
              style: AppTypography.bodySm.copyWith(
                color: item.serviceName != null
                    ? context.appColors.textPrimary
                    : context.appColors.textDisabled,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Status badge ──
          _StatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.pending => context.appColors.primaryLight,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => context.appColors.textDisabled,
      AppointmentStatus.completed => context.appColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      color: color.withValues(alpha: 0.15),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
