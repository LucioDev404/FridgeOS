import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/domain/repositories/recipe_repository.dart';
import 'package:fridgeos/domain/repositories/shopping_repository.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';

/// Application-layer use cases for recipes (FR-REC-*).
final class RecipeActions {
  const RecipeActions({
    required this.recipes,
    required this.products,
    required this.inventory,
    required this.shopping,
    required this.inventoryActions,
    required this.ranker,
    required this.sanitizer,
    required this.clock,
    required this.ids,
  });

  final RecipeRepository recipes;
  final ProductRepository products;
  final InventoryRepository inventory;
  final ShoppingRepository shopping;
  final InventoryActions inventoryActions;
  final RecipeRanker ranker;
  final InputSanitizer sanitizer;
  final Clock clock;
  final IdGenerator ids;

  /// Ranks all recipes against current stock and [preferences].
  Future<Result<List<RecipeMatch>>> listRanked({
    required List<InventoryItem> items,
    RecipeRankingPreferences preferences = const RecipeRankingPreferences(),
    DateOnly? today,
  }) async {
    final recipeList = await recipes.watchAll().first;
    final available = await _availableInventory(items);
    return Result.success(
      ranker.rank(
        recipes: recipeList,
        inventory: available,
        preferences: preferences,
        today: today,
      ),
    );
  }

  /// Adds missing required ingredients from [match] to the shopping list.
  Future<Result<void>> addMissingToShopping(RecipeMatch match) async {
    final now = clock.nowUtc();
    for (final name in match.missingIngredientNames) {
      final nameResult = sanitizer.requireText(
        name,
        maxLength: 200,
        fieldName: 'name',
      );
      if (nameResult.isFailure) continue;

      final item = ShoppingListItem(
        id: ids.newId(),
        name: nameResult.valueOrNull!,
        origin: ShoppingItemOrigin.manual,
        status: ShoppingItemStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final upsert = await shopping.upsert(item);
      if (upsert.isFailure) return upsert;
    }
    return const Result.success(null);
  }

  /// Best-effort consume of inventory for [recipe]'s available ingredients.
  ///
  /// Matches by linked [RecipeIngredient.productId] first, then by the same
  /// fuzzy name matching used by [RecipeRanker].
  Future<Result<void>> cooked(Recipe recipe) async {
    final items = await inventory.watchActiveItems().first;
    final available = await _availableInventory(items);
    final byProduct = <String, List<InventoryItem>>{};
    for (final item in items) {
      if (item.quantity.amount <= 0) continue;
      byProduct.putIfAbsent(item.productId, () => <InventoryItem>[]).add(item);
    }

    for (final ingredient in recipe.requiredIngredients) {
      if (!ranker.isIngredientAvailable(ingredient, available)) continue;

      final stockItems = _stockForIngredient(
        ingredient: ingredient,
        byProduct: byProduct,
        available: available,
      );
      if (stockItems.isEmpty) continue;

      final amount = _consumeAmount(ingredient);
      var remaining = amount;
      for (final item in stockItems) {
        if (remaining <= 0) break;
        final consumeAmount = remaining
            .clamp(0, item.quantity.amount)
            .toDouble();
        if (consumeAmount <= 0) continue;

        final result = await inventoryActions.consume(
          item: item,
          amount: consumeAmount,
        );
        if (result.isFailure) return result;
        remaining -= consumeAmount;
      }
    }
    return const Result.success(null);
  }

  Future<List<AvailableInventoryItem>> _availableInventory(
    List<InventoryItem> items,
  ) async {
    final catalog = await products.watchAll().first;
    final namesById = {for (final product in catalog) product.id: product.name};
    return items
        .where((i) => i.isActive && i.quantity.amount > 0)
        .map(
          (i) => AvailableInventoryItem(
            productId: i.productId,
            productName: namesById[i.productId],
            amount: i.quantity.amount,
            expirationDate: i.expirationDate,
          ),
        )
        .toList();
  }

  List<InventoryItem> _stockForIngredient({
    required RecipeIngredient ingredient,
    required Map<String, List<InventoryItem>> byProduct,
    required List<AvailableInventoryItem> available,
  }) {
    final productId = ingredient.productId;
    if (productId != null) {
      return byProduct[productId] ?? const <InventoryItem>[];
    }

    final matchedIds = <String>{};
    final probe = RecipeIngredient(
      id: ingredient.id,
      recipeId: ingredient.recipeId,
      name: ingredient.name,
    );
    for (final stock in available) {
      if (ranker.isIngredientAvailable(probe, [stock])) {
        matchedIds.add(stock.productId);
      }
    }

    final result = <InventoryItem>[];
    for (final id in matchedIds) {
      result.addAll(byProduct[id] ?? const <InventoryItem>[]);
    }
    return result;
  }

  double _consumeAmount(RecipeIngredient ingredient) {
    final quantity = ingredient.quantity;
    if (quantity == null || quantity.amount <= 0) return 1;
    return quantity.amount;
  }
}
