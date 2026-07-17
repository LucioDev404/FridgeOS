import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/features/expiration/application/notification_scheduler.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';

void main() {
  final now = DateTime.utc(2026, 7, 17);
  final location = Location(
    id: 'loc-1',
    name: 'Fridge',
    type: LocationType.refrigerator,
    createdAt: now,
    updatedAt: now,
  );
  final product = Product(
    id: 'p-milk',
    name: 'Milk',
    category: FoodCategory.dairy,
    defaultUnit: MeasurementUnit.liters,
    source: ProductSource.manual,
    createdAt: now,
    updatedAt: now,
  );

  InventoryLineItem line({
    required ExpirationStatus status,
    DateOnly? expiration,
  }) {
    return InventoryLineItem(
      item: InventoryItem(
        id: 'item-1',
        productId: product.id,
        locationId: location.id,
        quantity: Quantity(1, MeasurementUnit.liters),
        expirationDate: expiration,
        createdAt: now,
        updatedAt: now,
      ),
      product: product,
      location: location,
      status: status,
      daysToExpiry: expiration == null
          ? null
          : DateOnly(2026, 7, 17).daysUntil(expiration),
    );
  }

  group('computeDigestEntries', () {
    test('includes expired and expiring soon, excludes fresh', () {
      final entries = computeDigestEntries([
        line(status: ExpirationStatus.fresh, expiration: DateOnly(2026, 8, 1)),
        line(
          status: ExpirationStatus.expiringSoon,
          expiration: DateOnly(2026, 7, 19),
        ),
        line(
          status: ExpirationStatus.expired,
          expiration: DateOnly(2026, 7, 10),
        ),
      ]);

      expect(entries, hasLength(2));
      expect(entries.first.status, ExpirationStatus.expired);
      expect(entries.last.status, ExpirationStatus.expiringSoon);
    });
  });

  group('InMemoryNotificationScheduler', () {
    test('stores digest entries at the configured time', () async {
      final scheduler = InMemoryNotificationScheduler();
      final items = [
        line(
          status: ExpirationStatus.expired,
          expiration: DateOnly(2026, 7, 10),
        ),
      ];

      final result = await scheduler.scheduleExpirationDigest(
        items: items,
        digestTime: '09:00',
      );

      expect(result.isSuccess, isTrue);
      expect(scheduler.lastDigestTime, '09:00');
      expect(scheduler.scheduledEntries, hasLength(1));
      expect(scheduler.scheduledEntries.single.productName, 'Milk');
    });

    test('cancelAll clears scheduled entries', () async {
      final scheduler = InMemoryNotificationScheduler();
      await scheduler.scheduleExpirationDigest(
        items: [
          line(
            status: ExpirationStatus.expiringSoon,
            expiration: DateOnly(2026, 7, 18),
          ),
        ],
        digestTime: '09:00',
      );

      await scheduler.cancelAll();
      expect(scheduler.scheduledEntries, isEmpty);
      expect(scheduler.cancelCount, 1);
    });
  });
}
