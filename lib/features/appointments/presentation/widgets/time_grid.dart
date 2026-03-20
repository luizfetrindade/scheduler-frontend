import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';

const int kStartHour = 0;
const int kEndHour = 24;
const double kSlotHeight = 60.0;
const double kTimeColumnWidth = 52.0;
const double kGridTotalHeight = (kEndHour - kStartHour) * kSlotHeight;

typedef LaneData = ({AppointmentModel appointment, int lane, int totalLanes});

List<LaneData> computeLanes(List<AppointmentModel> appointments) {
  final sorted = [...appointments]
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  final lanes = <List<AppointmentModel>>[];
  final laneOf = <AppointmentModel, int>{};

  for (final appt in sorted) {
    var assigned = -1;
    for (var i = 0; i < lanes.length; i++) {
      if (!lanes[i].last.endsAt.isAfter(appt.startsAt)) {
        assigned = i;
        lanes[i].add(appt);
        break;
      }
    }
    if (assigned == -1) {
      assigned = lanes.length;
      lanes.add([appt]);
    }
    laneOf[appt] = assigned;
  }

  return sorted.map((appt) {
    final lane = laneOf[appt]!;
    var maxLane = lane;
    for (final other in sorted) {
      if (identical(other, appt)) continue;
      if (appt.startsAt.isBefore(other.endsAt) &&
          other.startsAt.isBefore(appt.endsAt)) {
        final ol = laneOf[other]!;
        if (ol > maxLane) maxLane = ol;
      }
    }
    return (appointment: appt, lane: lane, totalLanes: maxLane + 1);
  }).toList();
}

class TimeGridPositioner {
  const TimeGridPositioner._();

  static double topOffset(DateTime startsAt) {
    final minutes = (startsAt.hour - kStartHour) * 60 + startsAt.minute;
    return (minutes / 60) * kSlotHeight;
  }

  static double blockHeight(DateTime startsAt, DateTime endsAt) {
    final duration = endsAt.difference(startsAt).inMinutes;
    return (duration / 60) * kSlotHeight;
  }
}

class TimeColumn extends StatelessWidget {
  const TimeColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kTimeColumnWidth,
      height: kGridTotalHeight,
      child: Stack(
        children: List.generate(kEndHour - kStartHour, (i) {
          final hour = kStartHour + i;
          final label =
              '${hour.toString().padLeft(2, '0')}:00';
          return Positioned(
            top: i * kSlotHeight + 2,
            left: 0,
            right: 4,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          );
        }),
      ),
    );
  }
}

class SlotGrid extends StatelessWidget {
  const SlotGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kGridTotalHeight,
      child: Column(
        children: List.generate(kEndHour - kStartHour, (i) {
          return Container(
            height: kSlotHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.appColors.outline,
                  width: 1.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Horizontal indicator of the current time. Must be placed inside a [Stack]
/// that spans [kGridTotalHeight]. Refreshes every minute automatically.
class CurrentTimeLine extends StatefulWidget {
  const CurrentTimeLine({super.key});

  @override
  State<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends State<CurrentTimeLine> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = TimeGridPositioner.topOffset(_now);
    return Positioned(
      // center the 8px dot on the hour line
      top: top - 4,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
