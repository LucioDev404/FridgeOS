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

  test('addManualItem stores optional barcode and low stock', () async {
    final result = await actions.addManualItem(
      name: 'Yogurt',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.pieces,
      amount: 4,
      locationId: kDefaultFridgeId,
      barcode: '4006381333931',
      lowStockThreshold: 1,
      expirationDate: DateOnly(2026, 8, 1),
    );
    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);

    final product = (await db.select(db.products).get()).single;
    expect(product.barcode, '4006381333931');
    final item = (await db.select(db.inventoryItems).get()).single;
    expect(item.lowStockThreshold, 1);
    expect(item.expirationDate, '2026-08-01');
  });

  test('adjust increments quantity and logs a RESTOCK event', () async {
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
      contains(InventoryEventType.restock.wire),
    );
  });

  test(
    'setQuantity records MANUAL_CORRECTION and keeps prior events',
    () async {
      await addMilk(amount: 2);
      final item = (await db.select(db.inventoryItems).get()).single;

      final result = await actions.setQuantity(
        item: inventoryItemFromRow(item),
        targetAmount: 5,
      );
      expect(result.isSuccess, isTrue);

      final events = await db.select(db.inventoryEvents).get();
      expect(events, hasLength(2));
      expect(
        events.map((e) => e.type),
        containsAll([
          InventoryEventType.addProduct.wire,
          InventoryEventType.manualCorrection.wire,
        ]),
      );
    },
  );

  test('updateItemDetails edits snapshot without deleting history', () async {
    await addMilk(amount: 2);
    final productRow = (await db.select(db.products).get()).single;
    final itemRow = (await db.select(db.inventoryItems).get()).single;

    final result = await actions.updateItemDetails(
      product: productFromRow(productRow),
      item: inventoryItemFromRow(itemRow),
      name: 'Whole milk',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.liters,
      amount: 2,
      locationId: kDefaultFridgeId,
      barcode: '4006381333931',
      expirationDate: DateOnly(2026, 9, 1),
      lowStockThreshold: 0.5,
      note: 'Prefer organic',
    );
    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);

    final product = (await db.select(db.products).get()).single;
    expect(product.name, 'Whole milk');
    expect(product.barcode, '4006381333931');
    final item = (await db.select(db.inventoryItems).get()).single;
    expect(item.expirationDate, '2026-09-01');
    expect(item.lowStockThreshold, 0.5);
    expect(item.note, 'Prefer organic');
    final events = await db.select(db.inventoryEvents).get();
    expect(events, hasLength(1));
    expect(events.single.type, InventoryEventType.addProduct.wire);
  });

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
