import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  const ranker = RecipeRanker();
  final today = DateOnly(2026, 7, 17);
  final now = DateTime.utc(2026, 7, 17);

  Recipe recipe({
    required String id,
    required String title,
    int prepTimeMinutes = 20,
    List<String> tags = const <String>[],
    List<RecipeIngredient> ingredients = const <RecipeIngredient>[],
  }) {
    return Recipe(
      id: id,
      title: title,
      prepTimeMinutes: prepTimeMinutes,
      steps: const <String>['step'],
      tags: tags,
      source: RecipeSource.builtin,
      ingredients: ingredients,
      createdAt: now,
      updatedAt: now,
    );
  }

  RecipeIngredient ingredient({
    required String id,
    required String recipeId,
    required String name,
    String? productId,
    bool optional = false,
  }) {
    return RecipeIngredient(
      id: id,
      recipeId: recipeId,
      name: name,
      productId: productId,
      optional: optional,
    );
  }

  group('RecipeRanker.rank', () {
    test('ranks by completion then missing then expiring then prep time', () {
      final partial = recipe(
        id: 'r1',
        title: 'Partial',
        prepTimeMinutes: 10,
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Eggs',
            productId: 'p-eggs',
          ),
          ingredient(
            id: 'i2',
            recipeId: 'r1',
            name: 'Milk',
            productId: 'p-milk',
          ),
        ],
      );
      final completeSlow = recipe(
        id: 'r2',
        title: 'Complete Slow',
        prepTimeMinutes: 40,
        ingredients: [
          ingredient(
            id: 'i3',
            recipeId: 'r2',
            name: 'Eggs',
            productId: 'p-eggs',
          ),
        ],
      );
      final completeFast = recipe(
        id: 'r3',
        title: 'Complete Fast',
        prepTimeMinutes: 5,
        ingredients: [
          ingredient(
            id: 'i4',
            recipeId: 'r3',
            name: 'Eggs',
            productId: 'p-eggs',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [partial, completeSlow, completeFast],
        inventory: const [
          AvailableInventoryItem(productId: 'p-eggs', amount: 6),
        ],
        today: today,
      );

      expect(matches.map((m) => m.recipe.title).toList(), [
        'Complete Fast',
        'Complete Slow',
        'Partial',
      ]);
      expect(matches.first.completionPercent, 100);
      expect(matches.last.completionPercent, 50);
      expect(matches.last.missingIngredientNames, ['Milk']);
    });

    test('matches unlinked ingredients by product name aliases', () {
      final carbonara = recipe(
        id: 'r1',
        title: 'Spaghetti Carbonara',
        ingredients: [
          ingredient(id: 'i1', recipeId: 'r1', name: 'Eggs'),
          ingredient(id: 'i2', recipeId: 'r1', name: 'Parmesan'),
          ingredient(id: 'i3', recipeId: 'r1', name: 'Black pepper'),
          ingredient(id: 'i4', recipeId: 'r1', name: 'Guanciale'),
        ],
      );

      final matches = ranker.rank(
        recipes: [carbonara],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 4,
            productName: 'Free range eggs',
          ),
          AvailableInventoryItem(
            productId: 'p2',
            amount: 1,
            productName: 'Parmigiano Reggiano',
          ),
          AvailableInventoryItem(
            productId: 'p3',
            amount: 1,
            productName: 'Ground pepper',
          ),
        ],
        today: today,
      );

      expect(matches, hasLength(1));
      expect(matches.single.availableCount, 3);
      expect(matches.single.requiredCount, 4);
      expect(matches.single.completionPercent, 75);
      expect(matches.single.missingIngredientNames, ['Guanciale']);
      expect(matches.single.availableIngredientNames, [
        'Eggs',
        'Parmesan',
        'Black pepper',
      ]);
    });

    test('ignores zero-quantity inventory', () {
      final toast = recipe(
        id: 'r1',
        title: 'Toast',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Bread',
            productId: 'p-bread',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [toast],
        inventory: const [
          AvailableInventoryItem(productId: 'p-bread', amount: 0),
        ],
        today: today,
      );

      expect(matches, isEmpty);
    });

    test('breaks equal completion by missing count then expiring stock', () {
      final withExpiring = recipe(
        id: 'r1',
        title: 'Expiring Bowl',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Milk',
            productId: 'p-milk-exp',
          ),
          ingredient(id: 'i2', recipeId: 'r1', name: 'Salt'),
        ],
      );
      final withoutExpiring = recipe(
        id: 'r2',
        title: 'Stable Bowl',
        ingredients: [
          ingredient(
            id: 'i3',
            recipeId: 'r2',
            name: 'Milk',
            productId: 'p-milk',
          ),
          ingredient(id: 'i4', recipeId: 'r2', name: 'Pepper'),
        ],
      );

      final matches = ranker.rank(
        recipes: [withoutExpiring, withExpiring],
        inventory: [
          AvailableInventoryItem(
            productId: 'p-milk-exp',
            amount: 1,
            expirationDate: DateOnly(2026, 7, 18),
          ),
          const AvailableInventoryItem(productId: 'p-milk', amount: 1),
        ],
        preferences: const RecipeRankingPreferences(expiringSoonWindowDays: 3),
        today: today,
      );

      expect(matches.first.recipe.title, 'Expiring Bowl');
      expect(matches.first.expiringAvailableCount, 1);
    });

    test('excludes recipes with blocked tags', () {
      final blocked = recipe(
        id: 'r1',
        title: 'Spicy Curry',
        tags: const <String>['spicy'],
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Rice',
            productId: 'p-rice',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [blocked],
        inventory: const [
          AvailableInventoryItem(productId: 'p-rice', amount: 1),
        ],
        preferences: const RecipeRankingPreferences(
          blockedTags: <String>['spicy'],
        ),
        today: today,
      );

      expect(matches, isEmpty);
    });

    test('excludes recipes exceeding max prep time', () {
      final slow = recipe(
        id: 'r1',
        title: 'Slow Roast',
        prepTimeMinutes: 120,
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Beef',
            productId: 'p-beef',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [slow],
        inventory: const [
          AvailableInventoryItem(productId: 'p-beef', amount: 1),
        ],
        preferences: const RecipeRankingPreferences(maxPrepTimeMinutes: 60),
        today: today,
      );

      expect(matches, isEmpty);
    });

    test('evaluate returns zero-match recipes for detail views', () {
      final soup = recipe(
        id: 'r1',
        title: 'Soup',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Carrots',
            productId: 'p-carrot',
          ),
        ],
      );

      final match = ranker.evaluate(
        recipe: soup,
        inventory: const [],
        today: today,
      );

      expect(match, isNotNull);
      expect(match!.availableCount, 0);
      expect(match.completionPercent, 0);
      expect(match.missingIngredientNames, ['Carrots']);
    });

    test('ignores optional ingredients for hard filters and coverage', () {
      final toast = recipe(
        id: 'r1',
        title: 'Toast',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Bread',
            productId: 'p-bread',
          ),
          ingredient(
            id: 'i2',
            recipeId: 'r1',
            name: 'Jam',
            productId: 'p-jam',
            optional: true,
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [toast],
        inventory: const [
          AvailableInventoryItem(productId: 'p-bread', amount: 2),
        ],
        today: today,
      );

      expect(matches, hasLength(1));
      expect(matches.single.availableCount, 1);
      expect(matches.single.requiredCount, 1);
      expect(matches.single.completionPercent, 100);
    });
  });
}
