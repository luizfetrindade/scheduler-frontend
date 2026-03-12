import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TimeColumn(),
          Expanded(
            child: SizedBox(
              height: kGridTotalHeight,
              child: GestureDetector(
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
                    ...appointments.map(
                      (a) => AppointmentBlock(
                        appointment: a,
                        onTap: widget.onAppointmentTap == null
                            ? null
                            : () => widget.onAppointmentTap!(a),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
