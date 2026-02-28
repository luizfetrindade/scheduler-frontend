import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';
import 'package:scheduler_frontend/features/home/presentation/widgets/business_selector_header.dart';

const _biz1 =
    BusinessModel(id: '1', slug: 's1', name: 'Salão A', logo: null, timezone: 'UTC');
const _biz2 =
    BusinessModel(id: '2', slug: 's2', name: 'Salão B', logo: null, timezone: 'UTC');

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows active business name and dropdown icon', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (_) {},
      userName: 'João',
    )));

    expect(find.text('Salão A'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('shows user initial in avatar', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1],
      onSelect: (_) {},
      userName: 'Ana',
    )));

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('hides dropdown icon when only one business', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1],
      onSelect: (_) {},
      userName: 'João',
    )));

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('opens bottom sheet with business list on tap', (tester) async {
    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (_) {},
      userName: 'João',
    )));

    await tester.tap(find.text('Salão A'));
    await tester.pumpAndSettle();

    expect(find.text('Salão B'), findsOneWidget);
  });

  testWidgets('calls onSelect when a different business is tapped',
      (tester) async {
    BusinessModel? selected;

    await tester.pumpWidget(_wrap(BusinessSelectorHeader(
      active: _biz1,
      businesses: [_biz1, _biz2],
      onSelect: (b) => selected = b,
      userName: 'João',
    )));

    await tester.tap(find.text('Salão A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salão B'));
    await tester.pumpAndSettle();

    expect(selected, equals(_biz2));
  });
}
