import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointment_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/greeting_row.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/stats_summary_row.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: BlocListener<BusinessBloc, BusinessState>(
          listener: (context, state) {
            if (state is BusinessLoaded) {
              context.read<AppointmentsBloc>().add(
                    AppointmentsLoadRequested(
                      slug: state.active.slug,
                      date: DateTime.now(),
                    ),
                  );
            }
          },
          child: RefreshIndicator(
            color: context.appColors.primary,
            onRefresh: () async {
              final bizState = context.read<BusinessBloc>().state;
              if (bizState is BusinessLoaded) {
                context.read<AppointmentsBloc>().add(
                      AppointmentsLoadRequested(
                        slug: bizState.active.slug,
                        date: DateTime.now(),
                      ),
                    );
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildGreeting(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStats(context),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Agendamentos de hoje',
                        style: AppTypography.headingMd,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAppointmentList(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.firstName : '';

    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state is! BusinessLoaded) return const SizedBox.shrink();
        return BusinessSelectorHeader(
          active: state.active,
          businesses: state.businesses,
          userName: userName,
          onSelect: (biz) =>
              context.read<BusinessBloc>().add(BusinessSelected(biz)),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final firstName =
        authState is AuthAuthenticated ? authState.user.firstName : '';
    return GreetingRow(firstName: firstName);
  }

  Widget _buildStats(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoaded) {
          return StatsSummaryRow(
            total: state.total,
            pending: state.pending,
            confirmed: state.confirmed,
          );
        }
        return const StatsSummaryRow(total: 0, pending: 0, confirmed: 0);
      },
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        return switch (state) {
          AppointmentsLoading() => Center(
              child: CircularProgressIndicator(color: context.appColors.primary),
            ),
          AppointmentsLoaded(:final appointments) when appointments.isEmpty =>
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  'Nenhum agendamento hoje',
                  style: AppTypography.bodySm
                      .copyWith(color: context.appColors.textSecondary),
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
                  style:
                      AppTypography.bodySm.copyWith(color: AppColors.error),
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
    AppointmentStatus newStatus,
  ) {
    final bizState = context.read<BusinessBloc>().state;
    if (bizState is! BusinessLoaded) return;

    context.read<AppointmentsBloc>().add(
          AppointmentStatusChanged(
            slug: bizState.active.slug,
            appointmentId: appt.id,
            status: newStatus,
          ),
        );
  }
}
