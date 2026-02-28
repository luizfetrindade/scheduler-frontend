import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onConfirm;
  final VoidCallback? onNoShow;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onConfirm,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(appointment.startsAt.toLocal());
    final showActions = appointment.status == AppointmentStatus.pending &&
        (onConfirm != null || onNoShow != null);

    return BaseCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Text(
              timeStr,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.purple300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.clientName, style: AppTypography.bodyMd),
                if (appointment.serviceName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    appointment.serviceName!,
                    style: AppTypography.caption,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _StatusBadge(status: appointment.status),
              ],
            ),
          ),
          // Actions
          if (showActions)
            Row(
              children: [
                if (onConfirm != null)
                  IconButton(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, color: AppColors.success),
                    tooltip: 'Confirmar',
                  ),
                if (onNoShow != null)
                  IconButton(
                    onPressed: onNoShow,
                    icon: const Icon(
                      Icons.person_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Não compareceu',
                  ),
              ],
            ),
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
      AppointmentStatus.pending => AppColors.purple300,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => AppColors.textDisabled,
      AppointmentStatus.completed => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
