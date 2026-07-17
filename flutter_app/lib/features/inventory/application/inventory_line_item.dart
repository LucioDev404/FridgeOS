import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// A denormalized, display-ready view of a stock item that joins the
/// [InventoryItem] with its [Product] and [Location] and the derived
/// expiration [status]. Built in the application layer so widgets stay dumb.
final class InventoryLineItem {
  const InventoryLineItem({
    required this.item,
    required this.product,
    required this.location,
    required this.status,
    this.daysToExpiry,
  });

  final InventoryItem item;
  final Product product;
  final Location location;
  final ExpirationStatus status;

  /// Days until expiry (negative when past); `null` when no expiration date.
  final int? daysToExpiry;

  String get id => item.id;
  bool get isBelowThreshold => item.isBelowThreshold;
}
