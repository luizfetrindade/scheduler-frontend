import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Configurações', style: AppTypography.headingMd),
      ),
    );
  }
}
