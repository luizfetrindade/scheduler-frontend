import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduler_frontend/core/router/app_routes.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/empty_state_cta_card.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_filter_chips.dart';

/// Appointment list for team admins/managers (canViewOtherAppts == true).
/// Includes professional filter chips at the top.
class TeamAppointmentsList extends StatelessWidget {
  const TeamAppointmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ScheduleBloc(ctx.read<AppointmentRepository>()),
      child: const _TeamAppointmentsBody(),
    );
  }
}

class _TeamAppointmentsBody extends StatelessWidget {
  const _TeamAppointmentsBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<ProfessionalsBloc, ProfessionalsState>(
          builder: (context, state) {
            final professionals = _extractProfessionals(state);
            return ProfessionalFilterChips(professionals: professionals);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            return switch (state) {
              AppointmentsLoading() => Center(
                  child: CircularProgressIndicator(
                    color: context.appColors.primary,
                  ),
                ),
              AppointmentsLoaded(:final appointments)
                  when appointments.isEmpty =>
                EmptyStateCtaCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Sem agendamentos hoje',
                  subtitle: 'Nenhum atendimento marcado para hoje',
                  ctaLabel: 'Ver agenda',
                  onTap: () => context.push(AppRoutes.appointments),
                ),
              AppointmentsLoaded(:final appointments) => Column(
                  children: appointments
                      .map(
                        (appt) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppointmentCard(
                            appointment: appt,
                            onConfirm:
                                appt.status == AppointmentStatus.pending
                                    ? () => _updateStatus(
                                          context,
                                          appt,
                                          AppointmentStatus.confirmed,
                                        )
                                    : null,
                            onNoShow:
                                appt.status == AppointmentStatus.pending
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
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ],
    );
  }

  List<ProfessionalModel> _extractProfessionals(ProfessionalsState state) =>
      switch (state) {
        ProfessionalsLoaded(:final professionals) => professionals,
        ProfessionalsActionInProgress(:final professionals) => professionals,
        ProfessionalsError(:final professionals) => professionals,
        _ => const [],
      };

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
