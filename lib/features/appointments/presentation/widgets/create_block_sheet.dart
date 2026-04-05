import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/recurrence_selector.dart';

class CreateBlockSheet extends StatefulWidget {
  final DateTime initialDateTime;

  const CreateBlockSheet({super.key, required this.initialDateTime});

  @override
  State<CreateBlockSheet> createState() => _CreateBlockSheetState();
}

class _CreateBlockSheetState extends State<CreateBlockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _customDurationController = TextEditingController();
  late DateTime _selectedDateTime;
  int _durationMinutes = 60;
  bool _isCustomDuration = false;
  bool _isSubmitting = false;
  String? _recurrenceRule;

  static const _durationOptions = [15, 30, 45, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleActionSuccess || state is ScheduleActionFailure) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bloquear Horário',
                  style: AppTypography.headingMd.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildDateTimeRow(),
                const SizedBox(height: AppSpacing.md),
                _buildDurationSelector(),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(context, 'Título (opcional)'),
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value != null && value.length > 100) {
                      return 'Máximo de 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration(context, 'Observações (opcional)'),
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                RecurrenceSelector(
                  onChanged: (rrule) => _recurrenceRule = rrule,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blocked,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Bloquear Horário'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: AppColors.blocked),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Duração',
            style: AppTypography.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (!_isCustomDuration)
            DropdownButton<int>(
              value: _durationMinutes,
              underline: const SizedBox.shrink(),
              dropdownColor: context.appColors.surface,
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textPrimary,
              ),
              items: [
                ..._durationOptions.map((min) {
                  final label = _formatDuration(min);
                  return DropdownMenuItem(value: min, child: Text(label));
                }),
                DropdownMenuItem(
                  value: -1,
                  child: Text(
                    'Personalizar...',
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == -1) {
                  setState(() {
                    _isCustomDuration = true;
                    _customDurationController.text = _durationMinutes.toString();
                  });
                } else if (value != null) {
                  setState(() => _durationMinutes = value);
                }
              },
            ),
          if (_isCustomDuration)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _customDurationController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      hintText: 'min',
                      hintStyle: AppTypography.bodySm.copyWith(
                        color: context.appColors.textDisabled,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: context.appColors.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: context.appColors.primary),
                      ),
                      filled: true,
                      fillColor: context.appColors.surface,
                    ),
                    validator: (value) {
                      if (!_isCustomDuration) return null;
                      final mins = int.tryParse(value ?? '');
                      if (mins == null || mins < 5 || mins > 480) {
                        return '5-480';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'min',
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: context.appColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    setState(() => _isCustomDuration = false);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDateTime);
    final timeStr = DateFormat('HH:mm').format(_selectedDateTime);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: _tile(Icons.calendar_today, dateStr),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: _tile(Icons.access_time, timeStr),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blocked),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year, picked.month, picked.day,
          _selectedDateTime.hour, _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
          picked.hour, picked.minute,
        );
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final duration = _isCustomDuration
        ? int.parse(_customDurationController.text)
        : _durationMinutes;

    context.read<ScheduleBloc>().add(
          ScheduleBlockCreateRequested(
            startsAt: _selectedDateTime,
            durationMinutes: duration,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            recurrenceRule: _recurrenceRule,
          ),
        );
  }

  static String _formatDuration(int min) {
    if (min < 60) return '${min}min';
    if (min % 60 == 0) return '${min ~/ 60}h';
    return '${min ~/ 60}h ${min % 60}min';
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}
