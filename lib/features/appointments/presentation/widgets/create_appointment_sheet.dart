import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/appointments/presentation/widgets/recurrence_selector.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class CreateAppointmentSheet extends StatefulWidget {
  final DateTime initialDateTime;

  const CreateAppointmentSheet({super.key, required this.initialDateTime});

  @override
  State<CreateAppointmentSheet> createState() => _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState extends State<CreateAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _notesController = TextEditingController();
  final _customDurationController = TextEditingController();
  late DateTime _selectedDateTime;
  int _durationMinutes = 60;
  bool _isCustomDuration = false;
  bool _isSubmitting = false;
  String? _recurrenceRule;
  String? _selectedServiceId;

  static const _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
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
                _buildServiceSelector(),
                const SizedBox(height: AppSpacing.md),
                _buildDurationSelector(),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<ClientsBloc, ClientsState>(
                  builder: (context, clientsState) {
                    final clients = switch (clientsState) {
                      ClientsLoaded(:final clients) => clients,
                      ClientsActionInProgress(:final clients) => clients,
                      ClientsError(:final clients) => clients,
                      _ => <ClientModel>[],
                    };
                    return _buildClientNameField(context, clients);
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
                BaseButton(
                  label: 'Criar Agendamento',
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientNameField(BuildContext context, List<ClientModel> clients) {
    return RawAutocomplete<ClientModel>(
      textEditingController: _nameController,
      focusNode: _nameFocusNode,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) return const [];
        return clients.where((c) => c.name.toLowerCase().contains(query));
      },
      onSelected: (_) {},
      fieldViewBuilder: (ctx, textCtrl, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textCtrl,
          focusNode: focusNode,
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
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: context.appColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (ctx, i) {
                  final client = options.elementAt(i);
                  final subtitle = [
                    if (client.email != null) client.email!,
                    if (client.phone.isNotEmpty) client.phone,
                  ].join(' · ');
                  return InkWell(
                    onTap: () => onSelected(client),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            client.name,
                            style: AppTypography.bodySm.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTypography.bodySm.copyWith(
                                color: context.appColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceSelector() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        final services = switch (state) {
          ServicesLoaded(:final services) =>
              services.where((s) => s.isActive).toList(),
          _ => <ServiceModel>[],
        };

        if (services.isEmpty) return const SizedBox.shrink();

        final selected = services.where((s) => s.id == _selectedServiceId).firstOrNull;

        return GestureDetector(
          onTap: () => _openServicePicker(context, services),
          child: Container(
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
                Icon(Icons.design_services_outlined,
                    size: 18, color: context.appColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serviço',
                        style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _serviceSubtitle(selected),
                          style: AppTypography.bodySm.copyWith(
                            color: context.appColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  selected?.name ?? 'Nenhum',
                  style: AppTypography.bodySm.copyWith(
                    color: selected != null
                        ? context.appColors.textPrimary
                        : context.appColors.textDisabled,
                    fontWeight: selected != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right,
                    size: 16, color: context.appColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Duration + price subtitle for a service tile.
  String _serviceSubtitle(ServiceModel svc) {
    final parts = <String>[];
    if (svc.durationMinutes != null) parts.add(_formatDuration(svc.durationMinutes!));
    if (svc.price != null) {
      parts.add('R\$ ${svc.price!.toStringAsFixed(2).replaceAll('.', ',')}');
    }
    return parts.join(' · ');
  }

  Future<void> _openServicePicker(
      BuildContext context, List<ServiceModel> services) async {
    final scrollCtrl = ScrollController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Escolher serviço',
                        style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _applyService(null);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'Nenhum',
                          style: AppTypography.bodySm.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.appColors.surfaceHigh),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: services.length,
                    itemBuilder: (ctx, i) {
                      final svc = services[i];
                      final isSelected = svc.id == _selectedServiceId;
                      final subtitle = _serviceSubtitle(svc);
                      return InkWell(
                        onTap: () {
                          _applyService(svc);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          color: isSelected
                              ? context.appColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      svc.name,
                                      style: AppTypography.bodySm.copyWith(
                                        color: isSelected
                                            ? context.appColors.primary
                                            : context.appColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: AppTypography.bodySm.copyWith(
                                          color: context.appColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check,
                                    size: 16,
                                    color: context.appColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    scrollCtrl.dispose();
  }

  /// Applies a service selection: updates serviceId and auto-fills duration.
  void _applyService(ServiceModel? svc) {
    setState(() {
      _selectedServiceId = svc?.id;
      if (svc == null) {
        _durationMinutes = 60;
        _isCustomDuration = false;
        _customDurationController.clear();
      } else if (svc.durationMinutes != null) {
        final dur = svc.durationMinutes!;
        if (_durationOptions.contains(dur)) {
          _durationMinutes = dur;
          _isCustomDuration = false;
        } else {
          _durationMinutes = dur;
          _isCustomDuration = true;
          _customDurationController.text = dur.toString();
        }
      }
    });
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
            startsAt: _selectedDateTime,
            durationMinutes: duration,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            recurrenceRule: _recurrenceRule,
            serviceId: _selectedServiceId,
          ),
        );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
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
          border: Border.all(color: context.appColors.outline),
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
