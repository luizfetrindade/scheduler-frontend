import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/appointment_model.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/time_grid.dart';

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
    final top = TimeGridPositioner.topOffset(appointment.startsAt);
    final height = TimeGridPositioner.blockHeight(
      appointment.startsAt,
      appointment.endsAt,
    );
    final clampedHeight = height.clamp(20.0, double.infinity);

    const outerGap = 2.0;
    const innerGap = 2.0;
    final laneWidth = (containerWidth - outerGap * 2) / totalLanes;
    final left = outerGap + lane * laneWidth;
    final width = laneWidth - (lane < totalLanes - 1 ? innerGap : 0);

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: clampedHeight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(
              left: BorderSide(
                color: _borderColor(context),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
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
                  if (clampedHeight > 36 && _secondaryLabel != null)
                    Flexible(
                      child: Text(
                        _secondaryLabel!,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          ),
        ),
      ),
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
    if (appointment.isBlock) {
      return appointment.title ?? 'Bloqueado';
    }
    return appointment.clientName;
  }

  String? get _secondaryLabel {
    if (appointment.isBlock) {
      return appointment.notes;
    }
    return appointment.serviceName;
  }
}
