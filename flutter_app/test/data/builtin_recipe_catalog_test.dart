import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/recipes/builtin_recipe_catalog.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  test('BuiltinRecipeCatalog exposes extendable offline recipes', () {
    final recipes = BuiltinRecipeCatalog.build(DateTime.utc(2026, 7, 18));
    expect(recipes, isNotEmpty);
    expect(recipes.map((r) => r.id).toSet(), hasLength(recipes.length));
    expect(recipes.every((r) => r.source == RecipeSource.builtin), isTrue);
    expect(recipes.every((r) => r.ingredients.isNotEmpty), isTrue);
    expect(recipes.every((r) => r.steps.isNotEmpty), isTrue);
    expect(
      recipes.any((r) => r.title == 'Spaghetti Carbonara'),
      isTrue,
    );
  });
}
