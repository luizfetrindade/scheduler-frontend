import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

/// Result returned by the attendance prompt dialog.
enum AttendancePromptResult {
  attended,
  noShow,
  later,
}

/// Dialog asking whether the client attended an appointment that has ended.
///
/// Returns an [AttendancePromptResult] through [Navigator.pop]. Returns `null`
/// if dismissed via back button — treated as [AttendancePromptResult.later].
class AttendancePromptDialog extends StatelessWidget {
  final AppointmentModel appointment;

  const AttendancePromptDialog({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final timeLabel =
        '${DateFormat('HH:mm').format(appointment.startsAt)} – ${DateFormat('HH:mm').format(appointment.endsAt)}';
    final dateLabel =
        DateFormat("d 'de' MMM", 'pt_BR').format(appointment.startsAt);

    return Dialog(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_available, color: colors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Agendamento encerrado',
                    style: AppTypography.headingMd.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              appointment.clientName,
              style: AppTypography.bodyMd.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (appointment.serviceName != null) ...[
              const SizedBox(height: 2),
              Text(
                appointment.serviceName!,
                style: AppTypography.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              '$dateLabel · $timeLabel',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'O cliente compareceu?',
              style: AppTypography.bodySm.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionButton(
              icon: Icons.check_circle,
              label: 'Compareceu',
              color: AppColors.success,
              onTap: () => Navigator.of(context)
                  .pop(AttendancePromptResult.attended),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              icon: Icons.person_off_outlined,
              label: 'Não compareceu',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.of(context)
                  .pop(AttendancePromptResult.noShow),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              icon: Icons.schedule,
              label: 'Depois',
              color: colors.textSecondary,
              outlined: true,
              onTap: () => Navigator.of(context)
                  .pop(AttendancePromptResult.later),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: outlined
                  ? color
                  : Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: outlined
                    ? color
                    : Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
