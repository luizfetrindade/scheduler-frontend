import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/rrule_builder.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/edit_appointment_sheet.dart';

class AppointmentDetailSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final bool canModify;

  const AppointmentDetailSheet({
    super.key,
    required this.appointment,
    this.canModify = true,
  });

  bool get canEdit =>
      canModify &&
      !appointment.isBlock &&
      appointment.status != AppointmentStatus.cancelled;

  bool get canChangeStatus =>
      canModify &&
      !appointment.isBlock &&
      appointment.status != AppointmentStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final startStr = timeFormat.format(appointment.startsAt);
    final endStr = timeFormat.format(appointment.endsAt);
    final dateStr = DateFormat('dd/MM/yyyy').format(appointment.startsAt);
    final canCancel = canModify && appointment.status != AppointmentStatus.cancelled;

    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleActionSuccess || state is ScheduleActionFailure) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              appointment.isBlock
                  ? 'Detalhes do Bloqueio'
                  : 'Detalhes do Agendamento',
              style: AppTypography.headingMd.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (appointment.isBlock) ...[
              if (appointment.title != null)
                _DetailRow(icon: Icons.block, label: appointment.title!),
            ] else ...[
              _DetailRow(icon: Icons.person, label: appointment.clientName),
              if (appointment.serviceName != null)
                _DetailRow(
                  icon: Icons.work_outline,
                  label: appointment.serviceName!,
                ),
            ],
            _DetailRow(icon: Icons.calendar_today, label: dateStr),
            _DetailRow(icon: Icons.access_time, label: '$startStr – $endStr'),
            GestureDetector(
              onTap: canChangeStatus
                  ? () => _showStatusPicker(context)
                  : null,
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: _statusColor(context, appointment.status),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      appointment.status.label,
                      style: AppTypography.bodySm.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  if (canChangeStatus)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: context.appColors.textSecondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _DetailRow(icon: Icons.notes, label: appointment.notes!),
            if (appointment.isRecurring && appointment.recurrenceRule != null)
              _DetailRow(
                icon: Icons.repeat,
                label: describeRRule(appointment.recurrenceRule!),
              ),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.lg),
              BaseButton(
                label: 'Editar Agendamento',
                onPressed: () => _handleEdit(context),
                variant: BaseButtonVariant.secondary,
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: AppSpacing.md),
              BaseButton(
                label: appointment.isBlock
                    ? 'Remover Bloqueio'
                    : 'Cancelar Agendamento',
                onPressed: () => _handleCancel(context),
                variant: BaseButtonVariant.destructive,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    final statuses = [
      AppointmentStatus.pending,
      AppointmentStatus.confirmed,
      AppointmentStatus.completed,
      AppointmentStatus.noShow,
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    'Alterar status',
                    style: AppTypography.bodySm.copyWith(
                      color: sheetContext.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(height: 1, color: sheetContext.appColors.surfaceHigh),
                ...statuses.map((status) {
                  final isSelected = status == appointment.status;
                  return InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (!isSelected) {
                        context.read<ScheduleBloc>().add(
                              ScheduleAppointmentStatusChanged(
                                appointmentId: appointment.id,
                                status: status,
                              ),
                            );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _statusColor(context, status),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              status.label,
                              style: AppTypography.bodySm.copyWith(
                                color: isSelected
                                    ? context.appColors.primary
                                    : context.appColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: context.appColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleEdit(BuildContext context) {
    final bloc = context.read<ScheduleBloc>();
    final navigator = Navigator.of(context);
    navigator.pop();
    showModalBottomSheet<void>(
      context: navigator.context,
      isScrollControlled: true,
      backgroundColor: navigator.context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditAppointmentSheet(appointment: appointment),
      ),
    );
  }

  void _handleCancel(BuildContext context) {
    if (appointment.isRecurring) {
      _showRecurrenceCancelDialog(context);
    } else {
      _confirmCancel(context);
    }
  }

  void _showRecurrenceCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.appColors.surface,
        title: Text(
          appointment.isBlock ? 'Remover bloqueio' : 'Cancelar agendamento',
          style: AppTypography.bodySm.copyWith(
            color: dialogContext.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Este é um evento recorrente. O que deseja fazer?',
          style: AppTypography.bodySm.copyWith(
            color: dialogContext.appColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Não cancelar',
              style: AppTypography.bodySm.copyWith(
                color: dialogContext.appColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ScheduleBloc>().add(
                    ScheduleRecurrenceCancelRequested(
                      appointmentId: appointment.id,
                      cancelFuture: false,
                    ),
                  );
            },
            child: Text(
              'Cancelar apenas este',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ScheduleBloc>().add(
                    ScheduleRecurrenceCancelRequested(
                      appointmentId: appointment.id,
                      cancelFuture: true,
                    ),
                  );
            },
            child: Text(
              'Cancelar este e futuros',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    final label = appointment.isBlock
        ? 'Remover bloqueio?'
        : 'Cancelar agendamento?';
    final description = appointment.isBlock
        ? 'Tem certeza que deseja remover este bloqueio?'
        : 'Tem certeza que deseja cancelar o agendamento de ${appointment.clientName}?';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.appColors.surface,
        title: Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: dialogContext.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          description,
          style: AppTypography.bodySm.copyWith(
            color: dialogContext.appColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Não',
              style: AppTypography.bodySm.copyWith(
                color: dialogContext.appColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ScheduleBloc>().add(
                    ScheduleAppointmentCancelRequested(appointment.id),
                  );
            },
            child: Text(
              'Sim, cancelar',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, AppointmentStatus status) =>
      switch (status) {
        AppointmentStatus.pending => context.appColors.primary,
        AppointmentStatus.confirmed => AppColors.success,
        AppointmentStatus.cancelled => AppColors.error,
        AppointmentStatus.noShow => const Color(0xFFF59E0B),
        AppointmentStatus.completed => context.appColors.textSecondary,
      };
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final double iconSize;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? context.appColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
