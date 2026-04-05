import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/data/rrule_builder.dart';

class RecurrenceSelector extends StatefulWidget {
  final ValueChanged<String?> onChanged;

  const RecurrenceSelector({super.key, required this.onChanged});

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  bool _enabled = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _interval = 1;
  final Set<WeekDay> _selectedDays = {};
  bool _useCount = true;
  int _count = 4;
  DateTime? _until;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle(),
        if (_enabled) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildFrequencyDropdown(),
          const SizedBox(height: AppSpacing.sm),
          _buildIntervalRow(),
          if (_frequency == RecurrenceFrequency.weekly) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildDaySelector(),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildEndCondition(),
        ],
      ],
    );
  }

  Widget _buildToggle() {
    return Row(
      children: [
        Icon(Icons.repeat, size: 18, color: context.appColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Repetir',
          style: AppTypography.bodySm.copyWith(color: context.appColors.textSecondary),
        ),
        const Spacer(),
        Switch(
          value: _enabled,
          activeTrackColor: context.appColors.primary,
          onChanged: (val) {
            setState(() => _enabled = val);
            _notifyChange();
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.appColors.surfaceHigh),
      ),
      child: DropdownButton<RecurrenceFrequency>(
        value: _frequency,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: context.appColors.surface,
        style: AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
        items: const [
          DropdownMenuItem(
            value: RecurrenceFrequency.daily,
            child: Text('Diariamente'),
          ),
          DropdownMenuItem(
            value: RecurrenceFrequency.weekly,
            child: Text('Semanalmente'),
          ),
          DropdownMenuItem(
            value: RecurrenceFrequency.monthly,
            child: Text('Mensalmente'),
          ),
        ],
        onChanged: (val) {
          if (val == null) return;
          setState(() => _frequency = val);
          _notifyChange();
        },
      ),
    );
  }

  Widget _buildIntervalRow() {
    final unitLabel = switch (_frequency) {
      RecurrenceFrequency.daily => 'dias',
      RecurrenceFrequency.weekly => 'semanas',
      RecurrenceFrequency.monthly => 'meses',
    };

    return Row(
      children: [
        Text(
          'A cada',
          style: AppTypography.bodySm.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: context.appColors.surfaceHigh),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: context.appColors.primary),
              ),
              filled: true,
              fillColor: context.appColors.surface,
            ),
            controller: TextEditingController(text: _interval.toString()),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null && parsed >= 1 && parsed <= 99) {
                _interval = parsed;
                _notifyChange();
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          unitLabel,
          style: AppTypography.bodySm.copyWith(color: context.appColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 4,
      children: WeekDay.values.map((day) {
        final selected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(
            day.shortLabel,
            style: AppTypography.caption.copyWith(
              color: selected ? Colors.white : context.appColors.textSecondary,
            ),
          ),
          selected: selected,
          selectedColor: context.appColors.primary,
          backgroundColor: context.appColors.surface,
          side: BorderSide(
            color: selected ? context.appColors.primary : context.appColors.surfaceHigh,
          ),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
            _notifyChange();
          },
        );
      }).toList(),
    );
  }

  Widget _buildEndCondition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildEndOption('Repetir', true),
            const SizedBox(width: AppSpacing.md),
            _buildEndOption('Até', false),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_useCount)
          Row(
            children: [
              SizedBox(
                width: 56,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm
                      .copyWith(color: context.appColors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide:
                          BorderSide(color: context.appColors.surfaceHigh),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide:
                          BorderSide(color: context.appColors.primary),
                    ),
                    filled: true,
                    fillColor: context.appColors.surface,
                  ),
                  controller: TextEditingController(text: _count.toString()),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed >= 1 && parsed <= 52) {
                      _count = parsed;
                      _notifyChange();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'vezes',
                style: AppTypography.bodySm
                    .copyWith(color: context.appColors.textSecondary),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _until ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _until = picked);
                _notifyChange();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.appColors.surfaceHigh),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: context.appColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _until != null
                        ? '${_until!.day.toString().padLeft(2, '0')}/${_until!.month.toString().padLeft(2, '0')}/${_until!.year}'
                        : 'Selecionar data',
                    style: AppTypography.bodySm
                        .copyWith(color: context.appColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEndOption(String label, bool isCount) {
    final selected = _useCount == isCount;
    return GestureDetector(
      onTap: () {
        setState(() => _useCount = isCount);
        _notifyChange();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? context.appColors.primary.withValues(alpha: 0.15) : context.appColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? context.appColors.primary : context.appColors.surfaceHigh,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? context.appColors.primary : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _notifyChange() {
    if (!_enabled) {
      widget.onChanged(null);
      return;
    }

    final config = RecurrenceConfig(
      frequency: _frequency,
      interval: _interval,
      byWeekDay: _frequency == RecurrenceFrequency.weekly && _selectedDays.isNotEmpty
          ? _selectedDays.toList()
          : null,
      count: _useCount ? _count : null,
      until: !_useCount ? _until : null,
    );

    widget.onChanged(buildRRule(config));
  }
}
