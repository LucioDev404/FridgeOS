import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// A single ingredient required by a [Recipe]. May be linked to a catalog
/// [productId] or referenced only by free-text [name].
final class RecipeIngredient {
  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.name,
    this.productId,
    this.quantity,
    this.optional = false,
  });

  final String id;
  final String recipeId;
  final String? productId;
  final String name;
  final Quantity? quantity;
  final bool optional;

  @override
  bool operator ==(Object other) =>
      other is RecipeIngredient &&
      other.id == id &&
      other.recipeId == recipeId &&
      other.productId == productId &&
      other.name == name &&
      other.quantity == quantity &&
      other.optional == optional;

  @override
  int get hashCode =>
      Object.hash(id, recipeId, productId, name, quantity, optional);
}

/// A recipe with ordered preparation steps and its ingredient list.
final class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.prepTimeMinutes,
    required this.steps,
    required this.tags,
    required this.source,
    required this.ingredients,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final int prepTimeMinutes;
  final List<String> steps;
  final List<String> tags;
  final RecipeSource source;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Non-optional ingredients that must be available to cook the recipe.
  Iterable<RecipeIngredient> get requiredIngredients =>
      ingredients.where((i) => !i.optional);

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.title == title &&
      other.prepTimeMinutes == prepTimeMinutes &&
      _listEquals(other.steps, steps) &&
      _listEquals(other.tags, tags) &&
      other.source == source &&
      _listEquals(other.ingredients, ingredients) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    prepTimeMinutes,
    Object.hashAll(steps),
    Object.hashAll(tags),
    source,
    Object.hashAll(ingredients),
    createdAt,
    updatedAt,
    deletedAt,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
