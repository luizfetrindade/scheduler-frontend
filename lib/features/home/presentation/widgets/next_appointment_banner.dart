import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

class NextAppointmentBanner extends StatelessWidget {
  const NextAppointmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        final next = _findNextAppointment(state);
        if (next == null) return const SizedBox.shrink();
        return _Banner(appointment: next);
      },
    );
  }

  AppointmentModel? _findNextAppointment(AppointmentsState state) {
    if (state is! AppointmentsLoaded) return null;
    final now = DateTime.now();
    final upcoming = state.appointments
        .where((a) =>
            a.type == AppointmentType.appointment &&
            a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.noShow &&
            a.endsAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

class _Banner extends StatelessWidget {
  final AppointmentModel appointment;

  const _Banner({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final timeStr = DateFormat('HH:mm').format(appointment.startsAt);
    final now = DateTime.now();
    final diff = appointment.startsAt.difference(now);
    final isOngoing = appointment.startsAt.isBefore(now);

    final statusColor = switch (appointment.status) {
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.pending => colors.textDisabled,
      _ => colors.textSecondary,
    };

    return GestureDetector(
      onTap: () => context.go(AppRoutes.appointments),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.12),
              colors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            left: BorderSide(color: colors.primary, width: 3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(
                Icons.schedule,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximo agendamento',
                    style: AppTypography.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.clientName,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appointment.serviceName != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          child: Text(
                            '·',
                            style: AppTypography.caption.copyWith(
                              color: colors.textDisabled,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            appointment.serviceName!,
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    appointment.status.label,
                    style: AppTypography.caption.copyWith(color: statusColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOngoing ? 'Em andamento' : _formatCountdown(diff),
                  style: AppTypography.caption.copyWith(
                    color: isOngoing ? AppColors.success : colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(Duration diff) {
    if (diff.inHours > 0) {
      return 'em ${diff.inHours}h${diff.inMinutes.remainder(60)}min';
    }
    return 'em ${diff.inMinutes}min';
  }
}
