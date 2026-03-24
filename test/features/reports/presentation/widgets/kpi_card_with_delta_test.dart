import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/kpi_card_with_delta.dart';

void main() {
  Widget buildCard({required double delta, required String value}) {
    return MaterialApp(
      home: Scaffold(
        body: KpiCardWithDelta(
          label: 'Receita',
          value: value,
          delta: delta,
          deltaLabel: '+8%',
          accentColor: Colors.green,
        ),
      ),
    );
  }

  testWidgets('shows green up arrow for positive delta', (tester) async {
    await tester.pumpWidget(buildCard(delta: 0.08, value: 'R\$ 12.480'));
    await tester.pump();
    expect(find.text('↑ +8%'), findsOneWidget);
  });

  testWidgets('shows red down arrow for negative delta', (tester) async {
    await tester.pumpWidget(buildCard(delta: -0.05, value: '68%'));
    await tester.pump();
    final text = find.textContaining('↓');
    expect(text, findsOneWidget);
  });
}
