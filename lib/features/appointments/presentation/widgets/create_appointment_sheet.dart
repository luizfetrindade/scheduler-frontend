import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/recurrence_selector.dart';

class CreateAppointmentSheet extends StatefulWidget {
  final DateTime initialDateTime;

  const CreateAppointmentSheet({super.key, required this.initialDateTime});

  @override
  State<CreateAppointmentSheet> createState() => _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState extends State<CreateAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _customDurationController = TextEditingController();
  late DateTime _selectedDateTime;
  int _durationMinutes = 60;
  bool _isCustomDuration = false;
  bool _isSubmitting = false;
  String? _recurrenceRule;

  static const _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
                  'Novo Agendamento',
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
                  controller: _nameController,
                  decoration: _inputDecoration(context, 'Nome do cliente'),
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Nome deve ter pelo menos 2 caracteres';
                    }
                    if (value.trim().length > 100) {
                      return 'Nome deve ter no máximo 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(context, 'Email do cliente'),
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email é obrigatório';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email inválido';
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
                    backgroundColor: context.appColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
                      : const Text('Criar Agendamento'),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.appColors.surfaceHigh),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: context.appColors.primary),
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
                      color: context.appColors.primaryLight,
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

  static String _formatDuration(int min) {
    if (min < 60) return '${min}min';
    if (min % 60 == 0) return '${min ~/ 60}h';
    return '${min ~/ 60}h ${min % 60}min';
  }

  Widget _buildDateTimeRow() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDateTime);
    final timeStr = DateFormat('HH:mm').format(_selectedDateTime);

    return Row(
      children: [
        Expanded(
          child: _DateTimeTile(
            icon: Icons.calendar_today,
            label: dateStr,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DateTimeTile(
            icon: Icons.access_time,
            label: timeStr,
            onTap: _pickTime,
          ),
        ),
      ],
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
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
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
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
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
          ScheduleAppointmentCreateRequested(
            clientName: _nameController.text.trim(),
            clientEmail: _emailController.text.trim(),
            startsAt: _selectedDateTime,
            durationMinutes: duration,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            recurrenceRule: _recurrenceRule,
          ),
        );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySm.copyWith(
          color: context.appColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.appColors.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.appColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: context.appColors.surface,
      );
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          children: [
            Icon(icon, size: 18, color: context.appColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
