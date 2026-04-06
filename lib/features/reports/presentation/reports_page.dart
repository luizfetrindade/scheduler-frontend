import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_bloc.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_event.dart';
import 'package:scheduler_frontend/features/reports/bloc/reports_state.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/data/reports_repository.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/period_selector.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_general_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_financial_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_appointments_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_clients_tab.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/tabs/reports_staff_tab.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bizState = context.read<BusinessBloc>().state;

    if (bizState is! BusinessLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final slug = bizState.active.slug;

    return BlocProvider(
      create: (ctx) => ReportsBloc(ctx.read<ReportsRepository>())
        ..add(ReportsLoadRequested(slug: slug, period: ReportPeriod.monthly)),
      child: ReportsView(slug: slug),
    );
  }
}

@visibleForTesting
class ReportsView extends StatelessWidget {
  final String slug;
  const ReportsView({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {},
        builder: (context, state) {
          final currentPeriod = state is ReportsLoaded
              ? state.period
              : state is ReportsError
                  ? state.period
                  : ReportPeriod.monthly;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Relatórios'),
              bottom: state is ReportsLoaded
                  ? const TabBar(
                      tabs: [
                        Tab(text: 'Geral'),
                        Tab(text: 'Financeiro'),
                        Tab(text: 'Agenda'),
                        Tab(text: 'Clientes'),
                        Tab(text: 'Equipe'),
                      ],
                    )
                  : null,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PeriodSelector(
                        selected: currentPeriod,
                        onChanged: (p) =>
                            context.read<ReportsBloc>().add(
                                  ReportsLoadRequested(slug: slug, period: p),
                                ),
                      ),
                      if (state is ReportsLoaded) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _comparisonLabel(
                              state.data.from, state.data.previousFrom),
                          style: AppTypography.caption.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (state is ReportsLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is ReportsLoaded)
                  Expanded(
                    child: TabBarView(
                      children: [
                        ReportsGeneralTab(model: state.data),
                        ReportsFinancialTab(model: state.data),
                        ReportsAppointmentsTab(model: state.data),
                        ReportsClientsTab(model: state.data),
                        ReportsStaffTab(model: state.data),
                      ],
                    ),
                  )
                else if (state is ReportsError)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                context.read<ReportsBloc>().add(
                                      ReportsLoadRequested(
                                        slug: slug,
                                        period: state.period,
                                      ),
                                    ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state is ReportsInitial)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        },
      ),
    );
  }

  String _comparisonLabel(String from, String previousFrom) {
    final fmt = DateFormat('MMMM yyyy', 'pt_BR');
    try {
      final current = fmt.format(DateTime.parse(from));
      final previous = fmt.format(DateTime.parse(previousFrom));
      return '$current vs. $previous';
    } catch (_) {
      return '';
    }
  }
}
