import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/core/theme/theme_cubit.dart';
import 'package:scheduler_frontend/core/theme/theme_state.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Configurações',
              style: AppTypography.headingMd.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                final isLight = state.themeMode == ThemeMode.light;
                return ListTile(
                  tileColor: context.appColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  leading: Icon(
                    isLight ? Icons.light_mode : Icons.dark_mode,
                    color: context.appColors.primary,
                  ),
                  title: Text(
                    'Modo claro',
                    style: AppTypography.bodySm.copyWith(color: context.appColors.textPrimary),
                  ),
                  trailing: Switch(
                    value: isLight,
                    activeColor: context.appColors.primary,
                    onChanged: (_) => context.read<ThemeCubit>().toggle(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
