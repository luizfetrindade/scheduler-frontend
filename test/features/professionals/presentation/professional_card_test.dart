import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/design_system/tokens/app_theme.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';
import 'package:scheduler_frontend/features/professionals/presentation/widgets/professional_card.dart';

void main() {
  final prof = ProfessionalModel(
    id: 'p1',
    businessId: 'b1',
    name: 'Ana Silva',
    roleName: 'Cabeleireira',
    color: '#4A90E2',
    isActive: true,
  );

  Widget buildCard({
    ProfessionalModel? model,
    VoidCallback? onToggleActive,
    VoidCallback? onTap,
  }) =>
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProfessionalCard(
            professional: model ?? prof,
            onToggleActive: onToggleActive ?? () {},
            onTap: onTap ?? () {},
          ),
        ),
      );

  testWidgets('renders professional name', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('renders role name when set', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Cabeleireira'), findsOneWidget);
  });

  testWidgets('does not render role name when null', (tester) async {
    await tester.pumpWidget(buildCard(
      model: prof.copyWith(roleName: null),
    ));
    expect(find.text('Cabeleireira'), findsNothing);
  });

  testWidgets('shows active text when isActive true', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('shows inactive text when isActive false', (tester) async {
    await tester.pumpWidget(buildCard(
      model: prof.copyWith(isActive: false),
    ));
    expect(find.text('Inativo'), findsOneWidget);
  });

  testWidgets('calls onTap when card tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildCard(onTap: () => tapped = true));
    await tester.tap(find.byType(ProfessionalCard));
    expect(tapped, true);
  });

  testWidgets('calls onToggleActive when toggle button tapped', (tester) async {
    var toggled = false;
    await tester.pumpWidget(buildCard(onToggleActive: () => toggled = true));
    // Find the toggle button — use a Switch or IconButton
    final toggleFinder = find.byType(Switch).first;
    await tester.tap(toggleFinder);
    expect(toggled, true);
  });
}
