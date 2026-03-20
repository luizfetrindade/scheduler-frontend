import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';

class PersonalAppointmentsList extends StatelessWidget {
  const PersonalAppointmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        return switch (state) {
          AppointmentsLoading() => Center(
              child: CircularProgressIndicator(
                color: context.appColors.primary,
              ),
            ),
          AppointmentsLoaded(:final appointments) when appointments.isEmpty =>
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  'Nenhum agendamento hoje',
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
          AppointmentsLoaded(:final appointments) => Column(
              children: appointments
                  .map(
                    (appt) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppointmentCard(
                        appointment: appt,
                        onConfirm: appt.status == AppointmentStatus.pending
                            ? () => _updateStatus(
                                  context,
                                  appt,
                                  AppointmentStatus.confirmed,
                                )
                            : null,
                        onNoShow: appt.status == AppointmentStatus.pending
                            ? () => _updateStatus(
                                  context,
                                  appt,
                                  AppointmentStatus.noShow,
                                )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          AppointmentsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  message,
                  style: AppTypography.bodySm.copyWith(color: AppColors.error),
                ),
              ),
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  void _updateStatus(
    BuildContext context,
    AppointmentModel appt,
    AppointmentStatus status,
  ) {
    final bizState = context.read<BusinessBloc>().state;
    if (bizState is! BusinessLoaded) return;
    context.read<AppointmentsBloc>().add(
          AppointmentStatusChanged(
            slug: bizState.active.slug,
            appointmentId: appt.id,
            status: status,
          ),
        );
  }
}
