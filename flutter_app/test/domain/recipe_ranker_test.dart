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
    test('ranks by coverage then title deterministically', () {
      final pasta = recipe(
        id: 'r1',
        title: 'Pasta',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Pasta',
            productId: 'p-pasta',
          ),
          ingredient(id: 'i2', recipeId: 'r1', name: 'Salt'),
        ],
      );
      final salad = recipe(
        id: 'r2',
        title: 'Salad',
        ingredients: [
          ingredient(
            id: 'i3',
            recipeId: 'r2',
            name: 'Lettuce',
            productId: 'p-lettuce',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [pasta, salad],
        inventory: const [
          AvailableInventoryItem(productId: 'p-pasta', amount: 2),
          AvailableInventoryItem(productId: 'p-lettuce', amount: 1),
        ],
        today: today,
      );

      expect(matches, hasLength(2));
      expect(matches.first.recipe.title, 'Salad');
      expect(matches.first.score, greaterThan(matches.last.score));
    });

    test('breaks score ties by title ascending', () {
      final alpha = recipe(
        id: 'r1',
        title: 'Alpha Bowl',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Rice',
            productId: 'p-rice',
          ),
        ],
      );
      final beta = recipe(
        id: 'r2',
        title: 'Beta Bowl',
        ingredients: [
          ingredient(
            id: 'i2',
            recipeId: 'r2',
            name: 'Rice',
            productId: 'p-rice',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [beta, alpha],
        inventory: const [
          AvailableInventoryItem(productId: 'p-rice', amount: 1),
        ],
        today: today,
      );

      expect(matches.map((m) => m.recipe.title).toList(), [
        'Alpha Bowl',
        'Beta Bowl',
      ]);
      expect(matches.first.score, closeTo(matches.last.score, 0.0001));
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

    test(
      'includes partial matches when a linked required ingredient is missing',
      () {
        final omelette = recipe(
          id: 'r1',
          title: 'Omelette',
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

        final matches = ranker.rank(
          recipes: [omelette],
          inventory: const [
            AvailableInventoryItem(productId: 'p-eggs', amount: 6),
          ],
          today: today,
        );

        expect(matches, hasLength(1));
        expect(matches.single.availableCount, 1);
        expect(matches.single.requiredCount, 2);
        expect(matches.single.missingIngredientNames, ['Milk']);
      },
    );

    test(
      'includes partial matches when only unlinked ingredients are missing',
      () {
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
            ingredient(id: 'i2', recipeId: 'r1', name: 'Salt'),
          ],
        );

        final matches = ranker.rank(
          recipes: [soup],
          inventory: const [
            AvailableInventoryItem(productId: 'p-carrot', amount: 3),
          ],
          today: today,
        );

        expect(matches, hasLength(1));
        expect(matches.single.availableCount, 1);
        expect(matches.single.requiredCount, 2);
        expect(matches.single.missingIngredientNames, ['Salt']);
      },
    );

    test('boosts score for favorite tags and expiring stock', () {
      final expiringSoon = DateOnly(2026, 7, 18);
      final plain = recipe(
        id: 'r1',
        title: 'Plain Rice',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Rice',
            productId: 'p-rice',
          ),
        ],
      );
      final favorite = recipe(
        id: 'r2',
        title: 'Favorite Rice',
        tags: const <String>['quick'],
        ingredients: [
          ingredient(
            id: 'i2',
            recipeId: 'r2',
            name: 'Rice',
            productId: 'p-rice-exp',
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [plain, favorite],
        inventory: [
          const AvailableInventoryItem(productId: 'p-rice', amount: 1),
          AvailableInventoryItem(
            productId: 'p-rice-exp',
            amount: 1,
            expirationDate: expiringSoon,
          ),
        ],
        preferences: const RecipeRankingPreferences(
          favoriteTags: <String>['quick'],
          expiringSoonWindowDays: 3,
        ),
        today: today,
      );

      expect(matches.first.recipe.title, 'Favorite Rice');
      expect(matches.first.score, greaterThan(matches.last.score));
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
      expect(matches.single.score, closeTo(0.7, 0.001));
    });
  });
}
