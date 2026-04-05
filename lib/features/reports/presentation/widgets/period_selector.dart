import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

class PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: ReportPeriod.values.map((period) {
        final isSelected = period == selected;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(period.label),
            selected: isSelected,
            onSelected: (_) => onChanged(period),
            selectedColor: colors.primary,
            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: colors.surface,
            labelStyle: AppTypography.bodySm.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: isSelected
                ? BorderSide.none
                : BorderSide(color: colors.outline, width: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
          ),
        );
      }).toList(),
    );
  }
}
