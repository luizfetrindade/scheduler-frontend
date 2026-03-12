import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';

class ScheduleToolbar extends StatelessWidget {
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;

  const ScheduleToolbar({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: context.appColors.textPrimary),
            onPressed: onPrevious,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(context),
              child: Text(
                _label(),
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: context.appColors.textPrimary),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }

  String _label() {
    if (viewMode == ScheduleViewMode.day) {
      return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(selectedDate);
    }
    final monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start = DateFormat("d MMM", 'pt_BR').format(monday);
    final end = DateFormat("d MMM yyyy", 'pt_BR').format(sunday);
    return '$start – $end';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.appColors.primary,
              surface: context.appColors.surface,
              onSurface: context.appColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
