import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

import '../support/fakes.dart';

void main() {
  late FixedClock clock;
  late SequentialIdGenerator ids;
  late InventoryMutationService service;

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 7, 17, 10));
    ids = SequentialIdGenerator();
    service = InventoryMutationService(clock, ids);
  });

  InventoryItem itemWith(double amount) => InventoryItem(
    id: 'item-1',
    productId: 'product-1',
    locationId: 'loc-1',
    quantity: Quantity(amount, MeasurementUnit.pieces),
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
  );

  group('createItem', () {
    test('produces an item and a paired ADD_PRODUCT event', () {
      final mutation = service.createItem(
        productId: 'product-1',
        locationId: 'loc-1',
        quantity: Quantity(2, MeasurementUnit.pieces),
      );

      expect(mutation.item.productId, 'product-1');
      expect(mutation.item.quantity.amount, 2);
      expect(mutation.event.type, InventoryEventType.addProduct);
      expect(mutation.event.inventoryItemId, mutation.item.id);
      expect(mutation.event.quantityBefore, 0);
      expect(mutation.event.quantityAfter, 2);
      expect(mutation.event.occurredAt, clock.nowUtc());
    });
  });

  group('applyQuantityDelta', () {
    test('increments quantity and records before/after and delta', () {
      final result = service.applyQuantityDelta(
        item: itemWith(3),
        deltaAmount: 2,
        type: InventoryEventType.updateQuantity,
      );
      final mutation = result.valueOrNull!;
      expect(mutation.item.quantity.amount, 5);
      expect(mutation.event.quantityBefore, 3);
      expect(mutation.event.quantityAfter, 5);
      expect(mutation.event.quantityDelta, 2);
      expect(mutation.item.isActive, isTrue);
    });

    test('reaching zero soft-deletes the item but keeps history', () {
      final result = service.applyQuantityDelta(
        item: itemWith(1),
        deltaAmount: -1,
        type: InventoryEventType.consume,
      );
      final mutation = result.valueOrNull!;
      expect(mutation.item.quantity.amount, 0);
      expect(mutation.item.isActive, isFalse);
      expect(mutation.item.deletedAt, clock.nowUtc());
      expect(mutation.event.quantityAfter, 0);
    });

    test('rejects going below zero (non-negative invariant)', () {
      final result = service.applyQuantityDelta(
        item: itemWith(1),
        deltaAmount: -2,
        type: InventoryEventType.consume,
      );
      expect(result.isFailure, isTrue);
    });

    test('rejects mutating an already-removed item', () {
      final removed = itemWith(
        1,
      ).copyWith(deletedAt: DateTime.utc(2026, 7, 10));
      final result = service.applyQuantityDelta(
        item: removed,
        deltaAmount: 1,
        type: InventoryEventType.updateQuantity,
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('consume / discard', () {
    test('consume records a CONSUME event', () {
      final mutation = service
          .consume(item: itemWith(3), amount: 1)
          .valueOrNull!;
      expect(mutation.event.type, InventoryEventType.consume);
      expect(mutation.item.quantity.amount, 2);
    });

    test('discard records a DISCARD event with WASTE reason', () {
      final mutation = service
          .discard(item: itemWith(3), amount: 1)
          .valueOrNull!;
      expect(mutation.event.type, InventoryEventType.discard);
      expect(mutation.event.reason, kWasteReason);
    });

    test('non-positive consume/discard amounts are rejected', () {
      expect(service.consume(item: itemWith(3), amount: 0).isFailure, isTrue);
      expect(service.discard(item: itemWith(3), amount: -1).isFailure, isTrue);
    });
  });

  group('changeLocation', () {
    test('moves the item and records a CHANGE_LOCATION event', () {
      final result = service.changeLocation(
        item: itemWith(2),
        toLocationId: 'loc-2',
      );
      final mutation = result.valueOrNull!;
      expect(mutation.item.locationId, 'loc-2');
      expect(mutation.event.type, InventoryEventType.changeLocation);
      expect(mutation.event.fromLocationId, 'loc-1');
      expect(mutation.event.toLocationId, 'loc-2');
    });

    test('rejects moving to the same location', () {
      final result = service.changeLocation(
        item: itemWith(2),
        toLocationId: 'loc-1',
      );
      expect(result.isFailure, isTrue);
    });
  });
}
