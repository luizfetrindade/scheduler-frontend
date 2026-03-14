import 'package:flutter/material.dart';

/// Placeholder — full implementation in Task 14.
class ProfessionalProfilePage extends StatelessWidget {
  final String professionalId;

  const ProfessionalProfilePage({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Profissional')),
      body: Center(child: Text('Profissional: $professionalId')),
    );
  }
}
