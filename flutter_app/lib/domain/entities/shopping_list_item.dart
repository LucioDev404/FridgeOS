import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// An item on the shopping list, either entered manually or generated
/// automatically from low/zero stock (see FR-SHOP-1..5).
final class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.origin,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.productId,
    this.quantity,
    this.dismissedUntil,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String? productId;
  final Quantity? quantity;
  final ShoppingItemOrigin origin;
  final ShoppingItemStatus status;

  /// For AUTO items: suppress re-proposal until this instant (cooldown).
  final DateTime? dismissedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ShoppingListItem copyWith({
    String? name,
    String? productId,
    Quantity? quantity,
    ShoppingItemOrigin? origin,
    ShoppingItemStatus? status,
    DateTime? dismissedUntil,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ShoppingListItem(
      id: id,
      name: name ?? this.name,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      origin: origin ?? this.origin,
      status: status ?? this.status,
      dismissedUntil: dismissedUntil ?? this.dismissedUntil,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShoppingListItem &&
      other.id == id &&
      other.name == name &&
      other.productId == productId &&
      other.quantity == quantity &&
      other.origin == origin &&
      other.status == status &&
      other.dismissedUntil == dismissedUntil &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    productId,
    quantity,
    origin,
    status,
    dismissedUntil,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
