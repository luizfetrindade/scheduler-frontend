import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/draggable_appointment_block.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';

double _currentScrollHour() {
  final now = DateTime.now();
  return (now.hour - 1).clamp(0, 23).toDouble();
}

class WeekView extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, List<AppointmentModel>> appointmentsByDate;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;
  final bool dragEnabled;
  final void Function(AppointmentModel appointment, DateTime newStart)?
      onAppointmentDropped;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.appointmentsByDate,
    this.onSlotTap,
    this.onAppointmentTap,
    this.dragEnabled = false,
    this.onAppointmentDropped,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = _currentScrollHour() * kSlotHeight;
        _scrollController.jumpTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    });
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
                                return _WeekDayColumn(
                                  baseDate: day,
                                  containerWidth: containerWidth,
                                  laneData: laneData,
                                  onSlotTap: widget.onSlotTap,
                                  onAppointmentTap: widget.onAppointmentTap,
                                  dragEnabled: widget.dragEnabled,
                                  onAppointmentDropped:
                                      widget.onAppointmentDropped,
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
}

/// A single day column within the week grid.
class _WeekDayColumn extends StatelessWidget {
  final DateTime baseDate;
  final double containerWidth;
  final List<LaneData> laneData;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;
  final bool dragEnabled;
  final void Function(AppointmentModel, DateTime)? onAppointmentDropped;

  const _WeekDayColumn({
    required this.baseDate,
    required this.containerWidth,
    required this.laneData,
    this.onSlotTap,
    this.onAppointmentTap,
    this.dragEnabled = false,
    this.onAppointmentDropped,
  });

  DateTime _timeFromOffset(double dy) {
    final totalMinutes = (dy / kSlotHeight) * 60;
    final snapped = ((totalMinutes + kStartHour * 60) / 15).round() * 15;
    final hour = (snapped ~/ 60).clamp(kStartHour, kEndHour);
    final minute = snapped % 60;
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: onSlotTap == null
          ? null
          : (details) => onSlotTap!(_timeFromOffset(details.localPosition.dy)),
      child: Stack(
        children: [
          const SlotGrid(),
          ...laneData.map(
            (item) => DraggableAppointmentBlock(
              appointment: item.appointment,
              containerWidth: containerWidth,
              lane: item.lane,
              totalLanes: item.totalLanes,
              dragEnabled: dragEnabled,
              onTap: onAppointmentTap == null
                  ? null
                  : () => onAppointmentTap!(item.appointment),
            ),
          ),
        ],
      ),
    );

    if (dragEnabled && onAppointmentDropped != null) {
      final content = body;
      body = Builder(
        builder: (innerContext) => DragTarget<AppointmentModel>(
          onAcceptWithDetails: (details) {
            final renderBox = innerContext.findRenderObject() as RenderBox;
            final local = renderBox.globalToLocal(details.offset);
            final newStart = _timeFromOffset(local.dy);
            onAppointmentDropped!(details.data, newStart);
          },
          builder: (context, candidateData, rejectedData) => content,
        ),
      );
    }

    return body;
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
              color: isToday ? context.appColors.primary : null,
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
