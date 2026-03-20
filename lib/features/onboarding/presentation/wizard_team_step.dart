import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class WizardTeamStep extends StatefulWidget {
  const WizardTeamStep({super.key});

  @override
  State<WizardTeamStep> createState() => _WizardTeamStepState();
}

class _WizardTeamStepState extends State<WizardTeamStep> {
  final _emailController = TextEditingController();
  final List<String> _sentInvites = [];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendInvite() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    // TODO: dispatch staff invite event when staff invite flow is implemented
    setState(() {
      _sentInvites.add(email);
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Convide membros da equipe por e-mail. '
          'Eles receberão um link para criar sua senha.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BaseInputField(
          label: 'E-mail do colaborador',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          label: 'Enviar convite',
          variant: BaseButtonVariant.secondary,
          onPressed: _sendInvite,
        ),
        if (_sentInvites.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: _sentInvites
                .map((email) => Chip(label: Text(email)))
                .toList(),
          ),
        ],
      ],
    );
  }
}
