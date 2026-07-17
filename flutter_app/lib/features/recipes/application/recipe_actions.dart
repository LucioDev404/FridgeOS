import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
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
    required this.inventory,
    required this.shopping,
    required this.inventoryActions,
    required this.ranker,
    required this.sanitizer,
    required this.clock,
    required this.ids,
  });

  final RecipeRepository recipes;
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
    final available = items
        .where((i) => i.isActive && i.quantity.amount > 0)
        .map(
          (i) => AvailableInventoryItem(
            productId: i.productId,
            amount: i.quantity.amount,
            expirationDate: i.expirationDate,
          ),
        )
        .toList();
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

  /// Best-effort consume of linked inventory for [recipe]'s available ingredients.
  Future<Result<void>> cooked(Recipe recipe) async {
    final items = await inventory.watchActiveItems().first;
    final byProduct = <String, List<InventoryItem>>{};
    for (final item in items) {
      if (item.quantity.amount <= 0) continue;
      byProduct.putIfAbsent(item.productId, () => <InventoryItem>[]).add(item);
    }

    for (final ingredient in recipe.requiredIngredients) {
      final productId = ingredient.productId;
      if (productId == null) continue;

      final stock = byProduct[productId];
      if (stock == null || stock.isEmpty) continue;

      final amount = _consumeAmount(ingredient);
      var remaining = amount;
      for (final item in stock) {
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

  double _consumeAmount(RecipeIngredient ingredient) {
    final quantity = ingredient.quantity;
    if (quantity == null || quantity.amount <= 0) return 1;
    return quantity.amount;
  }
}
