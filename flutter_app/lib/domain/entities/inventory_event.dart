import 'package:fridgeos/domain/value_objects/enums.dart';

/// An immutable, append-only record of an inventory change
/// (see FR-HIST-1..4, docs/05-domain-model.md invariant 3).
///
/// This type is intentionally without a `copyWith`: events are never edited or
/// deleted. Each mutating inventory operation produces exactly one event within
/// the same transaction as the state change.
final class InventoryEvent {
  const InventoryEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.productId,
    this.inventoryItemId,
    this.locationId,
    this.fromLocationId,
    this.toLocationId,
    this.quantityDelta,
    this.quantityBefore,
    this.quantityAfter,
    this.reason,
    this.metadata = const <String, String>{},
  });

  final String id;
  final InventoryEventType type;

  /// UTC instant the event occurred.
  final DateTime occurredAt;

  final String? productId;

  /// Snapshot of the affected item id (not a foreign key: the item may later be
  /// soft-deleted while its history is retained).
  final String? inventoryItemId;
  final String? locationId;
  final String? fromLocationId;
  final String? toLocationId;
  final double? quantityDelta;
  final double? quantityBefore;
  final double? quantityAfter;

  /// Optional reason (e.g. `WASTE` for a discard).
  final String? reason;

  /// Small, validated structured context (e.g. source of the change).
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      other is InventoryEvent &&
      other.id == id &&
      other.type == type &&
      other.occurredAt == occurredAt &&
      other.productId == productId &&
      other.inventoryItemId == inventoryItemId &&
      other.locationId == locationId &&
      other.fromLocationId == fromLocationId &&
      other.toLocationId == toLocationId &&
      other.quantityDelta == quantityDelta &&
      other.quantityBefore == quantityBefore &&
      other.quantityAfter == quantityAfter &&
      other.reason == reason &&
      _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    occurredAt,
    productId,
    inventoryItemId,
    locationId,
    fromLocationId,
    toLocationId,
    quantityDelta,
    quantityBefore,
    quantityAfter,
    reason,
    Object.hashAllUnordered(
      metadata.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
