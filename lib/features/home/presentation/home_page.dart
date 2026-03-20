import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/greeting_row.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/personal_appointments_list.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/setup_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/stats_summary_row.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/team_appointments_list.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

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
                      const SizedBox(height: AppSpacing.lg),
                      _buildSetupCard(context),
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
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, bizState) {
        final isAdmin =
            bizState is BusinessLoaded ? bizState.policy.isAdmin : true;
        return BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            if (state is AppointmentsLoaded) {
              return _StatsWithLabel(
                total: state.total,
                pending: state.pending,
                confirmed: state.confirmed,
                isAdmin: isAdmin,
              );
            }
            return _StatsWithLabel(
              total: 0,
              pending: 0,
              confirmed: 0,
              isAdmin: isAdmin,
            );
          },
        );
      },
    );
  }

  Widget _buildSetupCard(BuildContext context) {
    return BlocBuilder<WizardBloc, WizardState>(
      builder: (context, wizardState) {
        if (wizardState is WizardLoaded && !wizardState.isAllComplete) {
          return Column(
            children: [
              SetupCard(wizardState: wizardState),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, businessState) {
        if (businessState is! BusinessLoaded) return const SizedBox.shrink();
        return businessState.policy.canViewOtherAppts
            ? const TeamAppointmentsList()
            : const PersonalAppointmentsList();
      },
    );
  }
}

class _StatsWithLabel extends StatelessWidget {
  final int total;
  final int pending;
  final int confirmed;
  final bool isAdmin;

  const _StatsWithLabel({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAdmin ? 'Total hoje' : 'Seus hoje',
          style: AppTypography.bodySm
              .copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatsSummaryRow(
          total: total,
          pending: pending,
          confirmed: confirmed,
        ),
      ],
    );
  }
}
