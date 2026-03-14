import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_repository.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/appointment_detail_sheet.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/create_appointment_sheet.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/create_block_sheet.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/day_view.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/schedule_toolbar.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/week_view.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_filter_chips.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repo = context.read<AppointmentRepository>();
        final bloc = ScheduleBloc(repo);
        final bizState = context.read<BusinessBloc>().state;
        if (bizState is BusinessLoaded) {
          bloc.add(ScheduleInitialized(
            slug: bizState.active.slug,
            date: DateTime.now(),
          ));
        }
        return bloc;
      },
      child: const AppointmentsBody(),
    );
  }
}

class AppointmentsBody extends StatelessWidget {
  const AppointmentsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        onPressed: () => _showFabOptions(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<BusinessBloc, BusinessState>(
              listener: (context, state) {
                if (state is BusinessLoaded) {
                  context.read<ScheduleBloc>().add(ScheduleInitialized(
                        slug: state.active.slug,
                        date: DateTime.now(),
                      ));
                }
              },
            ),
            BlocListener<ScheduleBloc, ScheduleState>(
              listener: (context, state) {
                if (state is ScheduleActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _reload(context, state.selectedDate, state.viewMode);
                } else if (state is ScheduleActionFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  _reload(context, state.selectedDate, state.viewMode);
                }
              },
            ),
          ],
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final targetMode =
                  isWide ? ScheduleViewMode.week : ScheduleViewMode.day;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context
                      .read<ScheduleBloc>()
                      .add(ScheduleViewModeChanged(targetMode));
                }
              });

              return BlocBuilder<ScheduleBloc, ScheduleState>(
                buildWhen: (prev, curr) =>
                    curr is! ScheduleActionSuccess &&
                    curr is! ScheduleActionFailure,
                builder: (context, state) {
                  return switch (state) {
                    ScheduleInitial() => Center(
                        child: CircularProgressIndicator(
                          color: context.appColors.primary,
                        ),
                      ),
                    ScheduleLoading(:final selectedDate, :final viewMode) =>
                      _buildContent(
                        context,
                        selectedDate: selectedDate,
                        viewMode: viewMode,
                        appointmentsByDate: const {},
                        isLoading: true,
                      ),
                    ScheduleLoaded(
                      :final selectedDate,
                      :final viewMode,
                      :final appointmentsByDate,
                    ) =>
                      _buildContent(
                        context,
                        selectedDate: selectedDate,
                        viewMode: viewMode,
                        appointmentsByDate: appointmentsByDate,
                        isLoading: false,
                      ),
                    ScheduleError(
                      :final message,
                      :final selectedDate,
                      :final viewMode,
                    ) =>
                      _buildError(context, message, selectedDate, viewMode),
                    ScheduleActionSuccess(:final selectedDate, :final viewMode)
                      =>
                      _buildContent(
                        context,
                        selectedDate: selectedDate,
                        viewMode: viewMode,
                        appointmentsByDate: const {},
                        isLoading: true,
                      ),
                    ScheduleActionFailure(:final selectedDate, :final viewMode)
                      =>
                      _buildContent(
                        context,
                        selectedDate: selectedDate,
                        viewMode: viewMode,
                        appointmentsByDate: const {},
                        isLoading: true,
                      ),
                  };
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _reload(
    BuildContext context,
    DateTime date,
    ScheduleViewMode viewMode,
  ) {
    final bizState = context.read<BusinessBloc>().state;
    if (bizState is BusinessLoaded) {
      context.read<ScheduleBloc>().add(ScheduleInitialized(
            slug: bizState.active.slug,
            date: date,
          ));
    }
  }

  Widget _buildContent(
    BuildContext context, {
    required DateTime selectedDate,
    required ScheduleViewMode viewMode,
    required Map<String, List<AppointmentModel>> appointmentsByDate,
    required bool isLoading,
  }) {
    final bloc = context.read<ScheduleBloc>();

    final profsState = context.read<ProfessionalsBloc>().state;
    final professionals = switch (profsState) {
      ProfessionalsLoaded(:final professionals) => professionals,
      ProfessionalsActionInProgress(:final professionals) => professionals,
      _ => <ProfessionalModel>[],
    };

    return Column(
      children: [
        ScheduleToolbar(
          selectedDate: selectedDate,
          viewMode: viewMode,
          onPrevious: () => bloc.add(const SchedulePreviousPeriod()),
          onNext: () => bloc.add(const ScheduleNextPeriod()),
          onDateSelected: (date) => bloc.add(ScheduleDateSelected(date)),
        ),
        if (professionals.isNotEmpty)
          ProfessionalFilterChips(professionals: professionals),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.appColors.primary,
                  ),
                )
              : viewMode == ScheduleViewMode.day
                  ? DayView(
                      date: selectedDate,
                      appointmentsByDate: appointmentsByDate,
                      onSlotTap: (dt) => _openCreateSheet(context, dt),
                      onAppointmentTap: (a) =>
                          _openDetailSheet(context, a),
                    )
                  : WeekView(
                      selectedDate: selectedDate,
                      appointmentsByDate: appointmentsByDate,
                      onSlotTap: (dt) => _openCreateSheet(context, dt),
                      onAppointmentTap: (a) =>
                          _openDetailSheet(context, a),
                    ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    String message,
    DateTime selectedDate,
    ScheduleViewMode viewMode,
  ) {
    final bloc = context.read<ScheduleBloc>();

    return Column(
      children: [
        ScheduleToolbar(
          selectedDate: selectedDate,
          viewMode: viewMode,
          onPrevious: () => bloc.add(const SchedulePreviousPeriod()),
          onNext: () => bloc.add(const ScheduleNextPeriod()),
          onDateSelected: (date) => bloc.add(ScheduleDateSelected(date)),
        ),
        Expanded(
          child: Center(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

void _openCreateSheet(BuildContext context, DateTime dateTime) {
  final bloc = context.read<ScheduleBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: CreateAppointmentSheet(initialDateTime: dateTime),
    ),
  );
}

void _showFabOptions(BuildContext context) {
  final bloc = context.read<ScheduleBloc>();
  showModalBottomSheet(
    context: context,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'O que deseja criar?',
              style: AppTypography.headingMd.copyWith(
                color: sheetContext.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.event, color: sheetContext.appColors.primary),
              title: Text(
                'Novo Agendamento',
                style: AppTypography.bodySm.copyWith(
                  color: sheetContext.appColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Agendar um horário para um cliente',
                style: AppTypography.caption.copyWith(
                  color: sheetContext.appColors.textSecondary,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              tileColor: sheetContext.appColors.surface,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openCreateSheet(context, DateTime.now());
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.blocked),
              title: Text(
                'Bloquear Horário',
                style: AppTypography.bodySm.copyWith(
                  color: sheetContext.appColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Marcar horário como indisponível',
                style: AppTypography.caption.copyWith(
                  color: sheetContext.appColors.textSecondary,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              tileColor: sheetContext.appColors.surface,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openBlockSheet(context, DateTime.now());
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _openBlockSheet(BuildContext context, DateTime dateTime) {
  final bloc = context.read<ScheduleBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: CreateBlockSheet(initialDateTime: dateTime),
    ),
  );
}

void _openDetailSheet(BuildContext context, AppointmentModel appointment) {
  final bloc = context.read<ScheduleBloc>();
  showModalBottomSheet(
    context: context,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: AppointmentDetailSheet(appointment: appointment),
    ),
  );
}
