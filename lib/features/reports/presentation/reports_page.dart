import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_bloc.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/daily_series_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/period_selector.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/revenue_donut.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/status_bar_chart.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/summary_cards.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/top_services_list.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bizState = context.read<BusinessBloc>().state;

    if (bizState is! BusinessLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.purple500),
        ),
      );
    }

    final slug = bizState.active.slug;

    return BlocProvider(
      create: (ctx) => ReportsBloc(ctx.read<ReportsRepository>())
        ..add(ReportsLoadRequested(slug: slug, period: ReportPeriod.monthly)),
      child: _ReportsView(slug: slug),
    );
  }
}

class _ReportsView extends StatelessWidget {
  final String slug;

  const _ReportsView({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ReportsBloc, ReportsState>(
          listener: (ctx, state) {
            if (state is ReportsError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  action: SnackBarAction(
                    label: 'Tentar novamente',
                    onPressed: () {
                      ctx
                          .read<ReportsBloc>()
                          .add(ReportsLoadRequested(slug: slug, period: state.period));
                    },
                  ),
                ),
              );
            }
          },
          builder: (ctx, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatórios',
                          style: AppTypography.headingMd
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PeriodSelector(
                          selected: state is ReportsLoaded
                              ? state.period
                              : ReportPeriod.monthly,
                          onChanged: (period) {
                            ctx.read<ReportsBloc>().add(
                                  ReportsLoadRequested(slug: slug, period: period),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is ReportsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.purple500),
                    ),
                  ),
                if (state is ReportsLoaded)
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SummaryCards(data: state.data),
                        const SizedBox(height: AppSpacing.md),
                        DailySeriesChart(
                            series: state.data.appointments.dailySeries),
                        const SizedBox(height: AppSpacing.md),
                        StatusBarChart(
                            appointments: state.data.appointments),
                        const SizedBox(height: AppSpacing.md),
                        RevenueDonut(revenue: state.data.revenue),
                        const SizedBox(height: AppSpacing.md),
                        TopServicesList(
                            services: state.data.revenue.topServices),
                        const SizedBox(height: AppSpacing.lg),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
