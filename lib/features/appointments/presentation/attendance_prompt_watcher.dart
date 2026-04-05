import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';
import 'package:scheduler_frontend/core/auth/auth_state.dart';
import 'package:scheduler_frontend/core/config/schedule_preferences.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/appointments_state.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/attendance_prompt_dialog.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_bloc.dart';
import 'package:scheduler_frontend/features/professionals/bloc/professionals_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

/// Watches loaded appointments and shows a global dialog asking about
/// attendance right after each appointment ends.
///
/// Rules:
/// - Appointment must be ended (`endsAt <= now`).
/// - Status must be pending or confirmed (resolved states are skipped).
/// - Blocks are ignored.
/// - Non-admins only see prompts for appointments assigned to them.
/// - Dismissed appointments ("Depois") are skipped until the app restarts or
///   appointments are refetched with a new status.
/// - Feature can be toggled off via [SchedulePreferences.isAttendancePromptEnabled].
class AttendancePromptWatcher extends StatefulWidget {
  final Widget child;

  const AttendancePromptWatcher({super.key, required this.child});

  @override
  State<AttendancePromptWatcher> createState() =>
      _AttendancePromptWatcherState();
}

class _AttendancePromptWatcherState extends State<AttendancePromptWatcher> {
  Timer? _ticker;
  final Set<String> _dismissedIds = {};
  bool _dialogOpen = false;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadPreference() async {
    final enabled = await SchedulePreferences.isAttendancePromptEnabled();
    if (mounted) {
      setState(() => _enabled = enabled);
      _tick();
    }
  }

  /// Exposed so the settings page can trigger a refresh after toggling.
  Future<void> refreshPreference() => _loadPreference();

  void _tick() {
    if (!mounted || !_enabled || _dialogOpen) return;

    final appointmentsState = context.read<AppointmentsBloc>().state;
    if (appointmentsState is! AppointmentsLoaded) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;

    final isAdmin = businessState.policy.isAdmin;
    final myProfId = isAdmin ? null : _findMyProfessionalId();

    // Non-admin with no linked professional → nothing to prompt about.
    if (!isAdmin && myProfId == null) return;

    final now = DateTime.now();
    final eligible = appointmentsState.appointments.firstWhere(
      (a) => _isEligible(a, now: now, isAdmin: isAdmin, myProfId: myProfId),
      orElse: () => _noneSentinel,
    );

    if (identical(eligible, _noneSentinel)) return;

    _showPrompt(eligible, slug: businessState.active.slug);
  }

  bool _isEligible(
    AppointmentModel a, {
    required DateTime now,
    required bool isAdmin,
    required String? myProfId,
  }) {
    if (a.isBlock) return false;
    if (_dismissedIds.contains(a.id)) return false;
    if (!a.endsAt.isBefore(now) && a.endsAt != now) return false;
    if (a.status != AppointmentStatus.pending &&
        a.status != AppointmentStatus.confirmed) {
      return false;
    }
    if (!isAdmin && a.staffId != myProfId) return false;
    return true;
  }

  String? _findMyProfessionalId() {
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

  Future<void> _showPrompt(
    AppointmentModel appointment, {
    required String slug,
  }) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final result = await showDialog<AttendancePromptResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AttendancePromptDialog(appointment: appointment),
    );

    _dialogOpen = false;
    if (!mounted) return;

    switch (result) {
      case AttendancePromptResult.attended:
        _dispatchStatus(
          slug: slug,
          id: appointment.id,
          status: AppointmentStatus.completed,
        );
      case AttendancePromptResult.noShow:
        _dispatchStatus(
          slug: slug,
          id: appointment.id,
          status: AppointmentStatus.noShow,
        );
      case AttendancePromptResult.later:
      case null:
        _dismissedIds.add(appointment.id);
    }

    // Check if another appointment is also eligible.
    _tick();
  }

  void _dispatchStatus({
    required String slug,
    required String id,
    required AppointmentStatus status,
  }) {
    context.read<AppointmentsBloc>().add(
          AppointmentStatusChanged(
            slug: slug,
            appointmentId: id,
            status: status,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Re-check whenever appointments list changes (e.g. after refresh).
        BlocListener<AppointmentsBloc, AppointmentsState>(
          listenWhen: (prev, curr) => curr is AppointmentsLoaded,
          listener: (_, state) => _tick(),
        ),
        // Clear in-memory dismissals on logout.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (_, curr) => curr is AuthUnauthenticated,
          listener: (_, state) => _dismissedIds.clear(),
        ),
      ],
      child: widget.child,
    );
  }
}

/// Sentinel returned by `firstWhere` when no eligible appointment exists.
final AppointmentModel _noneSentinel = AppointmentModel(
  id: '__none__',
  startsAt: DateTime(1970),
  endsAt: DateTime(1970),
  status: AppointmentStatus.pending,
  clientName: '',
);
