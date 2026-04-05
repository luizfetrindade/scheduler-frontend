import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';

/// Layout metrics for positioning an appointment within a day column.
class AppointmentBlockLayout {
  final double top;
  final double left;
  final double width;
  final double height;
  final bool isCompact;

  const AppointmentBlockLayout({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.isCompact,
  });

  factory AppointmentBlockLayout.compute({
    required AppointmentModel appointment,
    required double containerWidth,
    required int lane,
    required int totalLanes,
  }) {
    final top = TimeGridPositioner.topOffset(appointment.startsAt);
    final rawHeight = TimeGridPositioner.blockHeight(
      appointment.startsAt,
      appointment.endsAt,
    );
    final height = rawHeight.clamp(20.0, double.infinity);

    const outerGap = 2.0;
    const innerGap = 2.0;
    final laneWidth = (containerWidth - outerGap * 2) / totalLanes;
    final left = outerGap + lane * laneWidth;
    final width = laneWidth - (lane < totalLanes - 1 ? innerGap : 0);

    return AppointmentBlockLayout(
      top: top,
      left: left,
      width: width,
      height: height,
      isCompact: height < 36,
    );
  }
}

class AppointmentBlock extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final int lane;
  final int totalLanes;
  final double containerWidth;

  const AppointmentBlock({
    super.key,
    required this.appointment,
    required this.containerWidth,
    this.onTap,
    this.lane = 0,
    this.totalLanes = 1,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppointmentBlockLayout.compute(
      appointment: appointment,
      containerWidth: containerWidth,
      lane: lane,
      totalLanes: totalLanes,
    );

    return Positioned(
      top: layout.top,
      left: layout.left,
      width: layout.width,
      height: layout.height,
      child: GestureDetector(
        onTap: onTap,
        child: AppointmentBlockContent(
          appointment: appointment,
          isCompact: layout.isCompact,
        ),
      ),
    );
  }
}

/// The visual card content for an appointment, without any positioning wrapper.
///
/// Used directly by [AppointmentBlock] and reused as the drag feedback / child
/// inside draggable wrappers so the card keeps the exact same appearance while
/// being moved.
class AppointmentBlockContent extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCompact;

  const AppointmentBlockContent({
    super.key,
    required this.appointment,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _borderColor(context);
    return appointment.isBlock
        ? _buildBlockCard(context, 0, isCompact, borderColor)
        : _buildAppointmentCard(context, 0, isCompact, borderColor);
  }

  /// Regular appointment card — solid surface background with a colored left border.
  Widget _buildAppointmentCard(
    BuildContext context,
    double clampedHeight,
    bool isCompact,
    Color borderColor,
  ) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(
          left: BorderSide(color: borderColor, width: 3),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: isCompact ? 1 : AppSpacing.xs,
      ),
      child: _content(context, clampedHeight, isCompact),
    );
  }

  /// Block card — distinct visual: hatched pattern with blocked-color tint.
  Widget _buildBlockCard(
    BuildContext context,
    double clampedHeight,
    bool isCompact,
    Color borderColor,
  ) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.blocked.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.blocked.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // Diagonal stripe pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalStripesPainter(
                color: AppColors.blocked.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: isCompact ? 1 : AppSpacing.xs,
            ),
            child: _content(context, clampedHeight, isCompact),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, double clampedHeight, bool isCompact) {
    if (isCompact) {
      // Single-line layout for very short blocks — prevents vertical clipping
      return Row(
        children: [
          if (appointment.isBlock)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.block, size: 10, color: AppColors.blocked),
            ),
          Expanded(
            child: Text(
              _primaryLabel,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (appointment.isRecurring)
            Icon(Icons.repeat, size: 9, color: context.appColors.textSecondary),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (appointment.isBlock)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.block, size: 11, color: AppColors.blocked),
                  ),
                Expanded(
                  child: Text(
                    _primaryLabel,
                    style: AppTypography.caption.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_secondaryLabel != null)
              Text(
                _secondaryLabel!,
                style: AppTypography.caption.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        if (appointment.isRecurring)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.repeat,
              size: 10,
              color: context.appColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Color _borderColor(BuildContext context) {
    if (appointment.isBlock) return AppColors.blocked;
    return switch (appointment.status) {
      AppointmentStatus.pending => context.appColors.primary,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => const Color(0xFFF59E0B),
      AppointmentStatus.completed => context.appColors.textSecondary,
    };
  }

  String get _primaryLabel {
    if (appointment.isBlock) return appointment.title ?? 'Bloqueado';
    return appointment.clientName;
  }

  String? get _secondaryLabel {
    if (appointment.isBlock) return appointment.notes;
    return appointment.serviceName;
  }
}

/// Paints diagonal stripes for the block card pattern.
class _DiagonalStripesPainter extends CustomPainter {
  final Color color;
  _DiagonalStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const gap = 10.0;
    final steps = ((size.width + size.height) / gap).ceil();
    for (var i = 0; i < steps; i++) {
      final offset = i * gap;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(0, offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripesPainter old) => old.color != color;
}
