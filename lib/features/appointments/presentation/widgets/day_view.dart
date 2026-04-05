import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/draggable_appointment_block.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';

double _currentScrollHour() {
  final now = DateTime.now();
  // Scroll to 1 hour before current time so the current time line is visible
  return (now.hour - 1).clamp(0, 23).toDouble();
}

class DayView extends StatefulWidget {
  final DateTime date;
  final Map<String, List<AppointmentModel>> appointmentsByDate;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;
  final bool dragEnabled;
  final void Function(AppointmentModel appointment, DateTime newStart)?
      onAppointmentDropped;

  const DayView({
    super.key,
    required this.date,
    required this.appointmentsByDate,
    this.onSlotTap,
    this.onAppointmentTap,
    this.dragEnabled = false,
    this.onAppointmentDropped,
  });

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
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
                      return _DayColumn(
                        baseDate: widget.date,
                        containerWidth: containerWidth,
                        laneData: laneData,
                        onSlotTap: widget.onSlotTap,
                        onAppointmentTap: widget.onAppointmentTap,
                        dragEnabled: widget.dragEnabled,
                        onAppointmentDropped: widget.onAppointmentDropped,
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
}

/// A single day column that optionally acts as a DragTarget.
class _DayColumn extends StatelessWidget {
  final DateTime baseDate;
  final double containerWidth;
  final List<LaneData> laneData;
  final ValueChanged<DateTime>? onSlotTap;
  final ValueChanged<AppointmentModel>? onAppointmentTap;
  final bool dragEnabled;
  final void Function(AppointmentModel, DateTime)? onAppointmentDropped;

  const _DayColumn({
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
