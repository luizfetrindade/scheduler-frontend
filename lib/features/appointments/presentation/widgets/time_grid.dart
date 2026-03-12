import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

const int kStartHour = 0;
const int kEndHour = 24;
const double kSlotHeight = 60.0;
const double kTimeColumnWidth = 52.0;
const double kGridTotalHeight = (kEndHour - kStartHour) * kSlotHeight;

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
            top: i * kSlotHeight - 7,
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
                  color: context.appColors.surfaceHigh,
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
