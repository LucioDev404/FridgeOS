import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/services/shopping_list_policy.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  const policy = ShoppingListPolicy();
  final now = DateTime.utc(2026, 7, 17, 12);

  ShoppingListItem shoppingItem({
    required String id,
    required String name,
    String? productId,
    ShoppingItemStatus status = ShoppingItemStatus.pending,
    DateTime? dismissedUntil,
  }) {
    return ShoppingListItem(
      id: id,
      name: name,
      productId: productId,
      origin: ShoppingItemOrigin.auto,
      status: status,
      dismissedUntil: dismissedUntil,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ShoppingListPolicy.proposeFromInventory', () {
    test('proposes for zero stock and low-stock threshold', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(productId: 'p-milk', name: 'Milk', amount: 0),
          InventoryStockSnapshot(
            productId: 'p-eggs',
            name: 'Eggs',
            amount: 1,
            lowStockThreshold: 6,
          ),
        ],
        existingItems: const <ShoppingListItem>[],
        now: now,
      );

      expect(proposals, hasLength(2));
      expect(
        proposals.map((p) => p.name).toList(),
        containsAll(<String>['Eggs', 'Milk']),
      );
      expect(
        proposals.firstWhere((p) => p.productId == 'p-milk').suggestedAmount,
        1,
      );
      expect(
        proposals.firstWhere((p) => p.productId == 'p-eggs').suggestedAmount,
        5,
      );
    });

    test('skips when a pending item exists for the same product or name', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(productId: 'p-milk', name: 'Milk', amount: 0),
          InventoryStockSnapshot(
            productId: 'p-bread',
            name: 'Bread',
            amount: 0,
          ),
        ],
        existingItems: [
          shoppingItem(id: 's1', name: 'Milk', productId: 'p-other'),
          shoppingItem(id: 's2', name: 'bread', productId: 'p-bread'),
        ],
        now: now,
      );

      expect(proposals, isEmpty);
    });

    test('respects dismissal cooldown for the same product', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(
            productId: 'p-yogurt',
            name: 'Yogurt',
            amount: 0,
          ),
        ],
        existingItems: [
          shoppingItem(
            id: 's1',
            name: 'Yogurt',
            productId: 'p-yogurt',
            status: ShoppingItemStatus.dismissed,
            dismissedUntil: now.add(const Duration(days: 1)),
          ),
        ],
        now: now,
      );

      expect(proposals, isEmpty);
    });

    test('re-proposes after dismissal cooldown expires', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(
            productId: 'p-yogurt',
            name: 'Yogurt',
            amount: 0,
          ),
        ],
        existingItems: [
          shoppingItem(
            id: 's1',
            name: 'Yogurt',
            productId: 'p-yogurt',
            status: ShoppingItemStatus.dismissed,
            dismissedUntil: now.subtract(const Duration(minutes: 1)),
          ),
        ],
        now: now,
      );

      expect(proposals, hasLength(1));
      expect(proposals.single.productId, 'p-yogurt');
    });

    test('does not propose when stock is above threshold', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(
            productId: 'p-rice',
            name: 'Rice',
            amount: 5,
            lowStockThreshold: 2,
          ),
        ],
        existingItems: const <ShoppingListItem>[],
        now: now,
      );

      expect(proposals, isEmpty);
    });

    test('deduplicates inventory rows for the same product', () {
      final proposals = policy.proposeFromInventory(
        inventory: const [
          InventoryStockSnapshot(
            productId: 'p-pasta',
            name: 'Pasta',
            amount: 0,
          ),
          InventoryStockSnapshot(
            productId: 'p-pasta',
            name: 'Pasta duplicate row',
            amount: 0,
          ),
        ],
        existingItems: const <ShoppingListItem>[],
        now: now,
      );

      expect(proposals, hasLength(1));
    });
  });
}
