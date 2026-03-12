import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_event.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';

class ServiceFormSheet extends StatefulWidget {
  /// If non-null, edit mode — pre-fills fields.
  final ServiceModel? initial;

  const ServiceFormSheet({super.key, this.initial});

  @override
  State<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial?.price != null
          ? widget.initial!.price!.toStringAsFixed(2)
          : '',
    );
    _durationCtrl = TextEditingController(
      text: widget.initial?.durationMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initial != null;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServicesBloc, ServicesState>(
      listener: (context, state) {
        if (state is ServicesLoaded || state is ServicesError) {
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
                  _isEditing ? 'Editar Serviço' : 'Novo Serviço',
                  style: AppTypography.headingMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration('Nome do serviço'),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
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
                TextFormField(
                  controller: _priceCtrl,
                  decoration: _inputDecoration('Preço (opcional)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Preço inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _durationCtrl,
                  decoration: _inputDecoration('Duração em minutos (opcional)'),
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final mins = int.tryParse(v.trim());
                    if (mins == null || mins < 5 || mins > 480) {
                      return 'Duração deve ser entre 5 e 480 minutos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<ServicesBloc, ServicesState>(
                  builder: (context, state) {
                    final isLoading = state is ServicesActionInProgress;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Salvar' : 'Criar Serviço'),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;
    final businessId = businessState.active.id;

    final name = _nameCtrl.text.trim();
    final price = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final duration = _durationCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_durationCtrl.text.trim());

    if (_isEditing) {
      context.read<ServicesBloc>().add(ServiceUpdateRequested(
            businessId: businessId,
            serviceId: widget.initial!.id,
            name: name,
            price: price,
            durationMinutes: duration,
          ));
    } else {
      context.read<ServicesBloc>().add(ServiceCreateRequested(
            businessId: businessId,
            name: name,
            price: price,
            durationMinutes: duration,
          ));
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.purple500),
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
        fillColor: AppColors.surface,
      );
}
