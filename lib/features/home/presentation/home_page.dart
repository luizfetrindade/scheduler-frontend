import 'package:flutter/material.dart';
import 'package:scheduler_frontend/core/l10n/l10n.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.xl),
              BaseInputField(
                label: context.l10n.searchLabel,
                hint: context.l10n.searchHint,
                controller: _searchController,
                prefixIcon: Icons.search_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.homeTodayWorkout, style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              const _TodayWorkoutCard(),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.homeMyWorkouts, style: AppTypography.headingMd),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino A — Peito',
                muscles: 'Peitoral · Ombro · Tríceps',
                exercises: 6,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino B — Costas',
                muscles: 'Costas · Bíceps · Antebraço',
                exercises: 5,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              _WorkoutCard(
                name: 'Treino C — Pernas',
                muscles: 'Quadríceps · Posterior · Glúteo',
                exercises: 7,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: context.l10n.workoutNewButton,
                onPressed: () {},
                variant: BaseButtonVariant.secondary,
                prefixIcon: Icons.add,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.homeGreeting, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.appTitle, style: AppTypography.displayLg),
          ],
        ),
        BaseCard(
          padding: AppSpacing.sm,
          onTap: () {},
          child: const Icon(Icons.person_outline, color: AppColors.purple500, size: 24),
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      elevated: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.purple500, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('Treino A — Peito', style: AppTypography.headingMd),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Peitoral · Ombro · Tríceps', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatChip(icon: Icons.fitness_center_outlined, label: '6 exercícios'),
              const SizedBox(width: AppSpacing.md),
              _StatChip(icon: Icons.timer_outlined, label: '~45 min'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          BaseButton(
            label: context.l10n.workoutStartButton,
            onPressed: () {},
            prefixIcon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String muscles;
  final int exercises;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.name,
    required this.muscles,
    required this.exercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMd),
                const SizedBox(height: AppSpacing.xs),
                Text(muscles, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$exercises', style: AppTypography.headingMd.copyWith(color: AppColors.purple500)),
              Text('exercícios', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
