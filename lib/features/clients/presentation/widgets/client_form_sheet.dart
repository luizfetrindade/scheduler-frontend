import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _phoneCtrl = TextEditingController(
      text: _PhoneInputFormatter.format(widget.initial?.phone ?? ''),
    );
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
                          color: context.appColors.primary
                              .withValues(alpha: 0.08),
                          child: Icon(
                            _isEditing
                                ? Icons.edit_outlined
                                : Icons.person_add_outlined,
                            size: 16,
                            color: context.appColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _isEditing ? 'Editar cliente' : 'Novo cliente',
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
                            ? 'Atualize os dados do cliente.'
                            : 'Preencha os dados para cadastrar um novo cliente.',
                        style: AppTypography.bodySm.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Nome ──
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

                    // ── Telefone ──
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _inputDecoration(
                        context,
                        'Celular',
                        hintText: '(XX) XXXXX-XXXX',
                      ),
                      style: AppTypography.bodySm
                          .copyWith(color: context.appColors.textPrimary),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_PhoneInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Celular é obrigatório';
                        }
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) {
                          return 'Celular inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── E-mail (opcional) ──
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
                    const SizedBox(height: AppSpacing.xl),

                    // ── Submit ──
                    BaseButton(
                      label: _isEditing ? 'Salvar alterações' : 'Criar cliente',
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
    final phone = _phoneDigits();
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

  /// Strips mask before sending to backend.
  String _phoneDigits() =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    String? hintText,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppTypography.bodySm
            .copyWith(color: context.appColors.textSecondary),
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
          borderSide: BorderSide(
            color: context.appColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: context.appColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      );
}

// ── Phone input formatter ─────────────────────────────────────────────────────

/// Aplica máscara brasileira de telefone:
/// - 10 dígitos → (XX) XXXX-XXXX (fixo)
/// - 11 dígitos → (XX) XXXXX-XXXX (celular)
class _PhoneInputFormatter extends TextInputFormatter {
  static String format(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
    final isMobile = capped.length > 10;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (isMobile && i == 7) buf.write('-');
      if (!isMobile && i == 6) buf.write('-');
      buf.write(capped[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
