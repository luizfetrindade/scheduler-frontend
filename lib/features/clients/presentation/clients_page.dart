import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Clientes', style: AppTypography.headingMd),
      ),
    );
  }
}
