import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/appointment_block.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';


const double _kInitialScrollHour = 7;

class DayView extends StatefulWidget {
  final DateTime date;
  final Map<String, List<AppointmentModel>> appointmentsByDate;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;

  const DayView({
    super.key,
    required this.date,
    required this.appointmentsByDate,
    this.onSlotTap,
    this.onAppointmentTap,
  });

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
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
    final key = DateFormat('yyyy-MM-dd').format(widget.date);
    final appointments = widget.appointmentsByDate[key] ?? [];
    final laneData = computeLanes(appointments);
    final today = DateTime.now();
    final isToday = widget.date.year == today.year &&
        widget.date.month == today.month &&
        widget.date.day == today.day;

    return SingleChildScrollView(
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
                Expanded(
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
                                  widget.date,
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
                                    : () => widget.onAppointmentTap!(
                                        item.appointment),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (isToday) const CurrentTimeLine(),
          ],
        ),
      ),
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
