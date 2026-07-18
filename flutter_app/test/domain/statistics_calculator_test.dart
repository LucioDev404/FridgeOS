import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/services/statistics_calculator.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  const calculator = StatisticsCalculator();

  InventoryEvent event({
    required String id,
    required InventoryEventType type,
    required DateTime occurredAt,
    String? productId,
    double? quantityDelta,
    String? reason,
  }) {
    return InventoryEvent(
      id: id,
      type: type,
      occurredAt: occurredAt,
      productId: productId,
      quantityDelta: quantityDelta,
      reason: reason,
    );
  }

  group('StatisticsCalculator.compute', () {
    test('aggregates consumption and waste by product', () {
      final t1 = DateTime.utc(2026, 7, 10);
      final t2 = DateTime.utc(2026, 7, 12);

      final result = calculator.compute(
        events: [
          event(
            id: 'e1',
            type: InventoryEventType.consume,
            occurredAt: t1,
            productId: 'p-milk',
            quantityDelta: -2,
          ),
          event(
            id: 'e2',
            type: InventoryEventType.consume,
            occurredAt: t2,
            productId: 'p-milk',
            quantityDelta: -1,
          ),
          event(
            id: 'e3',
            type: InventoryEventType.discard,
            occurredAt: t2,
            productId: 'p-bread',
            quantityDelta: -0.5,
            reason: kWasteReason,
          ),
          event(
            id: 'e4',
            type: InventoryEventType.discard,
            occurredAt: t2,
            productId: 'p-bread',
            quantityDelta: -1,
            reason: 'SPOILED',
          ),
        ],
      );

      final snapshot = result.valueOrNull!;
      expect(snapshot.mostConsumed, {'p-milk': 3});
      expect(snapshot.consumptionTotal, 3);
      expect(snapshot.wasteByProduct, {'p-bread': 0.5});
      expect(snapshot.wasteTotal, 0.5);
      expect(snapshot.dailyConsumption.isNotEmpty, isTrue);
      expect(snapshot.averageDailyUsage, greaterThan(0));
    });

    test('filters events by optional date range', () {
      final start = DateTime.utc(2026, 7, 11);
      final end = DateTime.utc(2026, 7, 15);

      final result = calculator.compute(
        events: [
          event(
            id: 'e1',
            type: InventoryEventType.consume,
            occurredAt: DateTime.utc(2026, 7, 10),
            productId: 'p-a',
            quantityDelta: -1,
          ),
          event(
            id: 'e2',
            type: InventoryEventType.consume,
            occurredAt: DateTime.utc(2026, 7, 12),
            productId: 'p-b',
            quantityDelta: -2,
          ),
          event(
            id: 'e3',
            type: InventoryEventType.consume,
            occurredAt: DateTime.utc(2026, 7, 16),
            productId: 'p-c',
            quantityDelta: -3,
          ),
        ],
        rangeStart: start,
        rangeEnd: end,
      );

      final snapshot = result.valueOrNull!;
      expect(snapshot.mostConsumed, {'p-b': 2});
      expect(snapshot.consumptionTotal, 2);
    });

    test('rejects an inverted date range', () {
      final result = calculator.compute(
        events: const <InventoryEvent>[],
        rangeStart: DateTime.utc(2026, 7, 20),
        rangeEnd: DateTime.utc(2026, 7, 10),
      );

      expect(result.isFailure, isTrue);
    });

    test('ignores events without productId or quantity delta', () {
      final result = calculator.compute(
        events: [
          event(
            id: 'e1',
            type: InventoryEventType.consume,
            occurredAt: DateTime.utc(2026, 7, 10),
            quantityDelta: -1,
          ),
          event(
            id: 'e2',
            type: InventoryEventType.changeLocation,
            occurredAt: DateTime.utc(2026, 7, 10),
            productId: 'p-a',
          ),
        ],
      );

      final snapshot = result.valueOrNull!;
      expect(snapshot.mostConsumed, isEmpty);
      expect(snapshot.consumptionTotal, 0);
      expect(snapshot.wasteTotal, 0);
    });
  });
}
