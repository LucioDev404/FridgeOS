import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/recipes/builtin_recipe_catalog.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/repositories/recipe_repository.dart';
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
      await _seedMissingBuiltinRecipes();
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
    await _seedMissingBuiltinRecipes();
  }

  /// Upserts every builtin catalog recipe.
  ///
  /// New ids are inserted; existing builtin rows are refreshed so catalog
  /// metadata (images, cuisine, substitutions) stays current. User-authored
  /// recipes keep distinct ids and are never touched.
  Future<void> _seedMissingBuiltinRecipes() async {
    final catalog = BuiltinRecipeCatalog.build(DateTime.now().toUtc());
    for (final recipe in catalog) {
      await upsert(recipe);
    }
  }
}
