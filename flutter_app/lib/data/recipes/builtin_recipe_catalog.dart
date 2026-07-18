import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// Local offline recipe seed catalog.
///
/// Recipes are persisted via [RecipeRepository] on first launch (and when new
/// builtin ids appear). Keep this list extendable — do not hardcode recipes in
/// widgets. Future remote sync can upsert into the same Drift tables using
/// [RecipeSource.builtin] / [RecipeSource.user].
final class BuiltinRecipeCatalog {
  const BuiltinRecipeCatalog._();

  /// Builds the current builtin recipe set with timestamps [now].
  static List<Recipe> build(DateTime now) {
    Recipe recipe({
      required String id,
      required String title,
      required int prepTimeMinutes,
      required List<String> steps,
      required List<String> tags,
      required List<RecipeIngredient> ingredients,
      int? servings,
      RecipeDifficulty? difficulty,
    }) {
      return Recipe(
        id: id,
        title: title,
        prepTimeMinutes: prepTimeMinutes,
        steps: steps,
        tags: tags,
        source: RecipeSource.builtin,
        ingredients: ingredients,
        servings: servings,
        difficulty: difficulty,
        createdAt: now,
        updatedAt: now,
      );
    }

    RecipeIngredient ing({
      required String id,
      required String recipeId,
      required String name,
      Quantity? quantity,
      bool optional = false,
    }) {
      return RecipeIngredient(
        id: id,
        recipeId: recipeId,
        name: name,
        quantity: quantity,
        optional: optional,
      );
    }

    return [
      recipe(
        id: 'seed-recipe-scrambled-eggs',
        title: 'Scrambled eggs',
        prepTimeMinutes: 10,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: const ['breakfast', 'quick'],
        steps: const [
          'Beat eggs with a pinch of salt.',
          'Melt butter in a pan over medium heat.',
          'Cook eggs, stirring gently, until set.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-eggs-1',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Eggs',
            quantity: Quantity(3, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-eggs-2',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Butter',
            quantity: Quantity(15, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-eggs-3',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Salt',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-pasta',
        title: 'Tomato pasta',
        prepTimeMinutes: 25,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: const ['dinner', 'italian'],
        steps: const [
          'Boil pasta until al dente.',
          'Simmer tomatoes with olive oil and garlic.',
          'Toss pasta with sauce and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-pasta-1',
            recipeId: 'seed-recipe-pasta',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-pasta-2',
            recipeId: 'seed-recipe-pasta',
            name: 'Tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-pasta-3',
            recipeId: 'seed-recipe-pasta',
            name: 'Olive oil',
            quantity: Quantity(30, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-pasta-4',
            recipeId: 'seed-recipe-pasta',
            name: 'Garlic',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-salad',
        title: 'Garden salad',
        prepTimeMinutes: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: const ['lunch', 'vegetarian'],
        steps: const [
          'Wash and chop lettuce and vegetables.',
          'Toss with olive oil and vinegar.',
          'Season and serve immediately.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-salad-1',
            recipeId: 'seed-recipe-salad',
            name: 'Lettuce',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-salad-2',
            recipeId: 'seed-recipe-salad',
            name: 'Tomatoes',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-salad-3',
            recipeId: 'seed-recipe-salad',
            name: 'Olive oil',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-smoothie',
        title: 'Berry smoothie',
        prepTimeMinutes: 5,
        servings: 1,
        difficulty: RecipeDifficulty.easy,
        tags: const ['breakfast', 'drink'],
        steps: const [
          'Add berries, yogurt and milk to a blender.',
          'Blend until smooth and serve cold.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-smoothie-1',
            recipeId: 'seed-recipe-smoothie',
            name: 'Berries',
            quantity: Quantity(150, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-smoothie-2',
            recipeId: 'seed-recipe-smoothie',
            name: 'Yogurt',
            quantity: Quantity(125, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-smoothie-3',
            recipeId: 'seed-recipe-smoothie',
            name: 'Milk',
            quantity: Quantity(200, MeasurementUnit.milliliters),
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-carbonara',
        title: 'Spaghetti Carbonara',
        prepTimeMinutes: 25,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        tags: const ['dinner', 'italian'],
        steps: const [
          'Boil spaghetti in salted water until al dente.',
          'Cook guanciale (or bacon) until crisp.',
          'Whisk eggs with grated Parmesan and black pepper.',
          'Toss hot pasta with guanciale, then off heat fold in egg mixture.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-carb-1',
            recipeId: 'seed-recipe-carbonara',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-carb-2',
            recipeId: 'seed-recipe-carbonara',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-carb-3',
            recipeId: 'seed-recipe-carbonara',
            name: 'Parmesan',
            quantity: Quantity(50, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-carb-4',
            recipeId: 'seed-recipe-carbonara',
            name: 'Black pepper',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-carb-5',
            recipeId: 'seed-recipe-carbonara',
            name: 'Guanciale',
            quantity: Quantity(80, MeasurementUnit.grams),
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-grilled-cheese',
        title: 'Grilled cheese sandwich',
        prepTimeMinutes: 12,
        servings: 1,
        difficulty: RecipeDifficulty.easy,
        tags: const ['lunch', 'quick'],
        steps: const [
          'Butter two slices of bread.',
          'Add cheese between the slices.',
          'Toast in a pan until golden and the cheese melts.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-gc-1',
            recipeId: 'seed-recipe-grilled-cheese',
            name: 'Bread',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-gc-2',
            recipeId: 'seed-recipe-grilled-cheese',
            name: 'Cheese',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-gc-3',
            recipeId: 'seed-recipe-grilled-cheese',
            name: 'Butter',
            quantity: Quantity(10, MeasurementUnit.grams),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-chicken-rice',
        title: 'Chicken and rice',
        prepTimeMinutes: 35,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        tags: const ['dinner'],
        steps: const [
          'Season and pan-sear chicken until cooked through.',
          'Cook rice according to package directions.',
          'Serve chicken over rice with a side of vegetables if available.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-cr-1',
            recipeId: 'seed-recipe-chicken-rice',
            name: 'Chicken',
            quantity: Quantity(300, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-cr-2',
            recipeId: 'seed-recipe-chicken-rice',
            name: 'Rice',
            quantity: Quantity(150, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-cr-3',
            recipeId: 'seed-recipe-chicken-rice',
            name: 'Onion',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-omelette',
        title: 'Cheese omelette',
        prepTimeMinutes: 12,
        servings: 1,
        difficulty: RecipeDifficulty.easy,
        tags: const ['breakfast', 'quick'],
        steps: const [
          'Beat eggs with a splash of milk.',
          'Cook in a buttered pan, add cheese, then fold.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-om-1',
            recipeId: 'seed-recipe-omelette',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-om-2',
            recipeId: 'seed-recipe-omelette',
            name: 'Cheese',
            quantity: Quantity(30, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-om-3',
            recipeId: 'seed-recipe-omelette',
            name: 'Milk',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-garlic-toast',
        title: 'Garlic toast',
        prepTimeMinutes: 8,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        tags: const ['side', 'quick'],
        steps: const [
          'Mix softened butter with minced garlic.',
          'Spread on bread and toast until golden.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-gt-1',
            recipeId: 'seed-recipe-garlic-toast',
            name: 'Bread',
            quantity: Quantity(4, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-gt-2',
            recipeId: 'seed-recipe-garlic-toast',
            name: 'Butter',
            quantity: Quantity(20, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-gt-3',
            recipeId: 'seed-recipe-garlic-toast',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-yogurt-bowl',
        title: 'Yogurt berry bowl',
        prepTimeMinutes: 5,
        servings: 1,
        difficulty: RecipeDifficulty.easy,
        tags: const ['breakfast', 'quick'],
        steps: const [
          'Spoon yogurt into a bowl.',
          'Top with berries and serve cold.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-yb-1',
            recipeId: 'seed-recipe-yogurt-bowl',
            name: 'Yogurt',
            quantity: Quantity(150, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-yb-2',
            recipeId: 'seed-recipe-yogurt-bowl',
            name: 'Berries',
            quantity: Quantity(80, MeasurementUnit.grams),
          ),
        ],
      ),
    ];
  }
}
