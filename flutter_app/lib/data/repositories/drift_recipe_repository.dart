import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/repositories/recipe_repository.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [RecipeRepository].
final class DriftRecipeRepository implements RecipeRepository {
  DriftRecipeRepository(this._db);

  final AppDatabase _db;
  bool _seedChecked = false;

  @override
  Stream<List<Recipe>> watchAll() {
    return Stream.fromFuture(
      _ensureBuiltinRecipesOnce(),
    ).asyncExpand((_) => _watchRecipes());
  }

  Stream<List<Recipe>> _watchRecipes() {
    final recipeQuery = _db.select(_db.recipes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.title)]);

    return recipeQuery.watch().asyncMap((rows) async {
      if (rows.isEmpty) return const <Recipe>[];

      final recipeIds = rows.map((r) => r.id).toList();
      final ingredientRows = await (_db.select(
        _db.recipeIngredients,
      )..where((t) => t.recipeId.isIn(recipeIds))).get();

      final ingredientsByRecipe = <String, List<RecipeIngredient>>{};
      for (final row in ingredientRows) {
        final ingredient = recipeIngredientFromRow(row);
        ingredientsByRecipe
            .putIfAbsent(ingredient.recipeId, () => <RecipeIngredient>[])
            .add(ingredient);
      }

      return rows
          .map(
            (row) => recipeFromRow(
              row,
              ingredientsByRecipe[row.id] ?? const <RecipeIngredient>[],
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<void>> upsert(Recipe recipe) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.recipes)
            .insertOnConflictUpdate(recipeToCompanion(recipe));
        await (_db.delete(
          _db.recipeIngredients,
        )..where((t) => t.recipeId.equals(recipe.id))).go();
        for (final ingredient in recipe.ingredients) {
          await _db
              .into(_db.recipeIngredients)
              .insertOnConflictUpdate(recipeIngredientToCompanion(ingredient));
        }
      });
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('upsert recipe failed: $e'));
    }
  }

  @override
  Future<Result<void>> ensureBuiltinRecipes() async {
    try {
      await _seedBuiltinRecipesIfEmpty();
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(
        PersistenceFailure('ensureBuiltinRecipes failed: $e'),
      );
    }
  }

  Future<void> _ensureBuiltinRecipesOnce() async {
    if (_seedChecked) return;
    _seedChecked = true;
    await _seedBuiltinRecipesIfEmpty();
  }

  Future<void> _seedBuiltinRecipesIfEmpty() async {
    final existing = await (_db.select(
      _db.recipes,
    )..where((t) => t.deletedAt.isNull())).get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc();
    final recipes = _builtinRecipes(now);
    for (final recipe in recipes) {
      await upsert(recipe);
    }
  }

  List<Recipe> _builtinRecipes(DateTime now) {
    Recipe build({
      required String id,
      required String title,
      required int prepTimeMinutes,
      required List<String> steps,
      required List<String> tags,
      required List<RecipeIngredient> ingredients,
    }) {
      return Recipe(
        id: id,
        title: title,
        prepTimeMinutes: prepTimeMinutes,
        steps: steps,
        tags: tags,
        source: RecipeSource.builtin,
        ingredients: ingredients,
        createdAt: now,
        updatedAt: now,
      );
    }

    return [
      build(
        id: 'seed-recipe-scrambled-eggs',
        title: 'Scrambled eggs',
        prepTimeMinutes: 10,
        tags: const ['breakfast', 'quick'],
        steps: const [
          'Beat eggs with a pinch of salt.',
          'Melt butter in a pan over medium heat.',
          'Cook eggs, stirring gently, until set.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'seed-ing-eggs-1',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Eggs',
            quantity: Quantity(3, MeasurementUnit.pieces),
          ),
          RecipeIngredient(
            id: 'seed-ing-eggs-2',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Butter',
            quantity: Quantity(15, MeasurementUnit.grams),
          ),
          const RecipeIngredient(
            id: 'seed-ing-eggs-3',
            recipeId: 'seed-recipe-scrambled-eggs',
            name: 'Salt',
            optional: true,
          ),
        ],
      ),
      build(
        id: 'seed-recipe-pasta',
        title: 'Tomato pasta',
        prepTimeMinutes: 25,
        tags: const ['dinner', 'italian'],
        steps: const [
          'Boil pasta until al dente.',
          'Simmer tomatoes with olive oil and garlic.',
          'Toss pasta with sauce and serve.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'seed-ing-pasta-1',
            recipeId: 'seed-recipe-pasta',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
          ),
          RecipeIngredient(
            id: 'seed-ing-pasta-2',
            recipeId: 'seed-recipe-pasta',
            name: 'Tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
          ),
          RecipeIngredient(
            id: 'seed-ing-pasta-3',
            recipeId: 'seed-recipe-pasta',
            name: 'Olive oil',
            quantity: Quantity(30, MeasurementUnit.milliliters),
          ),
        ],
      ),
      build(
        id: 'seed-recipe-salad',
        title: 'Garden salad',
        prepTimeMinutes: 15,
        tags: const ['lunch', 'vegetarian'],
        steps: const [
          'Wash and chop lettuce and vegetables.',
          'Toss with olive oil and vinegar.',
          'Season and serve immediately.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'seed-ing-salad-1',
            recipeId: 'seed-recipe-salad',
            name: 'Lettuce',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          RecipeIngredient(
            id: 'seed-ing-salad-2',
            recipeId: 'seed-recipe-salad',
            name: 'Tomatoes',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          const RecipeIngredient(
            id: 'seed-ing-salad-3',
            recipeId: 'seed-recipe-salad',
            name: 'Olive oil',
            optional: true,
          ),
        ],
      ),
      build(
        id: 'seed-recipe-smoothie',
        title: 'Berry smoothie',
        prepTimeMinutes: 5,
        tags: const ['breakfast', 'drink'],
        steps: const [
          'Add berries, yogurt and milk to a blender.',
          'Blend until smooth and serve cold.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'seed-ing-smoothie-1',
            recipeId: 'seed-recipe-smoothie',
            name: 'Mixed berries',
            quantity: Quantity(150, MeasurementUnit.grams),
          ),
          RecipeIngredient(
            id: 'seed-ing-smoothie-2',
            recipeId: 'seed-recipe-smoothie',
            name: 'Yogurt',
            quantity: Quantity(125, MeasurementUnit.grams),
          ),
          RecipeIngredient(
            id: 'seed-ing-smoothie-3',
            recipeId: 'seed-recipe-smoothie',
            name: 'Milk',
            quantity: Quantity(200, MeasurementUnit.milliliters),
          ),
        ],
      ),
    ];
  }
}
