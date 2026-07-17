import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/statistics/application/statistics_providers.dart';

import '../../support/container.dart';

void main() {
  test(
    'statisticsViewModelProvider aggregates consumption from events',
    () async {
      final container = createTestContainer();
      final db = container.read(appDatabaseProvider);
      final inventory = container.read(inventoryRepositoryProvider);

      final now = DateTime.utc(2026, 7, 17);
      await db
          .into(db.products)
          .insert(
            productToCompanion(
              Product(
                id: 'p-stats',
                name: 'Stats Milk',
                category: FoodCategory.dairy,
                defaultUnit: MeasurementUnit.liters,
                source: ProductSource.manual,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );

      await db
          .into(db.inventoryEvents)
          .insert(
            inventoryEventToCompanion(
              InventoryEvent(
                id: 'e-stats',
                type: InventoryEventType.consume,
                occurredAt: now,
                productId: 'p-stats',
                quantityDelta: -2,
              ),
            ),
          );

      container.listen(
        statisticsViewModelProvider,
        (_, _) {},
        fireImmediately: true,
      );

      await expectLater(
        inventory.watchEvents().map((events) => events.length),
        emits(1),
      );

      final stats = container.read(statisticsViewModelProvider).requireValue;
      expect(stats.consumptionTotal, 2);
      expect(stats.mostConsumed, hasLength(1));
      expect(stats.mostConsumed.single.productId, 'p-stats');
      expect(stats.mostConsumed.single.amount, 2);
    },
  );
}
