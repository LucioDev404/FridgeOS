import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/features/inventory/application/inventory_projection.dart';

void main() {
  const policy = ExpirationPolicy();
  final today = DateOnly(2026, 7, 17);
  final ts = DateTime.utc(2026, 7, 1);

  Product product(String id, String name) => Product(
    id: id,
    name: name,
    category: FoodCategory.other,
    defaultUnit: MeasurementUnit.pieces,
    source: ProductSource.manual,
    createdAt: ts,
    updatedAt: ts,
  );

  Location location(String id) => Location(
    id: id,
    name: 'Fridge',
    type: LocationType.refrigerator,
    createdAt: ts,
    updatedAt: ts,
  );

  InventoryItem item(
    String id,
    String productId, {
    DateOnly? expiration,
    double amount = 1,
    double? threshold,
  }) => InventoryItem(
    id: id,
    productId: productId,
    locationId: 'loc',
    quantity: Quantity(amount, MeasurementUnit.pieces),
    expirationDate: expiration,
    lowStockThreshold: threshold,
    createdAt: ts,
    updatedAt: ts,
  );

  test('joins items with product and location and classifies status', () {
    final lines = buildInventoryLineItems(
      items: [item('i1', 'p1', expiration: DateOnly(2026, 7, 18))],
      products: [product('p1', 'Yogurt')],
      locations: [location('loc')],
      policy: policy,
      today: today,
      window: 3,
    );
    expect(lines, hasLength(1));
    expect(lines.single.product.name, 'Yogurt');
    expect(lines.single.status, ExpirationStatus.expiringSoon);
    expect(lines.single.daysToExpiry, 1);
  });

  test('skips items whose product or location is missing', () {
    final lines = buildInventoryLineItems(
      items: [item('i1', 'missing')],
      products: const [],
      locations: [location('loc')],
      policy: policy,
      today: today,
      window: 3,
    );
    expect(lines, isEmpty);
  });

  test('sorts expired first, then soonest expiry, then name', () {
    final lines = buildInventoryLineItems(
      items: [
        item('fresh', 'p_fresh', expiration: DateOnly(2026, 8, 1)),
        item('expired', 'p_expired', expiration: DateOnly(2026, 7, 10)),
        item('soon', 'p_soon', expiration: DateOnly(2026, 7, 19)),
      ],
      products: [
        product('p_fresh', 'Fresh'),
        product('p_expired', 'Expired'),
        product('p_soon', 'Soon'),
      ],
      locations: [location('loc')],
      policy: policy,
      today: today,
      window: 3,
    );
    expect(lines.map((l) => l.item.id).toList(), ['expired', 'soon', 'fresh']);
  });

  test('computeSummary counts statuses and low stock', () {
    final lines = buildInventoryLineItems(
      items: [
        item('a', 'p1', expiration: DateOnly(2026, 7, 10)),
        item('b', 'p2', expiration: DateOnly(2026, 7, 18)),
        item('c', 'p3', amount: 1, threshold: 2),
      ],
      products: [product('p1', 'A'), product('p2', 'B'), product('p3', 'C')],
      locations: [location('loc')],
      policy: policy,
      today: today,
      window: 3,
    );
    final summary = computeSummary(lines);
    expect(summary.totalItems, 3);
    expect(summary.expired, 1);
    expect(summary.expiringSoon, 1);
    expect(summary.lowStock, 1);
  });
}
