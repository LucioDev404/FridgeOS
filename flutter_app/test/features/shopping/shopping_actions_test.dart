import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/shopping/application/shopping_actions.dart';
import 'package:fridgeos/features/shopping/application/shopping_providers.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/container.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late InventoryActions inventoryActions;
  late ShoppingActions shoppingActions;

  setUp(() {
    container = createTestContainer();
    db = container.read(appDatabaseProvider);
    inventoryActions = container.read(inventoryActionsProvider);
    shoppingActions = container.read(shoppingActionsProvider);
  });

  Future<void> addMilk({double amount = 0, double? threshold}) async {
    await inventoryActions.addManualItem(
      name: 'Milk',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.liters,
      amount: amount > 0 ? amount : 1,
      locationId: kDefaultFridgeId,
      lowStockThreshold: threshold,
    );
    if (amount == 0) {
      final item = (await db.select(db.inventoryItems).get()).single;
      await inventoryActions.consume(
        item: inventoryItemFromRow(item),
        amount: 1,
      );
    }
  }

  test('addManual creates a pending shopping item', () async {
    final result = await shoppingActions.addManual(name: 'Bread');
    expect(result.isSuccess, isTrue);

    final rows = await db.select(db.shoppingListItems).get();
    expect(rows.single.name, 'Bread');
  });

  test('markDone updates status', () async {
    await shoppingActions.addManual(name: 'Eggs');
    final item = shoppingListItemFromRow(
      (await db.select(db.shoppingListItems).get()).single,
    );

    final result = await shoppingActions.markDone(item);
    expect(result.isSuccess, isTrue);

    final pending = await db.select(db.shoppingListItems).get();
    expect(
      pending.every((i) => i.status != ShoppingItemStatus.pending.wire),
      isTrue,
    );
  });

  test('dismiss sets cooldown before re-proposal', () async {
    await shoppingActions.addManual(name: 'Butter');
    final item = shoppingListItemFromRow(
      (await db.select(db.shoppingListItems).get()).single,
    );

    final result = await shoppingActions.dismiss(item);
    expect(result.isSuccess, isTrue);

    final row = (await db.select(db.shoppingListItems).get()).single;
    expect(row.status, ShoppingItemStatus.dismissed.wire);
    expect(row.dismissedUntil, isNotNull);
  });

  test('syncAutoProposals adds low-stock and out-of-stock items', () async {
    await addMilk(amount: 0);
    await addMilk(amount: 1, threshold: 3);

    final products = await db.select(db.products).get();
    final items = await db.select(db.inventoryItems).get();
    final activeItems = items
        .where((i) => i.deletedAt == null)
        .map(inventoryItemFromRow)
        .toList();

    final result = await shoppingActions.syncAutoProposals(
      items: activeItems,
      products: products.map(productFromRow).toList(),
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, greaterThan(0));

    final rows = await db.select(db.shoppingListItems).get();
    expect(rows.map((r) => r.name), contains('Milk'));
  });
}
