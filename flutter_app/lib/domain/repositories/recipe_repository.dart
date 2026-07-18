import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/recipe.dart';

/// Contract for reading and writing recipes with their ingredients.
abstract interface class RecipeRepository {
  /// Emits all non-deleted recipes with ingredients joined, updating on change.
  Stream<List<Recipe>> watchAll();

  /// Persists [recipe] and its ingredients (replaces ingredient rows).
  Future<Result<void>> upsert(Recipe recipe);

  /// Seeds missing built-in catalog recipes. Idempotent; never overwrites
  /// existing recipe rows (supports future local edits / sync).
  Future<Result<void>> ensureBuiltinRecipes();
}
