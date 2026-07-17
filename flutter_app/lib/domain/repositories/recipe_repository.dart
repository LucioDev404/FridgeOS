import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/recipe.dart';

/// Contract for reading and writing recipes with their ingredients.
abstract interface class RecipeRepository {
  /// Emits all non-deleted recipes with ingredients joined, updating on change.
  Stream<List<Recipe>> watchAll();

  /// Persists [recipe] and its ingredients (replaces ingredient rows).
  Future<Result<void>> upsert(Recipe recipe);

  /// Seeds built-in recipes when the table is empty. Idempotent.
  Future<Result<void>> ensureBuiltinRecipes();
}
