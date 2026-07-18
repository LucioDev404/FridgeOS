import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/diet_preference.dart';
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
    String? cuisine,
  }) {
    return Recipe(
      id: id,
      title: title,
      prepTimeMinutes: prepTimeMinutes,
      steps: const <String>['step'],
      tags: tags,
      source: RecipeSource.builtin,
      ingredients: ingredients,
      cuisine: cuisine,
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
    List<String> substitutions = const <String>[],
  }) {
    return RecipeIngredient(
      id: id,
      recipeId: recipeId,
      name: name,
      productId: productId,
      optional: optional,
      substitutions: substitutions,
    );
  }

  group('RecipeRanker.rank', () {
    test('exact ingredient match counts as available', () {
      final eggs = recipe(
        id: 'r1',
        title: 'Eggs',
        ingredients: [ingredient(id: 'i1', recipeId: 'r1', name: 'Eggs')],
      );

      final matches = ranker.rank(
        recipes: [eggs],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 6,
            productName: 'Eggs',
            locationName: 'Refrigerator',
          ),
        ],
        today: today,
      );

      expect(matches.single.isReadyToCook, isTrue);
      expect(matches.single.completionPercent, 100);
      expect(
        matches.single.ingredientDetails.single.kind,
        IngredientMatchKind.exact,
      );
      expect(matches.single.ingredientDetails.single.locations, [
        'Refrigerator',
      ]);
    });

    test('similar ingredients are partial only, never ready to cook', () {
      final tomatoes = recipe(
        id: 'r1',
        title: 'Tomato salad',
        ingredients: [
          ingredient(id: 'i1', recipeId: 'r1', name: 'Fresh tomatoes'),
        ],
      );

      final matches = ranker.rank(
        recipes: [tomatoes],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 1,
            productName: 'Tomato sauce',
          ),
        ],
        today: today,
      );

      // Partial alone does not count as available → filtered from ranked list.
      expect(matches, isEmpty);

      final evaluated = ranker.evaluate(
        recipe: tomatoes,
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 1,
            productName: 'Tomato sauce',
          ),
        ],
        today: today,
      )!;
      expect(evaluated.isReadyToCook, isFalse);
      expect(
        evaluated.ingredientDetails.single.kind,
        IngredientMatchKind.partial,
      );
      expect(evaluated.availableCount, 0);
    });

    test('explicit substitution counts as available', () {
      final carbonara = recipe(
        id: 'r1',
        title: 'Carbonara',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Guanciale',
            substitutions: const ['Pancetta', 'Bacon'],
          ),
        ],
      );

      final matches = ranker.rank(
        recipes: [carbonara],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 1,
            productName: 'Bacon',
          ),
        ],
        today: today,
      );

      expect(matches.single.isReadyToCook, isTrue);
      expect(
        matches.single.ingredientDetails.single.kind,
        IngredientMatchKind.substitution,
      );
    });

    test('optional ingredients do not reduce match score', () {
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

      expect(matches.single.requiredCount, 1);
      expect(matches.single.availableCount, 1);
      expect(matches.single.isReadyToCook, isTrue);
      expect(matches.single.optionalIngredientNames, ['Jam']);
    });

    test('duplicate products across fridge and pantry aggregate locations', () {
      final milk = recipe(
        id: 'r1',
        title: 'Milk drink',
        ingredients: [ingredient(id: 'i1', recipeId: 'r1', name: 'Milk')],
      );

      final matches = ranker.rank(
        recipes: [milk],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p-milk',
            amount: 1,
            productName: 'Milk',
            locationName: 'Refrigerator',
          ),
          AvailableInventoryItem(
            productId: 'p-milk',
            amount: 1,
            productName: 'Milk',
            locationName: 'Pantry',
          ),
        ],
        today: today,
      );

      expect(matches.single.isReadyToCook, isTrue);
      expect(
        matches.single.ingredientDetails.single.locations,
        containsAll(['Refrigerator', 'Pantry']),
      );
    });

    test('empty inventory yields no ranked recipes', () {
      final soup = recipe(
        id: 'r1',
        title: 'Soup',
        ingredients: [
          ingredient(
            id: 'i1',
            recipeId: 'r1',
            name: 'Carrots',
            productId: 'p1',
          ),
        ],
      );
      expect(
        ranker.rank(recipes: [soup], inventory: const [], today: today),
        isEmpty,
      );
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
      expect(
        ranker.rank(
          recipes: [toast],
          inventory: const [
            AvailableInventoryItem(productId: 'p-bread', amount: 0),
          ],
          today: today,
        ),
        isEmpty,
      );
    });

    test('ranks by completion then expiring then missing then prep time', () {
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
    });

    test('matches Italian inventory names to English recipe ingredients', () {
      final pasta = recipe(
        id: 'r1',
        title: 'Tomato pasta',
        cuisine: 'Italian',
        ingredients: [
          ingredient(id: 'i1', recipeId: 'r1', name: 'Pasta'),
          ingredient(id: 'i2', recipeId: 'r1', name: 'Tomatoes'),
          ingredient(id: 'i3', recipeId: 'r1', name: 'Olive oil'),
        ],
      );

      final matches = ranker.rank(
        recipes: [pasta],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 1,
            productName: 'Pasta',
          ),
          AvailableInventoryItem(
            productId: 'p2',
            amount: 2,
            productName: 'Pomodoro',
          ),
          AvailableInventoryItem(
            productId: 'p3',
            amount: 1,
            productName: 'Olio',
          ),
        ],
        today: today,
      );

      expect(matches, hasLength(1));
      expect(matches.single.isReadyToCook, isTrue);
      expect(matches.single.completionPercent, 100);
    });

    test('vegan diet hides dairy recipes', () {
      final cheesy = recipe(
        id: 'r1',
        title: 'Cheese bowl',
        ingredients: [
          ingredient(id: 'i1', recipeId: 'r1', name: 'Cheese'),
          ingredient(id: 'i2', recipeId: 'r1', name: 'Vegetables'),
        ],
      );
      final veg = recipe(
        id: 'r2',
        title: 'Rice bowl',
        tags: const ['vegan'],
        ingredients: [
          ingredient(id: 'i3', recipeId: 'r2', name: 'Rice'),
          ingredient(id: 'i4', recipeId: 'r2', name: 'Vegetables'),
        ],
      );

      final matches = ranker.rank(
        recipes: [cheesy, veg],
        inventory: const [
          AvailableInventoryItem(
            productId: 'p1',
            amount: 1,
            productName: 'Latte',
          ),
          AvailableInventoryItem(
            productId: 'p2',
            amount: 1,
            productName: 'Formaggio',
          ),
          AvailableInventoryItem(
            productId: 'p3',
            amount: 1,
            productName: 'Verdure',
          ),
          AvailableInventoryItem(
            productId: 'p4',
            amount: 1,
            productName: 'Riso',
          ),
        ],
        preferences: const RecipeRankingPreferences(diet: DietPreference.vegan),
        today: today,
      );

      expect(matches.map((m) => m.recipe.title), ['Rice bowl']);
    });

    test('eggplant does not match eggs (no false positive)', () {
      final eggs = recipe(
        id: 'r1',
        title: 'Scramble',
        ingredients: [ingredient(id: 'i1', recipeId: 'r1', name: 'Eggs')],
      );
      expect(
        ranker.rank(
          recipes: [eggs],
          inventory: const [
            AvailableInventoryItem(
              productId: 'p1',
              amount: 1,
              productName: 'Eggplant',
            ),
          ],
          today: today,
        ),
        isEmpty,
      );
    });
  });
}
