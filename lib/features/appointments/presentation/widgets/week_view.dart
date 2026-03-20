import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/appointment_block.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';

const double _kInitialScrollHour = 7;

class WeekView extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, List<AppointmentModel>> appointmentsByDate;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.appointmentsByDate,
    this.onSlotTap,
    this.onAppointmentTap,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _kInitialScrollHour * kSlotHeight,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monday = widget.selectedDate
        .subtract(Duration(days: widget.selectedDate.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final today = DateTime.now();

    return Column(
      children: [
        _WeekHeader(days: days, today: today),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: SizedBox(
              height: kGridTotalHeight,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TimeColumn(),
                      ...days.map((day) {
                        final key = DateFormat('yyyy-MM-dd').format(day);
                        final appointments =
                            widget.appointmentsByDate[key] ?? [];
                        final isToday = day.year == today.year &&
                            day.month == today.month &&
                            day.day == today.day;
                        final laneData = computeLanes(appointments);
                        return Expanded(
                          child: Container(
                            height: kGridTotalHeight,
                            color: isToday
                                ? context.appColors.primaryDark
                                    .withValues(alpha: 0.06)
                                : null,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final containerWidth = constraints.maxWidth;
                                return GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: widget.onSlotTap == null
                                      ? null
                                      : (details) {
                                          final tappedTime = _timeFromOffset(
                                            details.localPosition.dy,
                                            day,
                                          );
                                          widget.onSlotTap!(tappedTime);
                                        },
                                  child: Stack(
                                    children: [
                                      const SlotGrid(),
                                      ...laneData.map(
                                        (item) => AppointmentBlock(
                                          appointment: item.appointment,
                                          containerWidth: containerWidth,
                                          lane: item.lane,
                                          totalLanes: item.totalLanes,
                                          onTap: widget.onAppointmentTap == null
                                              ? null
                                              : () =>
                                                  widget.onAppointmentTap!(
                                                      item.appointment),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  if (days.any((d) =>
                      d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day))
                    const CurrentTimeLine(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime _timeFromOffset(double dy, DateTime baseDate) {
    final totalMinutes = (dy / kSlotHeight) * 60;
    final snapped = ((totalMinutes + kStartHour * 60) / 15).round() * 15;
    final hour = (snapped ~/ 60).clamp(kStartHour, kEndHour);
    final minute = snapped % 60;
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}

class _WeekHeader extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;

  const _WeekHeader({required this.days, required this.today});

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

    return Row(
      children: [
        const SizedBox(width: kTimeColumnWidth),
        ...List.generate(7, (i) {
          final day = days[i];
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: isToday
                  ? BoxDecoration(
                      color: context.appColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    dayLabels[i],
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
