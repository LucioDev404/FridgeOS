import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/repositories/shopping_repository.dart';
import 'package:fridgeos/domain/services/shopping_list_policy.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// Cooldown before a dismissed AUTO item can be re-proposed (FR-SHOP-5).
const Duration kShoppingDismissCooldown = Duration(days: 7);

/// Application-layer use cases for the shopping list (FR-SHOP-*).
final class ShoppingActions {
  const ShoppingActions({
    required this.shopping,
    required this.policy,
    required this.sanitizer,
    required this.clock,
    required this.ids,
  });

  final ShoppingRepository shopping;
  final ShoppingListPolicy policy;
  final InputSanitizer sanitizer;
  final Clock clock;
  final IdGenerator ids;

  /// Adds a manually entered item to the pending list.
  Future<Result<void>> addManual({
    required String name,
    double? amount,
    MeasurementUnit? unit,
  }) async {
    final nameResult = sanitizer.requireText(
      name,
      maxLength: 200,
      fieldName: 'name',
    );
    if (nameResult.isFailure) return Result.failure(nameResult.failureOrNull!);

    Quantity? quantity;
    if (amount != null) {
      if (amount <= 0) {
        return const Result.failure(
          ValidationFailure('Quantity must be greater than zero'),
        );
      }
      if (unit == null) {
        return const Result.failure(
          ValidationFailure('Unit is required when quantity is set'),
        );
      }
      quantity = Quantity(amount, unit);
    }

    final now = clock.nowUtc();
    return shopping.upsert(
      ShoppingListItem(
        id: ids.newId(),
        name: nameResult.valueOrNull!,
        quantity: quantity,
        origin: ShoppingItemOrigin.manual,
        status: ShoppingItemStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Marks [item] as done (checked off).
  Future<Result<void>> markDone(ShoppingListItem item) async {
    return shopping.upsert(
      item.copyWith(status: ShoppingItemStatus.done, updatedAt: clock.nowUtc()),
    );
  }

  /// Dismisses [item] with a 7-day cooldown before re-proposal.
  Future<Result<void>> dismiss(ShoppingListItem item) async {
    final now = clock.nowUtc();
    return shopping.upsert(
      item.copyWith(
        status: ShoppingItemStatus.dismissed,
        dismissedUntil: now.add(kShoppingDismissCooldown),
        updatedAt: now,
      ),
    );
  }

  /// Proposes AUTO items from low/zero stock and upserts new pending entries.
  Future<Result<int>> syncAutoProposals({
    required List<InventoryItem> items,
    required List<Product> products,
  }) async {
    final now = clock.nowUtc();
    final existing = await shopping.watchAll().first;

    final productById = {for (final p in products) p.id: p};
    final snapshots = <InventoryStockSnapshot>[];
    for (final item in items) {
      if (!item.isActive) continue;
      final product = productById[item.productId];
      if (product == null) continue;
      snapshots.add(
        InventoryStockSnapshot(
          productId: item.productId,
          name: product.name,
          amount: item.quantity.amount,
          lowStockThreshold: item.lowStockThreshold,
        ),
      );
    }

    final proposals = policy.proposeFromInventory(
      inventory: snapshots,
      existingItems: existing,
      now: now,
    );

    var added = 0;
    for (final proposal in proposals) {
      final item = ShoppingListItem(
        id: ids.newId(),
        name: proposal.name,
        productId: proposal.productId,
        quantity: proposal.suggestedAmount == null
            ? null
            : Quantity(proposal.suggestedAmount!, MeasurementUnit.pieces),
        origin: ShoppingItemOrigin.auto,
        status: ShoppingItemStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final upsert = await shopping.upsert(item);
      if (upsert.isFailure) return Result.failure(upsert.failureOrNull!);
      added++;
    }
    return Result.success(added);
  }
}
