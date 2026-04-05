import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/config/schedule_preferences.dart';
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
          if (!bizState.policy.isAdmin) {
            final myProfId = _findMyProfessionalId(context);
            if (myProfId != null) {
              bloc.add(ScheduleFilterByProfessional(myProfId));
            }
          }
        }
        return bloc;
      },
      child: const AppointmentsBody(),
    );
  }
}

class AppointmentsBody extends StatefulWidget {
  const AppointmentsBody({super.key});

  @override
  State<AppointmentsBody> createState() => _AppointmentsBodyState();
}

class _AppointmentsBodyState extends State<AppointmentsBody> {
  /// Statuses hidden from the view. Cancelled is hidden by default.
  final Set<String> _hiddenStatuses = {};

  /// Whether drag-and-drop is enabled (loaded from preferences).
  bool _dragEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadDragPreference();
  }

  Future<void> _loadDragPreference() async {
    final enabled = await SchedulePreferences.isDragEnabled();
    if (mounted) setState(() => _dragEnabled = enabled);
  }

  void _toggleStatus(String key) {
    setState(() {
      if (_hiddenStatuses.contains(key)) {
        _hiddenStatuses.remove(key);
      } else {
        _hiddenStatuses.add(key);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_hiddenStatuses.isEmpty) {
        // All are visible → hide all
        _hiddenStatuses.addAll(StatusFilterBar.allKeys);
      } else {
        // Some hidden → show all
        _hiddenStatuses.clear();
      }
    });
  }

  /// Filters appointments based on hidden statuses.
  Map<String, List<AppointmentModel>> _applyStatusFilter(
    Map<String, List<AppointmentModel>> byDate,
  ) {
    if (_hiddenStatuses.isEmpty) return byDate;
    return {
      for (final entry in byDate.entries)
        entry.key: entry.value.where((a) {
          if (a.isBlock) return !_hiddenStatuses.contains('block');
          return !_hiddenStatuses.contains(a.status.name);
        }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.primary,
        onPressed: () => _showFabOptions(context),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
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
                  if (!state.policy.isAdmin) {
                    final myProfId = _findMyProfessionalId(context);
                    if (myProfId != null) {
                      context
                          .read<ScheduleBloc>()
                          .add(ScheduleFilterByProfessional(myProfId));
                    }
                  }
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
          child: BlocBuilder<ScheduleBloc, ScheduleState>(
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
                ScheduleActionSuccess(:final selectedDate, :final viewMode) =>
                  _buildContent(
                    context,
                    selectedDate: selectedDate,
                    viewMode: viewMode,
                    appointmentsByDate: const {},
                    isLoading: true,
                  ),
                ScheduleActionFailure(:final selectedDate, :final viewMode) =>
                  _buildContent(
                    context,
                    selectedDate: selectedDate,
                    viewMode: viewMode,
                    appointmentsByDate: const {},
                    isLoading: true,
                  ),
              };
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
    final filtered = _applyStatusFilter(appointmentsByDate);

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
          onViewModeChanged: (mode) =>
              bloc.add(ScheduleViewModeChanged(mode)),
        ),
        StatusFilterBar(
          hiddenStatuses: _hiddenStatuses,
          onToggle: _toggleStatus,
          onToggleAll: _toggleAll,
        ),
        const SizedBox(height: AppSpacing.xs),
        BlocBuilder<BusinessBloc, BusinessState>(
          buildWhen: (prev, curr) => curr is BusinessLoaded,
          builder: (context, state) {
            if (state is BusinessLoaded &&
                state.policy.isAdmin &&
                !state.policy.isSoloMode &&
                professionals.isNotEmpty) {
              return ProfessionalFilterChips(professionals: professionals);
            }
            return const SizedBox.shrink();
          },
        ),
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
                      appointmentsByDate: filtered,
                      onSlotTap: (dt) => _openCreateSheet(context, dt),
                      onAppointmentTap: (a) => _openDetailSheet(context, a),
                      dragEnabled: _dragEnabled,
                      onAppointmentDropped: _dragEnabled
                          ? (a, newStart) =>
                              _handleDrop(context, a, newStart)
                          : null,
                    )
                  : WeekView(
                      selectedDate: selectedDate,
                      appointmentsByDate: filtered,
                      onSlotTap: (dt) => _openCreateSheet(context, dt),
                      onAppointmentTap: (a) => _openDetailSheet(context, a),
                      dragEnabled: _dragEnabled,
                      onAppointmentDropped: _dragEnabled
                          ? (a, newStart) =>
                              _handleDrop(context, a, newStart)
                          : null,
                    ),
        ),
      ],
    );
  }

  void _handleDrop(
    BuildContext context,
    AppointmentModel appointment,
    DateTime newStart,
  ) {
    context.read<ScheduleBloc>().add(ScheduleAppointmentUpdateRequested(
          appointmentId: appointment.id,
          startsAt: newStart,
        ));
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
          onViewModeChanged: (mode) =>
              bloc.add(ScheduleViewModeChanged(mode)),
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
  final bizState = context.read<BusinessBloc>().state;
  final isAdmin = bizState is BusinessLoaded && bizState.policy.isAdmin;
  if (!isAdmin) {
    _openCreateSheet(context, DateTime.now());
    return;
  }
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
              leading:
                  Icon(Icons.event, color: sheetContext.appColors.primary),
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
              shape: const RoundedRectangleBorder(),
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
              shape: const RoundedRectangleBorder(),
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

String? _findMyProfessionalId(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthAuthenticated) return null;
  final userId = authState.user.id;
  final profsState = context.read<ProfessionalsBloc>().state;
  final professionals = switch (profsState) {
    ProfessionalsLoaded(:final professionals) => professionals,
    ProfessionalsActionInProgress(:final professionals) => professionals,
    _ => <ProfessionalModel>[],
  };
  return professionals.where((p) => p.linkedUserId == userId).firstOrNull?.id;
}

void _openDetailSheet(BuildContext context, AppointmentModel appointment) {
  final bizState = context.read<BusinessBloc>().state;
  final policy = bizState is BusinessLoaded ? bizState.policy : null;
  final myProfId = (policy != null && !policy.isAdmin)
      ? _findMyProfessionalId(context)
      : null;
  final bool canModify = policy == null ||
      policy.isAdmin ||
      (myProfId != null && appointment.staffId == myProfId);

  final bloc = context.read<ScheduleBloc>();
  showModalBottomSheet(
    context: context,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: AppointmentDetailSheet(
          appointment: appointment, canModify: canModify),
    ),
  );
}
