import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/repositories/drift_inventory_repository.dart';
import 'package:fridgeos/data/repositories/drift_product_repository.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase db;
  late DriftInventoryRepository inventory;
  late DriftProductRepository products;
  late InventoryMutationService mutations;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    inventory = DriftInventoryRepository(db);
    products = DriftProductRepository(db);
    mutations = InventoryMutationService(
      FixedClock(DateTime.utc(2026, 7, 17, 10)),
      SequentialIdGenerator(),
    );

    // A product and the seeded fridge location satisfy the foreign keys.
    await products.upsert(
      Product(
        id: 'product-1',
        name: 'Milk',
        category: FoodCategory.dairy,
        defaultUnit: MeasurementUnit.liters,
        source: ProductSource.manual,
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 1),
      ),
    );
  });

  tearDown(() => db.close());

  InventoryMutation createMutation() => mutations.createItem(
    productId: 'product-1',
    locationId: kDefaultFridgeId,
    quantity: Quantity(2, MeasurementUnit.liters),
  );

  test('applyMutation persists item and its event atomically', () async {
    final result = await inventory.applyMutation(createMutation());
    expect(result.isSuccess, isTrue);

    final items = await db.select(db.inventoryItems).get();
    final events = await db.select(db.inventoryEvents).get();
    expect(items, hasLength(1));
    expect(events, hasLength(1));
    expect(events.single.type, InventoryEventType.addProduct.wire);
    expect(events.single.inventoryItemId, items.single.id);
  });

  test('watchActiveItems emits active stock', () async {
    await inventory.applyMutation(createMutation());
    await expectLater(
      inventory.watchActiveItems().map((l) => l.length),
      emits(1),
    );
  });

  test(
    'consuming to zero removes item from active stock but keeps events',
    () async {
      final created = createMutation();
      await inventory.applyMutation(created);

      final consumed = mutations
          .consume(item: created.item, amount: 2)
          .valueOrNull!;
      await inventory.applyMutation(consumed);

      await expectLater(
        inventory.watchActiveItems().map((l) => l.length),
        emits(0),
      );
      final events = await db.select(db.inventoryEvents).get();
      expect(events, hasLength(2)); // ADD_PRODUCT + CONSUME retained
    },
  );

  test(
    'a foreign-key violation rolls back the whole mutation (no event)',
    () async {
      // productId references a non-existent product -> FK failure inside the txn.
      final bad = mutations.createItem(
        productId: 'does-not-exist',
        locationId: kDefaultFridgeId,
        quantity: Quantity(1, MeasurementUnit.pieces),
      );
      final result = await inventory.applyMutation(bad);

      expect(result.isFailure, isTrue);
      expect(await db.select(db.inventoryItems).get(), isEmpty);
      expect(await db.select(db.inventoryEvents).get(), isEmpty);
    },
  );

  test('watchEvents can filter by product', () async {
    await inventory.applyMutation(createMutation());
    await expectLater(
      inventory.watchEvents(productId: 'product-1').map((l) => l.length),
      emits(1),
    );
  });
}
