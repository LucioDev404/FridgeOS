import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/recipes/application/recipe_actions.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/container.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late InventoryActions inventoryActions;
  late RecipeActions recipeActions;

  setUp(() {
    container = createTestContainer(today: DateOnly(2026, 7, 17));
    db = container.read(appDatabaseProvider);
    inventoryActions = container.read(inventoryActionsProvider);
    recipeActions = container.read(recipeActionsProvider);
  });

  Future<String> addProductAndStock({
    required String name,
    required String productId,
    double amount = 2,
  }) async {
    await db
        .into(db.products)
        .insertOnConflictUpdate(
          productToCompanion(
            Product(
              id: productId,
              name: name,
              category: FoodCategory.dairy,
              defaultUnit: MeasurementUnit.liters,
              source: ProductSource.manual,
              createdAt: DateTime.utc(2026, 7, 17),
              updatedAt: DateTime.utc(2026, 7, 17),
            ),
          ),
        );
    final add = await inventoryActions.addStockForProduct(
      product: Product(
        id: productId,
        name: name,
        category: FoodCategory.dairy,
        defaultUnit: MeasurementUnit.liters,
        source: ProductSource.manual,
        createdAt: DateTime.utc(2026, 7, 17),
        updatedAt: DateTime.utc(2026, 7, 17),
      ),
      unit: MeasurementUnit.liters,
      amount: amount,
      locationId: kDefaultFridgeId,
    );
    expect(add.isSuccess, isTrue);
    return productId;
  }

  test('listRanked returns seeded builtin recipes matching stock', () async {
    await addProductAndStock(name: 'Eggs', productId: 'p-eggs', amount: 6);
    await addProductAndStock(name: 'Butter', productId: 'p-butter', amount: 1);

    final items = await db.select(db.inventoryItems).get();
    final result = await recipeActions.listRanked(
      items: items.map(inventoryItemFromRow).toList(),
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNotEmpty);
    expect(
      result.valueOrNull!.any(
        (m) => m.recipe.id == 'seed-recipe-scrambled-eggs',
      ),
      isTrue,
    );
  });

  test('addMissingToShopping creates pending manual items', () async {
    final recipe = Recipe(
      id: 'r-test',
      title: 'Test soup',
      prepTimeMinutes: 20,
      steps: const ['cook'],
      tags: const [],
      source: RecipeSource.user,
      ingredients: const [
        RecipeIngredient(id: 'i1', recipeId: 'r-test', name: 'Carrots'),
      ],
      createdAt: DateTime.utc(2026, 7, 17),
      updatedAt: DateTime.utc(2026, 7, 17),
    );
    await container.read(recipeRepositoryProvider).upsert(recipe);

    final match = RecipeMatch(
      recipe: recipe,
      score: 0,
      missingIngredientNames: const ['Carrots'],
      availableIngredientNames: const [],
      availableCount: 0,
      requiredCount: 1,
    );

    final add = await recipeActions.addMissingToShopping(match);
    expect(add.isSuccess, isTrue);

    final rows = await db.select(db.shoppingListItems).get();
    expect(rows.map((r) => r.name), contains('Carrots'));
  });

  test('cooked consumes linked inventory best-effort', () async {
    const productId = 'p-milk-recipe';
    await addProductAndStock(name: 'Milk', productId: productId, amount: 2);

    final recipe = Recipe(
      id: 'r-milk',
      title: 'Milk drink',
      prepTimeMinutes: 5,
      steps: const ['pour'],
      tags: const [],
      source: RecipeSource.user,
      ingredients: [
        RecipeIngredient(
          id: 'i-milk',
          recipeId: 'r-milk',
          name: 'Milk',
          productId: productId,
          quantity: Quantity(1, MeasurementUnit.liters),
        ),
      ],
      createdAt: DateTime.utc(2026, 7, 17),
      updatedAt: DateTime.utc(2026, 7, 17),
    );
    await container.read(recipeRepositoryProvider).upsert(recipe);

    final cooked = await recipeActions.cooked(recipe);
    expect(cooked.isSuccess, isTrue);

    final item = (await db.select(db.inventoryItems).get()).single;
    expect(item.quantityAmount, 1);
  });
}
