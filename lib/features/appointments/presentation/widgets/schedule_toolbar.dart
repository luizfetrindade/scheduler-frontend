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
  final ValueChanged<ScheduleViewMode>? onViewModeChanged;

  const ScheduleToolbar({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
    this.onViewModeChanged,
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
            icon: Icon(Icons.chevron_left,
                color: context.appColors.textPrimary),
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
            icon: Icon(Icons.chevron_right,
                color: context.appColors.textPrimary),
            onPressed: onNext,
          ),
          if (onViewModeChanged != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _ViewModeToggle(
              current: viewMode,
              onChanged: onViewModeChanged!,
            ),
          ],
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

/// Day / Week toggle button pair.
class _ViewModeToggle extends StatelessWidget {
  final ScheduleViewMode current;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ViewModeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem(
            context,
            icon: Icons.view_day_outlined,
            tooltip: 'Diário',
            mode: ScheduleViewMode.day,
          ),
          _toggleItem(
            context,
            icon: Icons.view_week_outlined,
            tooltip: 'Semanal',
            mode: ScheduleViewMode.week,
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required ScheduleViewMode mode,
  }) {
    final isActive = current == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: Container(
          width: 34,
          height: 34,
          color: isActive ? context.appColors.primary : Colors.transparent,
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Horizontal chip row for toggling which statuses are visible on the schedule.
class StatusFilterBar extends StatelessWidget {
  final Set<String> hiddenStatuses;
  final ValueChanged<String> onToggle;
  final VoidCallback? onToggleAll;

  const StatusFilterBar({
    super.key,
    required this.hiddenStatuses,
    required this.onToggle,
    this.onToggleAll,
  });

  static const _filters = [
    ('pending', 'Pendentes', Icons.schedule),
    ('confirmed', 'Confirmados', Icons.check_circle_outline),
    ('cancelled', 'Cancelados', Icons.cancel_outlined),
    ('completed', 'Concluídos', Icons.task_alt),
    ('noShow', 'Ausentes', Icons.person_off_outlined),
    ('block', 'Bloqueios', Icons.block),
  ];

  static const allKeys = [
    'pending',
    'confirmed',
    'cancelled',
    'completed',
    'noShow',
    'block',
  ];

  @override
  Widget build(BuildContext context) {
    final allVisible = hiddenStatuses.isEmpty;
    final totalItems = _filters.length + 1; // +1 for "Tudo"

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: totalItems,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _buildChip(
              context,
              icon: Icons.select_all,
              label: 'Tudo',
              isActive: allVisible,
              onTap: () => onToggleAll?.call(),
            );
          }
          final (key, label, icon) = _filters[i - 1];
          final isVisible = !hiddenStatuses.contains(key);
          return _buildChip(
            context,
            icon: icon,
            label: label,
            isActive: isVisible,
            onTap: () => onToggle(key),
          );
        },
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? context.appColors.primary
              : context.appColors.surface,
          border: Border.all(
            color: isActive
                ? context.appColors.primary
                : context.appColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.appColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.appColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
