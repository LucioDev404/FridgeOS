import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';

/// Pure projection helpers that turn raw inventory rows into sorted,
/// display-ready [InventoryLineItem]s and dashboard [InventorySummary].
/// Kept free of Riverpod/Flutter so they are trivially unit-testable.

const Map<ExpirationStatus, int> _statusOrder = {
  ExpirationStatus.expired: 0,
  ExpirationStatus.expiringSoon: 1,
  ExpirationStatus.fresh: 2,
};

/// Joins [items] with their [products]/[locations] and classifies expiration.
/// Items whose product or location is missing are skipped. The result is
/// sorted by urgency (expired first), then soonest expiry, then product name.
List<InventoryLineItem> buildInventoryLineItems({
  required List<InventoryItem> items,
  required List<Product> products,
  required List<Location> locations,
  required ExpirationPolicy policy,
  required DateOnly today,
  required int window,
}) {
  final productById = {for (final p in products) p.id: p};
  final locationById = {for (final l in locations) l.id: l};

  final lines = <InventoryLineItem>[];
  for (final item in items) {
    final product = productById[item.productId];
    final location = locationById[item.locationId];
    if (product == null || location == null) continue;
    lines.add(
      InventoryLineItem(
        item: item,
        product: product,
        location: location,
        status: policy.classify(
          expirationDate: item.expirationDate,
          today: today,
          windowDays: window,
        ),
        daysToExpiry: policy.daysUntilExpiry(item.expirationDate, today),
      ),
    );
  }

  lines.sort(_compareLines);
  return lines;
}

int _compareLines(InventoryLineItem a, InventoryLineItem b) {
  final byStatus = _statusOrder[a.status]!.compareTo(_statusOrder[b.status]!);
  if (byStatus != 0) return byStatus;
  final aDays = a.daysToExpiry;
  final bDays = b.daysToExpiry;
  if (aDays != null && bDays != null && aDays != bDays) {
    return aDays.compareTo(bDays);
  }
  if (aDays != null && bDays == null) return -1;
  if (aDays == null && bDays != null) return 1;
  return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
}

/// Computes the glanceable dashboard counters from projected [lines].
InventorySummary computeSummary(List<InventoryLineItem> lines) {
  var expiringSoon = 0;
  var expired = 0;
  var lowStock = 0;
  for (final line in lines) {
    switch (line.status) {
      case ExpirationStatus.expiringSoon:
        expiringSoon++;
      case ExpirationStatus.expired:
        expired++;
      case ExpirationStatus.fresh:
        break;
    }
    if (line.isBelowThreshold) lowStock++;
  }
  return InventorySummary(
    totalItems: lines.length,
    expiringSoon: expiringSoon,
    expired: expired,
    lowStock: lowStock,
  );
}

/// Immutable dashboard summary.
final class InventorySummary {
  const InventorySummary({
    required this.totalItems,
    required this.expiringSoon,
    required this.expired,
    required this.lowStock,
  });

  final int totalItems;
  final int expiringSoon;
  final int expired;
  final int lowStock;
}
