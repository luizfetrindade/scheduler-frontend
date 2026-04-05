import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/create_appointment_sheet.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/empty_state_cta_card.dart';

class AppointmentsSummaryCard extends StatelessWidget {
  const AppointmentsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        final appointments = _extractAppointments(state);

        if (appointments.isEmpty) {
          return Column(
            children: [
              _AppointmentsCardHeader(
                total: 0,
                pending: 0,
                confirmed: 0,
                onNewAppointment: () => _openNewAppointmentSheet(context),
              ),
              const SizedBox(height: AppSpacing.md),
              EmptyStateCtaCard(
                icon: Icons.calendar_today_outlined,
                title: 'Sem agendamentos hoje',
                subtitle: 'Crie o primeiro agendamento do dia',
                ctaLabel: 'Novo agendamento',
                onTap: () => _openNewAppointmentSheet(context),
              ),
            ],
          );
        }

        final pending =
            appointments.where((a) => a.status == AppointmentStatus.pending).length;
        final confirmed =
            appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
        final preview = appointments.take(3).toList();
        final overflow = appointments.length - 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AppointmentsCardHeader(
              total: appointments.length,
              pending: pending,
              confirmed: confirmed,
              onNewAppointment: () => _openNewAppointmentSheet(context),
            ),
            const SizedBox(height: AppSpacing.md),
            BaseCard(
              onTap: () => context.go(AppRoutes.appointments),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...preview.map(
                    (appt) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AppointmentRow(appointment: appt),
                    ),
                  ),
                  if (overflow > 0)
                    Text(
                      '+$overflow mais',
                      style: AppTypography.caption.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<AppointmentModel> _extractAppointments(AppointmentsState state) =>
      switch (state) {
        AppointmentsLoaded(:final appointments) => appointments,
        _ => const [],
      };

  void _openNewAppointmentSheet(BuildContext context) {
    final repo = context.read<AppointmentRepository>();
    final scheduleBloc = ScheduleBloc(repo);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BlocProvider<ScheduleBloc>(
        create: (_) => scheduleBloc,
        child: CreateAppointmentSheet(initialDateTime: DateTime.now()),
      ),
    );
  }
}

class _AppointmentsCardHeader extends StatelessWidget {
  final int total;
  final int pending;
  final int confirmed;
  final VoidCallback onNewAppointment;

  const _AppointmentsCardHeader({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.onNewAppointment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 16, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Agendamentos de hoje',
          style: AppTypography.labelLarge.copyWith(color: colors.textPrimary),
        ),
        if (total > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              '$total',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusPill(label: '$pending pend.', color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          _StatusPill(label: '$confirmed conf.', color: AppColors.success),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onNewAppointment,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 12, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 2),
                Text(
                  'Novo',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final timeStr = DateFormat('HH:mm').format(appointment.startsAt);
    final statusColor = switch (appointment.status) {
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.pending => colors.textDisabled,
      AppointmentStatus.noShow => AppColors.error,
      _ => colors.textSecondary,
    };

    return Row(
      children: [
        Text(
          timeStr,
          style: AppTypography.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(width: 3, height: 3, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            appointment.clientName,
            style: AppTypography.bodySm.copyWith(color: colors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (appointment.serviceName != null)
          Text(
            appointment.serviceName!,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
