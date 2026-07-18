import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/recipes/builtin_recipe_catalog.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  test('BuiltinRecipeCatalog is international and image-backed', () {
    final recipes = BuiltinRecipeCatalog.build(DateTime.utc(2026, 7, 18));
    expect(recipes.length, greaterThanOrEqualTo(20));
    expect(recipes.map((r) => r.id).toSet(), hasLength(recipes.length));
    expect(recipes.every((r) => r.source == RecipeSource.builtin), isTrue);
    expect(
      recipes.every((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty),
      isTrue,
    );
    expect(
      recipes.every((r) => r.cuisine != null && r.cuisine!.isNotEmpty),
      isTrue,
    );
    expect(recipes.every((r) => r.description != null), isTrue);

    final cuisines = recipes.map((r) => r.cuisine!.toLowerCase()).toSet();
    expect(cuisines.any((c) => c.contains('italian')), isTrue);
    expect(
      cuisines.any(
        (c) =>
            c.contains('japan') ||
            c.contains('china') ||
            c.contains('korea') ||
            c.contains('thai') ||
            c.contains('vietnam') ||
            c.contains('india') ||
            c.contains('asian'),
      ),
      isTrue,
    );
    expect(
      recipes.any(
        (r) => r.tags.any((t) => t.toLowerCase().contains('vegetarian')),
      ),
      isTrue,
    );

    final americanish = recipes.where((r) {
      final t = r.title.toLowerCase();
      return t.contains('burger') ||
          t.contains('sandwich') ||
          t.contains('grilled cheese');
    }).length;
    expect(americanish / recipes.length, lessThan(0.2));
  });
}
