import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_bloc.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_event.dart';
import 'package:scheduler_frontend/features/onboarding/bloc/wizard_state.dart';

class WizardBusinessStep extends StatefulWidget {
  const WizardBusinessStep({super.key});

  @override
  State<WizardBusinessStep> createState() => _WizardBusinessStepState();
}

class _WizardBusinessStepState extends State<WizardBusinessStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<WizardBloc>().add(
          WizardBusinessSubmitted(name: _nameController.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WizardBloc, WizardState>(
      builder: (context, state) {
        final isLoading = state is WizardLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome do negócio',
                  hintText: 'Ex: Salão da Maria',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do negócio';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome deve ter pelo menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                BaseButton(
                  label: 'Criar negócio',
                  onPressed: () => _submit(context),
                ),
            ],
          ),
        );
      },
    );
  }
}
