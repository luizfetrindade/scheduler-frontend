import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/appointment_block.dart';

/// A draggable variant of [AppointmentBlock] that keeps the exact same visual
/// appearance while the user long-presses to move it. Used by both day and
/// week views so drag-and-drop behaves identically.
///
/// When [dragEnabled] is false (or the appointment is cancelled), this falls
/// back to a plain [AppointmentBlock].
class DraggableAppointmentBlock extends StatelessWidget {
  final AppointmentModel appointment;
  final double containerWidth;
  final int lane;
  final int totalLanes;
  final bool dragEnabled;
  final VoidCallback? onTap;

  const DraggableAppointmentBlock({
    super.key,
    required this.appointment,
    required this.containerWidth,
    required this.lane,
    required this.totalLanes,
    this.dragEnabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!dragEnabled || appointment.status == AppointmentStatus.cancelled) {
      return AppointmentBlock(
        appointment: appointment,
        containerWidth: containerWidth,
        lane: lane,
        totalLanes: totalLanes,
        onTap: onTap,
      );
    }

    final layout = AppointmentBlockLayout.compute(
      appointment: appointment,
      containerWidth: containerWidth,
      lane: lane,
      totalLanes: totalLanes,
    );

    final card = AppointmentBlockContent(
      appointment: appointment,
      isCompact: layout.isCompact,
    );

    return Positioned(
      top: layout.top,
      left: layout.left,
      width: layout.width,
      height: layout.height,
      child: LongPressDraggable<AppointmentModel>(
        data: appointment,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: _DragFeedback(
          width: layout.width,
          height: layout.height,
          child: card,
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

/// Wraps the drag feedback in a [Material] + subtle elevation and a gentle
/// wiggle animation so the user gets a clear "picked up" signal while keeping
/// the card's real size and look.
class _DragFeedback extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _DragFeedback({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _WiggleAnimation(
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }
}

/// Oscillating rotation applied to the drag feedback to visually signal
/// "edit mode" while the card is being moved — similar to the iOS home-screen
/// jiggle.
class _WiggleAnimation extends StatefulWidget {
  final Widget child;
  const _WiggleAnimation({required this.child});

  @override
  State<_WiggleAnimation> createState() => _WiggleAnimationState();
}

class _WiggleAnimationState extends State<_WiggleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _rotation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (_, child) => Transform.rotate(
        angle: _rotation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
