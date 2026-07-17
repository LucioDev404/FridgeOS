import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// A concrete stock of a product in a location, with a quantity and optional
/// expiration date. The same product in two locations is two distinct
/// [InventoryItem]s (see FR-INV-10, docs/05-domain-model.md §4).
final class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.productId,
    required this.locationId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.expirationDate,
    this.lowStockThreshold,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String productId;
  final String locationId;
  final Quantity quantity;
  final DateOnly? expirationDate;

  /// When set, stock at or below this amount makes the product a candidate for
  /// the shopping list (see FR-INV-11, FR-SHOP-2).
  final double? lowStockThreshold;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone. An item is soft-deleted when depleted (quantity 0)
  /// or explicitly removed; its history is retained (FR-INV-4).
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;

  /// Whether stock is at or below the configured low-stock threshold.
  bool get isBelowThreshold {
    final threshold = lowStockThreshold;
    if (threshold == null) return false;
    return quantity.amount <= threshold;
  }

  InventoryItem copyWith({
    String? locationId,
    Quantity? quantity,
    DateOnly? expirationDate,
    double? lowStockThreshold,
    String? note,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InventoryItem(
      id: id,
      productId: productId,
      locationId: locationId ?? this.locationId,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryItem &&
      other.id == id &&
      other.productId == productId &&
      other.locationId == locationId &&
      other.quantity == quantity &&
      other.expirationDate == expirationDate &&
      other.lowStockThreshold == lowStockThreshold &&
      other.note == note &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    locationId,
    quantity,
    expirationDate,
    lowStockThreshold,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
