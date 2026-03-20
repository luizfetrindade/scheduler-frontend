import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http/flutter_http.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/data/business_repository.dart';

class CreateBusinessPage extends StatefulWidget {
  /// Called with the created business slug when the form succeeds.
  final void Function(String slug)? onCreated;

  const CreateBusinessPage({super.key, this.onCreated});

  @override
  State<CreateBusinessPage> createState() => _CreateBusinessPageState();
}

class _CreateBusinessPageState extends State<CreateBusinessPage> {
  final _nameController = TextEditingController();
  String? _nameError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Nome do negócio é obrigatório');
      return false;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Nome deve ter ao menos 2 caracteres');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final repo = context.read<BusinessRepository>();
    final result = await repo.createBusiness(
      name: _nameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(:final data):
        widget.onCreated?.call(data.slug);
      case HttpFailure(:final failure):
        final message = switch (failure) {
          NetworkFailure() => 'Sem conexão com a internet',
          _ => 'Não foi possível criar o negócio. Tente novamente.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Criar Negócio',
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dê um nome ao seu negócio',
                style: AppTypography.bodySm.copyWith(
                  color: context.appColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              BaseInputField(
                label: 'Nome do negócio',
                controller: _nameController,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.business_outlined,
                errorText: _nameError,
              ),
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: 'Criar negócio',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
