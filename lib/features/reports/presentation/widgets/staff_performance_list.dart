import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class StaffPerformanceList extends StatelessWidget {
  final List<StaffReport> staff;
  const StaffPerformanceList({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return Center(
        child: Text(
          'Nenhum dado de equipe disponível',
          style: AppTypography.bodyMd.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: staff.map((s) => _StaffCard(staff: s)).toList(),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffReport staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initials = staff.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final avatarColor =
        Color(int.parse(staff.color.replaceFirst('#', '0xFF')));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BaseCard(
        padding: AppSpacing.md,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 20,
              child: Text(
                initials,
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: AppTypography.bodySm.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (staff.roleName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      staff.roleName!,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${staff.revenue.toStringAsFixed(0)}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.appointments} agend. · ${(staff.completionRate * 100).round()}%',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
