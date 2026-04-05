import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

// ── Duration picker options: 5 min increments from 5 to 480 ──────────────────

const _kDurationStep = 5;
const _kDurationMax = 480;
final _kDurationOptions = List.generate(
  _kDurationMax ~/ _kDurationStep,
  (i) => (i + 1) * _kDurationStep,
);

// ── BRL currency input formatter ──────────────────────────────────────────────

class _BrlCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final cents = int.parse(
        digits.length > 12 ? digits.substring(digits.length - 12) : digits);
    final formatted = _centsToBrl(cents);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _centsToBrl(int cents) {
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    return 'R\$ ${_formatReais(reais)},${centavos.toString().padLeft(2, '0')}';
  }

  static String _formatReais(int reais) {
    final s = reais.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double? _parseBrl(String text) {
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  final cents = int.tryParse(digits);
  if (cents == null || cents == 0) return null;
  return cents / 100.0;
}

String _formatDuration(int min) {
  if (min < 60) return '${min}min';
  if (min % 60 == 0) return '${min ~/ 60}h';
  return '${min ~/ 60}h ${min % 60}min';
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ServiceFormSheet extends StatefulWidget {
  final ServiceModel? initial;

  const ServiceFormSheet({super.key, this.initial});

  @override
  State<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;

  int? _selectedDuration;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');

    final initialPrice = widget.initial?.price;
    _priceCtrl = TextEditingController(
      text: initialPrice != null
          ? _BrlCurrencyFormatter._centsToBrl((initialPrice * 100).round())
          : '',
    );

    _selectedDuration = widget.initial?.durationMinutes;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServicesBloc, ServicesState>(
      listener: (context, state) {
        if (state is ServicesLoaded) {
          Navigator.of(context).pop();
        } else if (state is ServicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    color: context.appColors.outline,
                  ),
                ),

                // ── Title ──
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      color: context.appColors.primary.withValues(alpha: 0.08),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_outlined
                            : Icons.add_circle_outline,
                        size: 16,
                        color: context.appColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isEditing ? 'Editar serviço' : 'Novo serviço',
                      style: AppTypography.headingMd.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    _isEditing
                        ? 'Atualize os dados do serviço.'
                        : 'Preencha os dados para criar um novo serviço.',
                    style: AppTypography.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Nome ──
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration(context, 'Nome do serviço'),
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Nome deve ter pelo menos 2 caracteres';
                    }
                    if (v.trim().length > 100) {
                      return 'Nome deve ter no máximo 100 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Preço ──
                TextFormField(
                  controller: _priceCtrl,
                  decoration:
                      _inputDecoration(context, 'Preço (opcional)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_BrlCurrencyFormatter()],
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed = _parseBrl(v);
                    if (parsed == null) return 'Preço inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Duração ──
                _buildDurationTile(context),
                const SizedBox(height: AppSpacing.xl),

                // ── Submit ──
                BlocBuilder<ServicesBloc, ServicesState>(
                  builder: (context, state) {
                    final isLoading = state is ServicesActionInProgress;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BaseButton(
                          label: _isEditing
                              ? 'Salvar alterações'
                              : 'Criar serviço',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        BaseButton(
                          label: 'Cancelar',
                          variant: BaseButtonVariant.secondary,
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Duration tile ──────────────────────────────────────────────────────────

  Widget _buildDurationTile(BuildContext context) {
    final label = _selectedDuration != null
        ? _formatDuration(_selectedDuration!)
        : 'Sem duração';
    final hasValue = _selectedDuration != null;

    return GestureDetector(
      onTap: () => _openDurationPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          border: Border.all(color: context.appColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: context.appColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Duração',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: hasValue
                    ? context.appColors.textPrimary
                    : context.appColors.textDisabled,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: context.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDurationPicker(BuildContext context) async {
    final initialIndex = _selectedDuration != null
        ? _kDurationOptions.indexOf(_selectedDuration!)
        : -1;
    final scrollController = ScrollController(
      initialScrollOffset: initialIndex > 0 ? (initialIndex * 48.0) : 0,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    color: ctx.appColors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duração do serviço',
                        style: AppTypography.labelLarge.copyWith(
                          color: ctx.appColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedDuration = null);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'Sem duração',
                          style: AppTypography.bodySm.copyWith(
                            color: ctx.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: ctx.appColors.outline),
                Expanded(
                  child: StatefulBuilder(
                    builder: (ctx, setPickerState) {
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: _kDurationOptions.length,
                        itemBuilder: (ctx, index) {
                          final min = _kDurationOptions[index];
                          final isSelected = _selectedDuration == min;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedDuration = min);
                              Navigator.of(ctx).pop();
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              color: isSelected
                                  ? ctx.appColors.primary
                                      .withValues(alpha: 0.08)
                                  : Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(min),
                                    style: AppTypography.bodySm.copyWith(
                                      color: isSelected
                                          ? ctx.appColors.primary
                                          : ctx.appColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: ctx.appColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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

    scrollController.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    final businessId = businessState.active.id;

    final name = _nameCtrl.text.trim();
    final price = _parseBrl(_priceCtrl.text);

    if (_isEditing) {
      context.read<ServicesBloc>().add(ServiceUpdateRequested(
            businessId: businessId,
            serviceId: widget.initial!.id,
            name: name,
            price: price,
            durationMinutes: _selectedDuration,
          ));
    } else {
      context.read<ServicesBloc>().add(ServiceCreateRequested(
            businessId: businessId,
            name: name,
            price: price,
            durationMinutes: _selectedDuration,
          ));
    }
  }

  // ── Input decoration ───────────────────────────────────────────────────────

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
        floatingLabelStyle: AppTypography.caption
            .copyWith(color: context.appColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: context.appColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: context.appColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: context.appColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      );
}
