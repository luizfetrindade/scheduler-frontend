import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/appointments_summary_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/clients_summary_card.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/greeting_row.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/next_appointment_banner.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/services_summary_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
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
                    const NextAppointmentBanner(),
                    const SizedBox(height: AppSpacing.xl),
                    const AppointmentsSummaryCard(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSummaryCards(context),
                  ]),
                ),
              ),
            ],
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

  Widget _buildSummaryCards(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state is! BusinessLoaded || !state.policy.isAdmin) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'Visão geral'),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(child: ServicesSummaryCard()),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: ClientsSummaryCard()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: context.appColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
