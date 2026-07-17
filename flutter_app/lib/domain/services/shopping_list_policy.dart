import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Active stock snapshot used to decide auto-proposed shopping items.
final class InventoryStockSnapshot {
  const InventoryStockSnapshot({
    required this.productId,
    required this.name,
    required this.amount,
    this.lowStockThreshold,
  });

  final String productId;
  final String name;
  final double amount;
  final double? lowStockThreshold;
}

/// A shopping-list entry proposed by [ShoppingListPolicy].
final class ProposedShoppingItem {
  const ProposedShoppingItem({
    required this.name,
    this.productId,
    this.suggestedAmount,
  });

  final String name;
  final String? productId;
  final double? suggestedAmount;
}

/// Pure policy that proposes AUTO shopping-list items from low or zero stock
/// (see FR-SHOP-2/5, docs/05-domain-model.md §4).
final class ShoppingListPolicy {
  const ShoppingListPolicy();

  /// Proposes items for products that are out of stock or at/below their
  /// low-stock threshold.
  ///
  /// Skips a product when:
  /// * a [ShoppingItemStatus.pending] item already exists with the same
  ///   [ShoppingListItem.productId] or the same [ShoppingListItem.name]
  ///   (case-insensitive);
  /// * a dismissed AUTO item for the same product has [ShoppingListItem.dismissedUntil]
  ///   still in the future relative to [now].
  List<ProposedShoppingItem> proposeFromInventory({
    required List<InventoryStockSnapshot> inventory,
    required List<ShoppingListItem> existingItems,
    required DateTime now,
  }) {
    final pendingProductIds = <String>{};
    final pendingNames = <String>{};
    final dismissedUntilByProductId = <String, DateTime>{};

    for (final item in existingItems) {
      if (item.isDeleted) continue;

      if (item.status == ShoppingItemStatus.pending) {
        final productId = item.productId;
        if (productId != null) pendingProductIds.add(productId);
        pendingNames.add(item.name.toLowerCase());
        continue;
      }

      if (item.status == ShoppingItemStatus.dismissed) {
        final productId = item.productId;
        final dismissedUntil = item.dismissedUntil;
        if (productId == null || dismissedUntil == null) continue;
        if (dismissedUntil.isAfter(now)) {
          dismissedUntilByProductId[productId] = dismissedUntil;
        }
      }
    }

    final proposals = <ProposedShoppingItem>[];
    final seenProductIds = <String>{};

    for (final stock in inventory) {
      if (!_needsRestock(stock)) continue;
      if (!seenProductIds.add(stock.productId)) continue;
      if (pendingProductIds.contains(stock.productId)) continue;
      if (pendingNames.contains(stock.name.toLowerCase())) continue;

      final dismissedUntil = dismissedUntilByProductId[stock.productId];
      if (dismissedUntil != null && dismissedUntil.isAfter(now)) continue;

      proposals.add(
        ProposedShoppingItem(
          name: stock.name,
          productId: stock.productId,
          suggestedAmount: _suggestedAmount(stock),
        ),
      );
    }

    proposals.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return proposals;
  }

  bool _needsRestock(InventoryStockSnapshot stock) {
    if (stock.amount == 0) return true;
    final threshold = stock.lowStockThreshold;
    if (threshold == null) return false;
    return stock.amount <= threshold;
  }

  double? _suggestedAmount(InventoryStockSnapshot stock) {
    final threshold = stock.lowStockThreshold;
    if (stock.amount == 0) {
      return threshold ?? 1;
    }
    if (threshold == null) return null;
    final deficit = threshold - stock.amount;
    return deficit > 0 ? deficit : 1;
  }
}
