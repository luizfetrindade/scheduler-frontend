import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';

class ClientFormSheet extends StatefulWidget {
  /// null = create mode; non-null = edit mode
  final ClientModel? initial;
  final String businessId;

  const ClientFormSheet({super.key, this.initial, required this.businessId});

  @override
  State<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.initial?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.initial?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientsBloc, ClientsState>(
      listenWhen: (previous, current) =>
          (current is ClientsLoaded && previous is ClientsActionInProgress) ||
          current is ClientsError,
      listener: (context, state) {
        if (state is ClientsLoaded) {
          Navigator.of(context).pop();
        } else if (state is ClientsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      child: BlocBuilder<ClientsBloc, ClientsState>(
        builder: (context, state) {
          final isLoading = state is ClientsActionInProgress;

          return Padding(
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
                      _isEditing ? 'Editar cliente' : 'Novo cliente',
                      style: AppTypography.headingMd
                          .copyWith(color: context.appColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Nome
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration(context, 'Nome'),
                      style: AppTypography.bodySm
                          .copyWith(color: context.appColors.textPrimary),
                      textCapitalization: TextCapitalization.words,
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

                    // Telefone
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _inputDecoration(context, 'Telefone'),
                      style: AppTypography.bodySm
                          .copyWith(color: context.appColors.textPrimary),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Telefone é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // E-mail (opcional)
                    TextFormField(
                      controller: _emailCtrl,
                      decoration:
                          _inputDecoration(context, 'E-mail (opcional)'),
                      style: AppTypography.bodySm
                          .copyWith(color: context.appColors.textPrimary),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Submit
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.primary,
                        foregroundColor: context.appColors.background,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.appColors.background,
                              ),
                            )
                          : Text(_isEditing ? 'Salvar' : 'Criar cliente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email =
        _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();

    if (_isEditing) {
      context.read<ClientsBloc>().add(ClientUpdateRequested(
            businessId: widget.businessId,
            clientId: widget.initial!.id,
            name: name,
            phone: phone,
            email: email,
          ));
    } else {
      context.read<ClientsBloc>().add(ClientCreateRequested(
            businessId: widget.businessId,
            name: name,
            phone: phone,
            email: email,
          ));
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
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
