import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/services/ingredient_lexicon.dart';
import 'package:fridgeos/domain/value_objects/diet_preference.dart';

void main() {
  const lexicon = IngredientLexicon();
  const diet = RecipeDietPolicy();

  group('IngredientLexicon', () {
    test('matches tomato across languages', () {
      for (final name in const [
        'Tomato',
        'Tomatoes',
        'Pomodoro',
        'Tomate',
        'トマト',
      ]) {
        expect(lexicon.canonicalize(name), 'tomato', reason: name);
        expect(lexicon.isExactMatch(name, 'Tomato'), isTrue, reason: name);
      }
    });

    test('matches milk phrases like Latte intero', () {
      expect(lexicon.isExactMatch('Latte intero', 'Milk'), isTrue);
      expect(lexicon.isExactMatch('latte', 'Milch'), isTrue);
    });

    test('matches olive oil aliases including Olio', () {
      expect(lexicon.isExactMatch('Olio', 'Olive oil'), isTrue);
      expect(lexicon.isExactMatch("Olio d'oliva", 'Olive oil'), isTrue);
    });

    test('tomato sauce is related but not exact with fresh tomato', () {
      expect(lexicon.isExactMatch('Tomato sauce', 'Fresh tomatoes'), isFalse);
      expect(lexicon.isRelated('Tomato sauce', 'Pomodoro'), isTrue);
    });

    test('pasta aliases match', () {
      expect(lexicon.isExactMatch('Pasta', 'Spaghetti'), isTrue);
    });
  });

  group('RecipeDietPolicy', () {
    test('vegan excludes dairy and eggs', () {
      expect(
        diet.isCompatible(
          tags: const ['italian'],
          ingredientNames: const ['Milk', 'Pasta'],
          diet: DietPreference.vegan,
        ),
        isFalse,
      );
      expect(
        diet.isCompatible(
          tags: const ['italian'],
          ingredientNames: const ['Latte', 'Formaggio'],
          diet: DietPreference.vegan,
        ),
        isFalse,
      );
    });

    test('vegetarian allows cheese but not chicken', () {
      expect(
        diet.isCompatible(
          tags: const ['italian'],
          ingredientNames: const ['Cheese', 'Pasta'],
          diet: DietPreference.vegetarian,
        ),
        isTrue,
      );
      expect(
        diet.isCompatible(
          tags: const ['dinner'],
          ingredientNames: const ['Pollo', 'Riso'],
          diet: DietPreference.vegetarian,
        ),
        isFalse,
      );
    });

    test('omnivore allows everything', () {
      expect(
        diet.isCompatible(
          tags: const [],
          ingredientNames: const ['Beef', 'Milk'],
          diet: DietPreference.omnivore,
        ),
        isTrue,
      );
    });
  });
}
