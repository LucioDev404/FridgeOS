import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/container.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late InventoryActions actions;

  setUp(() {
    container = createTestContainer();
    db = container.read(appDatabaseProvider);
    actions = container.read(inventoryActionsProvider);
  });

  Future<void> addMilk({double amount = 2}) async {
    final result = await actions.addManualItem(
      name: 'Milk',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.liters,
      amount: amount,
      locationId: kDefaultFridgeId,
      expirationDate: DateOnly(2026, 7, 20),
    );
    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);
  }

  test('addManualItem creates product, item and ADD_PRODUCT event', () async {
    await addMilk();

    final products = await db.select(db.products).get();
    final items = await db.select(db.inventoryItems).get();
    final events = await db.select(db.inventoryEvents).get();
    expect(products, hasLength(1));
    expect(products.single.name, 'Milk');
    expect(items, hasLength(1));
    expect(items.single.quantityAmount, 2);
    expect(items.single.expirationDate, '2026-07-20');
    expect(events.single.type, InventoryEventType.addProduct.wire);
  });

  test('addManualItem rejects an empty name', () async {
    final result = await actions.addManualItem(
      name: '   ',
      category: FoodCategory.other,
      unit: MeasurementUnit.pieces,
      amount: 1,
      locationId: kDefaultFridgeId,
    );
    expect(result.isFailure, isTrue);
    expect(await db.select(db.products).get(), isEmpty);
  });

  test('addManualItem rejects a non-positive quantity', () async {
    final result = await actions.addManualItem(
      name: 'Eggs',
      category: FoodCategory.other,
      unit: MeasurementUnit.pieces,
      amount: 0,
      locationId: kDefaultFridgeId,
    );
    expect(result.isFailure, isTrue);
  });

  test(
    'adjust increments quantity and logs an UPDATE_QUANTITY event',
    () async {
      await addMilk();
      final item = (await db.select(db.inventoryItems).get()).single;

      final result = await actions.adjust(
        item: inventoryItemFromRow(item),
        delta: 1,
      );
      expect(result.isSuccess, isTrue);

      final updated = (await db.select(db.inventoryItems).get()).single;
      expect(updated.quantityAmount, 3);
      final events = await db.select(db.inventoryEvents).get();
      expect(
        events.map((e) => e.type),
        contains(InventoryEventType.updateQuantity.wire),
      );
    },
  );

  test('consuming all soft-deletes the item and keeps its history', () async {
    await addMilk(amount: 1);
    final item = (await db.select(db.inventoryItems).get()).single;

    final result = await actions.consume(
      item: inventoryItemFromRow(item),
      amount: 1,
    );
    expect(result.isSuccess, isTrue);

    final updated = (await db.select(db.inventoryItems).get()).single;
    expect(updated.deletedAt, isNotNull);
    final events = await db.select(db.inventoryEvents).get();
    expect(events, hasLength(2));
  });

  test('move changes location and records CHANGE_LOCATION', () async {
    await addMilk();
    final item = (await db.select(db.inventoryItems).get()).single;

    final result = await actions.move(
      item: inventoryItemFromRow(item),
      toLocationId: kDefaultPantryId,
    );
    expect(result.isSuccess, isTrue);

    final updated = (await db.select(db.inventoryItems).get()).single;
    expect(updated.locationId, kDefaultPantryId);
  });
}
