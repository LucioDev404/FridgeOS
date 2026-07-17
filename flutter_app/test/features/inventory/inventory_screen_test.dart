import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/presentation/inventory_screen.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('shows a seeded item and increments its quantity', (
    tester,
  ) async {
    final harness = TestHarness();
    await harness.actions.addManualItem(
      name: 'Milk',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.liters,
      amount: 2,
      locationId: kDefaultFridgeId,
    );

    await tester.pumpWidget(harness.wrap(const InventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2 l'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase'));
    await tester.pumpAndSettle();

    expect(find.text('3 l'), findsOneWidget);
  });

  testWidgets('empty inventory shows the onboarding empty state', (
    tester,
  ) async {
    final harness = TestHarness();

    await tester.pumpWidget(harness.wrap(const InventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nothing in stock yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add product'), findsWidgets);
  });

  testWidgets('add-product form validates a required name', (tester) async {
    final harness = TestHarness();

    await tester.pumpWidget(harness.wrap(const InventoryScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add product').first);
    await tester.pumpAndSettle();
    expect(find.text('Add a product'), findsOneWidget);

    final addButton = find.widgetWithText(FilledButton, 'Add');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
  });
}
