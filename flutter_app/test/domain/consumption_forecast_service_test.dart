import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/services/consumption_forecast_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  const service = ConsumptionForecastService();

  test('forecasts run-out from consume history and current stock', () {
    final forecasts = service.forecast(
      events: [
        InventoryEvent(
          id: 'e1',
          type: InventoryEventType.consume,
          occurredAt: DateTime.utc(2026, 7, 1),
          productId: 'p-milk',
          quantityDelta: -1,
        ),
        InventoryEvent(
          id: 'e2',
          type: InventoryEventType.consume,
          occurredAt: DateTime.utc(2026, 7, 4),
          productId: 'p-milk',
          quantityDelta: -1,
        ),
        InventoryEvent(
          id: 'e3',
          type: InventoryEventType.consume,
          occurredAt: DateTime.utc(2026, 7, 7),
          productId: 'p-milk',
          quantityDelta: -1,
        ),
      ],
      currentQuantityByProduct: const {'p-milk': 1},
    );

    expect(forecasts, hasLength(1));
    expect(forecasts.single.productId, 'p-milk');
    expect(forecasts.single.averageDaysBetweenConsumption, closeTo(3, 0.01));
    expect(forecasts.single.estimatedDaysUntilEmpty, isNotNull);
    expect(forecasts.single.estimatedDaysUntilEmpty!, closeTo(2, 0.5));
  });

  test('ignores products with fewer than two consume events', () {
    final forecasts = service.forecast(
      events: [
        InventoryEvent(
          id: 'e1',
          type: InventoryEventType.consume,
          occurredAt: DateTime.utc(2026, 7, 1),
          productId: 'p-eggs',
          quantityDelta: -1,
        ),
      ],
    );
    expect(forecasts, isEmpty);
  });
}
