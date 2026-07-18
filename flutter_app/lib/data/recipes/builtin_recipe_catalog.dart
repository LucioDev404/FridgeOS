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
      required String description,
      required String cuisine,
      required String imageUrl,
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
        description: description,
        cuisine: cuisine,
        imageUrl: imageUrl,
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
      List<String> substitutions = const <String>[],
    }) {
      return RecipeIngredient(
        id: id,
        recipeId: recipeId,
        name: name,
        quantity: quantity,
        optional: optional,
        substitutions: substitutions,
      );
    }

    return [
      // --- Existing seed ids (enriched) ---
      recipe(
        id: 'seed-recipe-scrambled-eggs',
        title: 'Scrambled eggs',
        prepTimeMinutes: 10,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'American',
        description:
            'Soft, creamy scrambled eggs finished with butter — a reliable quick breakfast.',
        imageUrl:
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80',
        tags: const ['breakfast', 'quick', 'american'],
        steps: const [
          'Beat eggs with a pinch of salt.',
          'Melt butter in a pan over medium-low heat.',
          'Cook eggs, stirring gently, until just set and still soft.',
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
            substitutions: const ['Olive oil'],
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
        cuisine: 'Italian',
        description:
            'Simple Italian pasta tossed in a garlicky tomato sauce — pantry-friendly and comforting.',
        imageUrl:
            'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
        tags: const ['dinner', 'italian', 'vegetarian'],
        steps: const [
          'Boil pasta in salted water until al dente; reserve a splash of pasta water.',
          'Simmer crushed tomatoes with olive oil and garlic until slightly thickened.',
          'Toss pasta with the sauce, loosen with pasta water if needed, and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-pasta-1',
            recipeId: 'seed-recipe-pasta',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Spaghetti', 'Penne', 'Rigatoni'],
          ),
          ing(
            id: 'seed-ing-pasta-2',
            recipeId: 'seed-recipe-pasta',
            name: 'Tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Canned tomatoes', 'Tomato passata'],
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
            substitutions: const ['Garlic powder'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-salad',
        title: 'Garden salad',
        prepTimeMinutes: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Mediterranean',
        description:
            'A crisp mixed salad with tomatoes and a light olive-oil dressing.',
        imageUrl:
            'https://images.unsplash.com/photo-1512621774951-5407ee5f7ad0?w=800&q=80',
        tags: const ['lunch', 'vegetarian', 'mediterranean', 'quick'],
        steps: const [
          'Wash and chop lettuce and tomatoes.',
          'Toss with olive oil and a splash of vinegar.',
          'Season with salt and pepper and serve immediately.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-salad-1',
            recipeId: 'seed-recipe-salad',
            name: 'Lettuce',
            quantity: Quantity(1, MeasurementUnit.pieces),
            substitutions: const ['Mixed greens', 'Romaine'],
          ),
          ing(
            id: 'seed-ing-salad-2',
            recipeId: 'seed-recipe-salad',
            name: 'Tomatoes',
            quantity: Quantity(2, MeasurementUnit.pieces),
            substitutions: const ['Cherry tomatoes'],
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
        cuisine: 'American',
        description:
            'A cold blended breakfast drink with yogurt and mixed berries.',
        imageUrl:
            'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800&q=80',
        tags: const ['breakfast', 'drink', 'quick', 'vegetarian'],
        steps: const [
          'Add frozen berries, yogurt, and milk to a blender.',
          'Blend until smooth and serve immediately.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-smoothie-1',
            recipeId: 'seed-recipe-smoothie',
            name: 'Frozen berries',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const [
              'Strawberries',
              'Blueberries',
              'Raspberries',
              'Mixed berries',
            ],
          ),
          ing(
            id: 'seed-ing-smoothie-2',
            recipeId: 'seed-recipe-smoothie',
            name: 'Yogurt',
            quantity: Quantity(125, MeasurementUnit.grams),
            substitutions: const ['Greek yogurt', 'Plant yogurt'],
          ),
          ing(
            id: 'seed-ing-smoothie-3',
            recipeId: 'seed-recipe-smoothie',
            name: 'Milk',
            quantity: Quantity(200, MeasurementUnit.milliliters),
            substitutions: const ['Oat milk', 'Almond milk'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-carbonara',
        title: 'Spaghetti Carbonara',
        prepTimeMinutes: 25,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Italian',
        description:
            'Roman classic of spaghetti, guanciale, egg, and pecorino — creamy without cream.',
        imageUrl:
            'https://images.unsplash.com/photo-1612874740296-ec2f8b1c4f5e?w=800&q=80',
        tags: const ['dinner', 'italian'],
        steps: const [
          'Boil spaghetti in salted water until al dente; reserve pasta water.',
          'Cook guanciale in a pan until crisp and golden.',
          'Whisk eggs with grated cheese and plenty of black pepper.',
          'Toss hot pasta with guanciale, then off heat fold in the egg mixture; loosen with pasta water.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-carb-1',
            recipeId: 'seed-recipe-carbonara',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Spaghetti', 'Bucatini'],
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
            substitutions: const ['Pecorino', 'Pecorino Romano'],
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
            substitutions: const ['Pancetta', 'Bacon'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-grilled-cheese',
        title: 'Grilled cheese sandwich',
        prepTimeMinutes: 12,
        servings: 1,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'American',
        description:
            'A quick toasted cheese sandwich — simple comfort food for busy days.',
        imageUrl:
            'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=800&q=80',
        tags: const ['lunch', 'quick', 'american'],
        steps: const [
          'Butter the outer sides of two bread slices.',
          'Add cheese between the slices.',
          'Toast in a pan over medium heat until golden and the cheese melts.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-gc-1',
            recipeId: 'seed-recipe-grilled-cheese',
            name: 'Bread',
            quantity: Quantity(2, MeasurementUnit.pieces),
            substitutions: const ['Sourdough', 'White bread'],
          ),
          ing(
            id: 'seed-ing-gc-2',
            recipeId: 'seed-recipe-grilled-cheese',
            name: 'Cheese',
            quantity: Quantity(2, MeasurementUnit.pieces),
            substitutions: const ['Cheddar', 'Mozzarella'],
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
        cuisine: 'International',
        description:
            'Pan-seared chicken served over fluffy rice — an easy weeknight plate.',
        imageUrl:
            'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800&q=80',
        tags: const ['dinner', 'protein'],
        steps: const [
          'Season chicken and pan-sear until cooked through.',
          'Cook rice according to package directions.',
          'Serve chicken over rice; add sautéed onion or vegetables if available.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-cr-1',
            recipeId: 'seed-recipe-chicken-rice',
            name: 'Chicken',
            quantity: Quantity(300, MeasurementUnit.grams),
            substitutions: const ['Chicken breast', 'Chicken thighs'],
          ),
          ing(
            id: 'seed-ing-cr-2',
            recipeId: 'seed-recipe-chicken-rice',
            name: 'Rice',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Jasmine rice', 'Basmati rice'],
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
        cuisine: 'French',
        description:
            'A soft folded omelette filled with melted cheese — classic and fast.',
        imageUrl:
            'https://images.unsplash.com/photo-1612929632978-63a21c4b9f7a?w=800&q=80',
        tags: const ['breakfast', 'quick', 'vegetarian'],
        steps: const [
          'Beat eggs with a splash of milk and a pinch of salt.',
          'Cook in a buttered pan until nearly set, add cheese, then fold.',
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
            substitutions: const ['Cheddar', 'Gruyère', 'Mozzarella'],
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
        cuisine: 'Italian',
        description:
            'Crisp toasted bread rubbed with garlic butter — a simple Italian side.',
        imageUrl:
            'https://images.unsplash.com/photo-1573140401552-3fab57c0c527?w=800&q=80',
        tags: const ['side', 'quick', 'italian'],
        steps: const [
          'Mix softened butter with minced garlic.',
          'Spread on bread and toast until golden and fragrant.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-gt-1',
            recipeId: 'seed-recipe-garlic-toast',
            name: 'Bread',
            quantity: Quantity(4, MeasurementUnit.pieces),
            substitutions: const ['Baguette', 'Ciabatta'],
          ),
          ing(
            id: 'seed-ing-gt-2',
            recipeId: 'seed-recipe-garlic-toast',
            name: 'Butter',
            quantity: Quantity(20, MeasurementUnit.grams),
            substitutions: const ['Olive oil'],
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
        cuisine: 'Mediterranean',
        description: 'Cool yogurt topped with berries — no cooking required.',
        imageUrl:
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800&q=80',
        tags: const ['breakfast', 'quick', 'vegetarian', 'mediterranean'],
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
            substitutions: const ['Greek yogurt'],
          ),
          ing(
            id: 'seed-ing-yb-2',
            recipeId: 'seed-recipe-yogurt-bowl',
            name: 'Berries',
            quantity: Quantity(80, MeasurementUnit.grams),
            substitutions: const [
              'Strawberries',
              'Blueberries',
              'Frozen berries',
            ],
          ),
        ],
      ),

      // --- Italian ---
      recipe(
        id: 'seed-recipe-risotto-milanese',
        title: 'Risotto alla Milanese',
        prepTimeMinutes: 40,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Italian',
        description:
            'Creamy saffron risotto from Milan — rich, golden, and comforting.',
        imageUrl:
            'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=800&q=80',
        tags: const ['dinner', 'italian', 'vegetarian'],
        steps: const [
          'Warm stock in a saucepan; steep a pinch of saffron in a ladle of hot stock.',
          'Sauté onion in butter and olive oil, then toast the rice until translucent.',
          'Add hot stock ladle by ladle, stirring, until the rice is creamy and al dente.',
          'Finish with saffron stock, butter, and Parmesan.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-riso-1',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Arborio rice',
            quantity: Quantity(180, MeasurementUnit.grams),
            substitutions: const ['Carnaroli rice', 'Risotto rice'],
          ),
          ing(
            id: 'seed-ing-riso-2',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Vegetable stock',
            quantity: Quantity(700, MeasurementUnit.milliliters),
            substitutions: const ['Chicken stock', 'Broth'],
          ),
          ing(
            id: 'seed-ing-riso-3',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Onion',
            quantity: Quantity(1, MeasurementUnit.pieces),
            substitutions: const ['Shallot'],
          ),
          ing(
            id: 'seed-ing-riso-4',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Parmesan',
            quantity: Quantity(40, MeasurementUnit.grams),
            substitutions: const ['Grana Padano'],
          ),
          ing(
            id: 'seed-ing-riso-5',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Butter',
            quantity: Quantity(30, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-riso-6',
            recipeId: 'seed-recipe-risotto-milanese',
            name: 'Saffron',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-puttanesca',
        title: 'Pasta puttanesca',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Italian',
        description:
            'Bold Neapolitan sauce of tomatoes, olives, capers, and anchovies.',
        imageUrl:
            'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=800&q=80',
        tags: const ['dinner', 'italian'],
        steps: const [
          'Boil pasta until al dente.',
          'Sauté garlic in olive oil; add anchovies until they melt.',
          'Stir in tomatoes, olives, and capers; simmer briefly.',
          'Toss with pasta and finish with parsley if available.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-putt-1',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Spaghetti', 'Linguine'],
          ),
          ing(
            id: 'seed-ing-putt-2',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Canned tomatoes'],
          ),
          ing(
            id: 'seed-ing-putt-3',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Olives',
            quantity: Quantity(60, MeasurementUnit.grams),
            substitutions: const ['Kalamata olives', 'Black olives'],
          ),
          ing(
            id: 'seed-ing-putt-4',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Capers',
            quantity: Quantity(20, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-putt-5',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Anchovies',
            quantity: Quantity(4, MeasurementUnit.pieces),
            optional: true,
            substitutions: const ['Anchovy paste'],
          ),
          ing(
            id: 'seed-ing-putt-6',
            recipeId: 'seed-recipe-puttanesca',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-minestrone',
        title: 'Minestrone',
        prepTimeMinutes: 45,
        servings: 4,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Italian',
        description:
            'Hearty Italian vegetable soup with beans and a little pasta.',
        imageUrl:
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
        tags: const ['dinner', 'italian', 'vegetarian', 'soup'],
        steps: const [
          'Sauté onion, carrot, and celery in olive oil until soft.',
          'Add tomatoes, stock, beans, and chopped vegetables; simmer 20 minutes.',
          'Add small pasta and cook until tender; season and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-mine-1',
            recipeId: 'seed-recipe-minestrone',
            name: 'Onion',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-mine-2',
            recipeId: 'seed-recipe-minestrone',
            name: 'Carrot',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-mine-3',
            recipeId: 'seed-recipe-minestrone',
            name: 'Celery',
            quantity: Quantity(2, MeasurementUnit.pieces),
            substitutions: const ['Fennel'],
          ),
          ing(
            id: 'seed-ing-mine-4',
            recipeId: 'seed-recipe-minestrone',
            name: 'Canned tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Tomatoes'],
          ),
          ing(
            id: 'seed-ing-mine-5',
            recipeId: 'seed-recipe-minestrone',
            name: 'Cannellini beans',
            quantity: Quantity(240, MeasurementUnit.grams),
            substitutions: const ['Borlotti beans', 'Chickpeas'],
          ),
          ing(
            id: 'seed-ing-mine-6',
            recipeId: 'seed-recipe-minestrone',
            name: 'Pasta',
            quantity: Quantity(80, MeasurementUnit.grams),
            substitutions: const ['Ditalini', 'Small pasta'],
          ),
          ing(
            id: 'seed-ing-mine-7',
            recipeId: 'seed-recipe-minestrone',
            name: 'Vegetable stock',
            quantity: Quantity(1, MeasurementUnit.liters),
            substitutions: const ['Water', 'Broth'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-caprese',
        title: 'Caprese salad',
        prepTimeMinutes: 10,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Italian',
        description:
            'Ripe tomatoes, fresh mozzarella, and basil with olive oil — summer on a plate.',
        imageUrl:
            'https://images.unsplash.com/photo-1608897013039-887f21d8c804?w=800&q=80',
        tags: const ['lunch', 'italian', 'vegetarian', 'quick'],
        steps: const [
          'Slice tomatoes and mozzarella into rounds.',
          'Arrange alternating slices with fresh basil leaves.',
          'Drizzle with olive oil, season with salt, and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-capr-1',
            recipeId: 'seed-recipe-caprese',
            name: 'Tomatoes',
            quantity: Quantity(3, MeasurementUnit.pieces),
            substitutions: const ['Heirloom tomatoes'],
          ),
          ing(
            id: 'seed-ing-capr-2',
            recipeId: 'seed-recipe-caprese',
            name: 'Mozzarella',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Fresh mozzarella', 'Bufala mozzarella'],
          ),
          ing(
            id: 'seed-ing-capr-3',
            recipeId: 'seed-recipe-caprese',
            name: 'Basil',
            quantity: Quantity(10, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-capr-4',
            recipeId: 'seed-recipe-caprese',
            name: 'Olive oil',
            quantity: Quantity(20, MeasurementUnit.milliliters),
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-pesto-pasta',
        title: 'Pesto pasta',
        prepTimeMinutes: 20,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Italian',
        description:
            'Pasta coated in vibrant basil pesto with a splash of pasta water.',
        imageUrl:
            'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=800&q=80',
        tags: const ['dinner', 'italian', 'vegetarian'],
        steps: const [
          'Boil pasta until al dente; reserve pasta water.',
          'Toss hot pasta with pesto, loosening with pasta water.',
          'Finish with grated Parmesan and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-pesto-1',
            recipeId: 'seed-recipe-pesto-pasta',
            name: 'Pasta',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Trofie', 'Linguine', 'Spaghetti'],
          ),
          ing(
            id: 'seed-ing-pesto-2',
            recipeId: 'seed-recipe-pesto-pasta',
            name: 'Basil pesto',
            quantity: Quantity(80, MeasurementUnit.grams),
            substitutions: const ['Pesto', 'Homemade pesto'],
          ),
          ing(
            id: 'seed-ing-pesto-3',
            recipeId: 'seed-recipe-pesto-pasta',
            name: 'Parmesan',
            quantity: Quantity(30, MeasurementUnit.grams),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-margherita-pizza',
        title: 'Homemade margherita pizza',
        prepTimeMinutes: 35,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Italian',
        description:
            'Thin home pizza with tomato, mozzarella, and basil — oven-baked until bubbly.',
        imageUrl:
            'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80',
        tags: const ['dinner', 'italian', 'vegetarian'],
        steps: const [
          'Preheat oven as hot as it goes (ideally 250°C / 480°F).',
          'Stretch dough, spread a thin layer of tomato sauce, and top with mozzarella.',
          'Bake until the crust is golden and cheese is melted.',
          'Finish with fresh basil and a drizzle of olive oil.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-marg-1',
            recipeId: 'seed-recipe-margherita-pizza',
            name: 'Pizza dough',
            quantity: Quantity(300, MeasurementUnit.grams),
            substitutions: const ['Flatbread', 'Store-bought dough'],
          ),
          ing(
            id: 'seed-ing-marg-2',
            recipeId: 'seed-recipe-margherita-pizza',
            name: 'Tomato sauce',
            quantity: Quantity(120, MeasurementUnit.grams),
            substitutions: const ['Tomato passata', 'Crushed tomatoes'],
          ),
          ing(
            id: 'seed-ing-marg-3',
            recipeId: 'seed-recipe-margherita-pizza',
            name: 'Mozzarella',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Fresh mozzarella'],
          ),
          ing(
            id: 'seed-ing-marg-4',
            recipeId: 'seed-recipe-margherita-pizza',
            name: 'Basil',
            optional: true,
          ),
          ing(
            id: 'seed-ing-marg-5',
            recipeId: 'seed-recipe-margherita-pizza',
            name: 'Olive oil',
            optional: true,
          ),
        ],
      ),

      // --- Japanese ---
      recipe(
        id: 'seed-recipe-miso-soup',
        title: 'Miso soup',
        prepTimeMinutes: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Japanese',
        description:
            'Light Japanese soup with miso, tofu, and seaweed — soothing and quick.',
        imageUrl:
            'https://images.unsplash.com/photo-1606491956689-2ea866880067?w=800&q=80',
        tags: const ['soup', 'japanese', 'vegetarian', 'quick'],
        steps: const [
          'Bring dashi or water to a gentle simmer; add tofu and wakame.',
          'Turn off heat and whisk in miso until dissolved — do not boil.',
          'Serve immediately, optionally with sliced spring onion.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-miso-1',
            recipeId: 'seed-recipe-miso-soup',
            name: 'Miso paste',
            quantity: Quantity(30, MeasurementUnit.grams),
            substitutions: const ['White miso', 'Red miso'],
          ),
          ing(
            id: 'seed-ing-miso-2',
            recipeId: 'seed-recipe-miso-soup',
            name: 'Tofu',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Silken tofu', 'Firm tofu'],
          ),
          ing(
            id: 'seed-ing-miso-3',
            recipeId: 'seed-recipe-miso-soup',
            name: 'Wakame',
            quantity: Quantity(5, MeasurementUnit.grams),
            optional: true,
            substitutions: const ['Nori', 'Dried seaweed'],
          ),
          ing(
            id: 'seed-ing-miso-4',
            recipeId: 'seed-recipe-miso-soup',
            name: 'Dashi',
            quantity: Quantity(500, MeasurementUnit.milliliters),
            substitutions: const ['Vegetable stock', 'Water'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-teriyaki-chicken',
        title: 'Teriyaki chicken',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Japanese',
        description:
            'Pan-glazed chicken in a sweet-savory soy glaze, served with rice.',
        imageUrl:
            'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&q=80',
        tags: const ['dinner', 'japanese'],
        steps: const [
          'Pat chicken dry and pan-sear until nearly cooked through.',
          'Mix soy sauce, mirin, and a little sugar; pour over chicken.',
          'Simmer until the sauce thickens into a glossy glaze.',
          'Serve over rice with sesame seeds if available.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-teri-1',
            recipeId: 'seed-recipe-teriyaki-chicken',
            name: 'Chicken',
            quantity: Quantity(350, MeasurementUnit.grams),
            substitutions: const ['Chicken thighs', 'Chicken breast'],
          ),
          ing(
            id: 'seed-ing-teri-2',
            recipeId: 'seed-recipe-teriyaki-chicken',
            name: 'Soy sauce',
            quantity: Quantity(40, MeasurementUnit.milliliters),
            substitutions: const ['Tamari'],
          ),
          ing(
            id: 'seed-ing-teri-3',
            recipeId: 'seed-recipe-teriyaki-chicken',
            name: 'Mirin',
            quantity: Quantity(30, MeasurementUnit.milliliters),
            substitutions: const ['Rice wine', 'Honey'],
          ),
          ing(
            id: 'seed-ing-teri-4',
            recipeId: 'seed-recipe-teriyaki-chicken',
            name: 'Rice',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Jasmine rice', 'Sushi rice'],
          ),
          ing(
            id: 'seed-ing-teri-5',
            recipeId: 'seed-recipe-teriyaki-chicken',
            name: 'Sugar',
            quantity: Quantity(10, MeasurementUnit.grams),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-sushi-bowl',
        title: 'Vegetable sushi bowl',
        prepTimeMinutes: 25,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Japanese',
        description:
            'Chirashi-style bowl of seasoned rice topped with avocado, cucumber, and nori.',
        imageUrl:
            'https://images.unsplash.com/photo-1516684669134-de6f7c473a2a?w=800&q=80',
        tags: const ['lunch', 'japanese', 'vegetarian'],
        steps: const [
          'Cook rice and season lightly with rice vinegar and a pinch of salt.',
          'Slice avocado and cucumber; arrange over the rice.',
          'Top with crumbled nori and a drizzle of soy sauce.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-sushi-1',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Sushi rice',
            quantity: Quantity(180, MeasurementUnit.grams),
            substitutions: const ['Rice', 'Short-grain rice'],
          ),
          ing(
            id: 'seed-ing-sushi-2',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Avocado',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-sushi-3',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Cucumber',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-sushi-4',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Nori',
            quantity: Quantity(1, MeasurementUnit.pieces),
            optional: true,
            substitutions: const ['Seaweed snacks'],
          ),
          ing(
            id: 'seed-ing-sushi-5',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Rice vinegar',
            quantity: Quantity(15, MeasurementUnit.milliliters),
            optional: true,
            substitutions: const ['Apple cider vinegar'],
          ),
          ing(
            id: 'seed-ing-sushi-6',
            recipeId: 'seed-recipe-sushi-bowl',
            name: 'Soy sauce',
            optional: true,
            substitutions: const ['Tamari'],
          ),
        ],
      ),

      // --- Chinese ---
      recipe(
        id: 'seed-recipe-fried-rice',
        title: 'Vegetable fried rice',
        prepTimeMinutes: 20,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Chinese',
        description:
            'Wok-tossed leftover rice with egg, vegetables, and soy sauce.',
        imageUrl:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=800&q=80',
        tags: const ['dinner', 'chinese', 'quick'],
        steps: const [
          'Scramble eggs in a hot wok or pan; set aside.',
          'Stir-fry garlic and mixed vegetables briefly.',
          'Add cold cooked rice, break up clumps, then season with soy sauce.',
          'Return eggs, toss well, and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-frice-1',
            recipeId: 'seed-recipe-fried-rice',
            name: 'Cooked rice',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Rice', 'Day-old rice'],
          ),
          ing(
            id: 'seed-ing-frice-2',
            recipeId: 'seed-recipe-fried-rice',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-frice-3',
            recipeId: 'seed-recipe-fried-rice',
            name: 'Soy sauce',
            quantity: Quantity(25, MeasurementUnit.milliliters),
            substitutions: const ['Tamari'],
          ),
          ing(
            id: 'seed-ing-frice-4',
            recipeId: 'seed-recipe-fried-rice',
            name: 'Mixed vegetables',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Peas', 'Carrot', 'Corn'],
          ),
          ing(
            id: 'seed-ing-frice-5',
            recipeId: 'seed-recipe-fried-rice',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-mapo-tofu',
        title: 'Mapo tofu (simplified)',
        prepTimeMinutes: 25,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Chinese',
        description:
            'Soft tofu in a spicy, savory Sichuan-inspired sauce — simplified for home kitchens.',
        imageUrl:
            'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800&q=80',
        tags: const ['dinner', 'chinese', 'spicy'],
        steps: const [
          'Brown a little minced meat or mushrooms in oil with garlic and ginger.',
          'Add chili bean paste and a splash of stock; simmer briefly.',
          'Gently add cubed tofu and simmer until heated through.',
          'Thicken slightly with cornstarch slurry and finish with spring onion.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-mapo-1',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Tofu',
            quantity: Quantity(300, MeasurementUnit.grams),
            substitutions: const ['Soft tofu', 'Silken tofu'],
          ),
          ing(
            id: 'seed-ing-mapo-2',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Minced pork',
            quantity: Quantity(100, MeasurementUnit.grams),
            optional: true,
            substitutions: const ['Minced beef', 'Mushrooms'],
          ),
          ing(
            id: 'seed-ing-mapo-3',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Chili bean paste',
            quantity: Quantity(20, MeasurementUnit.grams),
            substitutions: const ['Doubanjiang', 'Chili paste'],
          ),
          ing(
            id: 'seed-ing-mapo-4',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Soy sauce',
            quantity: Quantity(15, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-mapo-5',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-mapo-6',
            recipeId: 'seed-recipe-mapo-tofu',
            name: 'Ginger',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-stir-fried-greens',
        title: 'Stir-fried greens',
        prepTimeMinutes: 12,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Chinese',
        description:
            'Quick garlic greens from a hot wok — a classic Chinese vegetable side.',
        imageUrl:
            'https://images.unsplash.com/photo-1607305387299-a3d9611cd469?w=800&q=80',
        tags: const ['side', 'chinese', 'vegetarian', 'quick'],
        steps: const [
          'Heat oil in a wok until shimmering; add garlic briefly.',
          'Add greens and stir-fry until just wilted and bright.',
          'Season with salt or a splash of soy sauce and serve.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-greens-1',
            recipeId: 'seed-recipe-stir-fried-greens',
            name: 'Bok choy',
            quantity: Quantity(300, MeasurementUnit.grams),
            substitutions: const ['Pak choi', 'Spinach', 'Chinese broccoli'],
          ),
          ing(
            id: 'seed-ing-greens-2',
            recipeId: 'seed-recipe-stir-fried-greens',
            name: 'Garlic',
            quantity: Quantity(3, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-greens-3',
            recipeId: 'seed-recipe-stir-fried-greens',
            name: 'Vegetable oil',
            quantity: Quantity(15, MeasurementUnit.milliliters),
            substitutions: const ['Neutral oil', 'Sesame oil'],
          ),
          ing(
            id: 'seed-ing-greens-4',
            recipeId: 'seed-recipe-stir-fried-greens',
            name: 'Soy sauce',
            optional: true,
          ),
        ],
      ),

      // --- Korean ---
      recipe(
        id: 'seed-recipe-kimchi-fried-rice',
        title: 'Kimchi fried rice',
        prepTimeMinutes: 20,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Korean',
        description:
            'Spicy kimchi stir-fried with rice — punchy, fast Korean comfort food.',
        imageUrl:
            'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=800&q=80',
        tags: const ['dinner', 'korean', 'spicy', 'quick'],
        steps: const [
          'Chop kimchi and sauté in a little oil until fragrant.',
          'Add cooked rice and kimchi juice; stir-fry until hot.',
          'Season with gochujang and soy sauce; top with a fried egg if desired.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-kfr-1',
            recipeId: 'seed-recipe-kimchi-fried-rice',
            name: 'Kimchi',
            quantity: Quantity(150, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-kfr-2',
            recipeId: 'seed-recipe-kimchi-fried-rice',
            name: 'Cooked rice',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Rice'],
          ),
          ing(
            id: 'seed-ing-kfr-3',
            recipeId: 'seed-recipe-kimchi-fried-rice',
            name: 'Gochujang',
            quantity: Quantity(15, MeasurementUnit.grams),
            optional: true,
            substitutions: const ['Chili paste'],
          ),
          ing(
            id: 'seed-ing-kfr-4',
            recipeId: 'seed-recipe-kimchi-fried-rice',
            name: 'Soy sauce',
            quantity: Quantity(15, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-kfr-5',
            recipeId: 'seed-recipe-kimchi-fried-rice',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-bibimbap',
        title: 'Bibimbap (simplified)',
        prepTimeMinutes: 35,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Korean',
        description:
            'Rice bowl with assorted vegetables, egg, and gochujang — mix before eating.',
        imageUrl:
            'https://images.unsplash.com/photo-1553163147-622ab57be1c7?w=800&q=80',
        tags: const ['dinner', 'korean', 'vegetarian'],
        steps: const [
          'Cook rice and prepare a few quick-sautéed or raw vegetable toppings.',
          'Arrange vegetables over rice in sections; add a fried or soft egg.',
          'Serve with gochujang and sesame oil; mix everything together at the table.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-bibi-1',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Rice',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Short-grain rice'],
          ),
          ing(
            id: 'seed-ing-bibi-2',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Spinach',
            quantity: Quantity(100, MeasurementUnit.grams),
            substitutions: const ['Mixed greens'],
          ),
          ing(
            id: 'seed-ing-bibi-3',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Carrot',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-bibi-4',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-bibi-5',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Gochujang',
            quantity: Quantity(20, MeasurementUnit.grams),
            substitutions: const ['Chili paste'],
          ),
          ing(
            id: 'seed-ing-bibi-6',
            recipeId: 'seed-recipe-bibimbap',
            name: 'Sesame oil',
            optional: true,
          ),
        ],
      ),

      // --- Thai ---
      recipe(
        id: 'seed-recipe-green-curry',
        title: 'Thai green curry (simplified)',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Thai',
        description:
            'Coconut curry with green paste and vegetables — fragrant and weeknight-friendly.',
        imageUrl:
            'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800&q=80',
        tags: const ['dinner', 'thai', 'spicy'],
        steps: const [
          'Fry green curry paste in a little oil until aromatic.',
          'Add coconut milk and simmer; stir in vegetables (and protein if using).',
          'Season with fish sauce or soy sauce and a pinch of sugar.',
          'Serve with jasmine rice.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-gcurry-1',
            recipeId: 'seed-recipe-green-curry',
            name: 'Green curry paste',
            quantity: Quantity(40, MeasurementUnit.grams),
            substitutions: const ['Thai curry paste'],
          ),
          ing(
            id: 'seed-ing-gcurry-2',
            recipeId: 'seed-recipe-green-curry',
            name: 'Coconut milk',
            quantity: Quantity(400, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-gcurry-3',
            recipeId: 'seed-recipe-green-curry',
            name: 'Mixed vegetables',
            quantity: Quantity(250, MeasurementUnit.grams),
            substitutions: const ['Zucchini', 'Bell pepper', 'Eggplant'],
          ),
          ing(
            id: 'seed-ing-gcurry-4',
            recipeId: 'seed-recipe-green-curry',
            name: 'Chicken',
            quantity: Quantity(250, MeasurementUnit.grams),
            optional: true,
            substitutions: const ['Tofu', 'Shrimp'],
          ),
          ing(
            id: 'seed-ing-gcurry-5',
            recipeId: 'seed-recipe-green-curry',
            name: 'Jasmine rice',
            quantity: Quantity(150, MeasurementUnit.grams),
            substitutions: const ['Rice'],
          ),
          ing(
            id: 'seed-ing-gcurry-6',
            recipeId: 'seed-recipe-green-curry',
            name: 'Fish sauce',
            optional: true,
            substitutions: const ['Soy sauce'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-pad-thai',
        title: 'Pad Thai (simplified)',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Thai',
        description:
            'Stir-fried rice noodles with tamarind-soy sauce, egg, and peanuts.',
        imageUrl:
            'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800&q=80',
        tags: const ['dinner', 'thai'],
        steps: const [
          'Soak rice noodles until pliable; drain.',
          'Stir-fry garlic, add egg, then noodles and sauce (tamarind, fish sauce, sugar).',
          'Toss with bean sprouts and crushed peanuts; serve with lime.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-pad-1',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Rice noodles',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Pad Thai noodles'],
          ),
          ing(
            id: 'seed-ing-pad-2',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Eggs',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-pad-3',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Bean sprouts',
            quantity: Quantity(100, MeasurementUnit.grams),
            optional: true,
          ),
          ing(
            id: 'seed-ing-pad-4',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Peanuts',
            quantity: Quantity(30, MeasurementUnit.grams),
            substitutions: const ['Crushed peanuts'],
          ),
          ing(
            id: 'seed-ing-pad-5',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Fish sauce',
            quantity: Quantity(20, MeasurementUnit.milliliters),
            substitutions: const ['Soy sauce'],
          ),
          ing(
            id: 'seed-ing-pad-6',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Tamarind paste',
            quantity: Quantity(20, MeasurementUnit.grams),
            optional: true,
            substitutions: const ['Lime juice'],
          ),
          ing(
            id: 'seed-ing-pad-7',
            recipeId: 'seed-recipe-pad-thai',
            name: 'Lime',
            optional: true,
          ),
        ],
      ),

      // --- Vietnamese ---
      recipe(
        id: 'seed-recipe-pho-bowl',
        title: 'Pho-inspired broth bowl',
        prepTimeMinutes: 40,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Vietnamese',
        description:
            'Aromatic star-anise broth over rice noodles with herbs — home-friendly pho vibes.',
        imageUrl:
            'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800&q=80',
        tags: const ['dinner', 'vietnamese', 'soup'],
        steps: const [
          'Simmer stock with onion, ginger, star anise, and a splash of fish sauce.',
          'Cook rice noodles separately; divide into bowls.',
          'Ladle hot broth over noodles; add protein or tofu if available.',
          'Top with herbs, bean sprouts, and lime.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-pho-1',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Rice noodles',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Pho noodles'],
          ),
          ing(
            id: 'seed-ing-pho-2',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Beef stock',
            quantity: Quantity(1, MeasurementUnit.liters),
            substitutions: const ['Chicken stock', 'Vegetable stock'],
          ),
          ing(
            id: 'seed-ing-pho-3',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Onion',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-pho-4',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Ginger',
            quantity: Quantity(20, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-pho-5',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Star anise',
            quantity: Quantity(2, MeasurementUnit.pieces),
            optional: true,
          ),
          ing(
            id: 'seed-ing-pho-6',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Fish sauce',
            quantity: Quantity(20, MeasurementUnit.milliliters),
            substitutions: const ['Soy sauce'],
          ),
          ing(
            id: 'seed-ing-pho-7',
            recipeId: 'seed-recipe-pho-bowl',
            name: 'Fresh herbs',
            optional: true,
            substitutions: const ['Cilantro', 'Thai basil', 'Mint'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-spring-rolls',
        title: 'Fresh spring rolls',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.medium,
        cuisine: 'Vietnamese',
        description:
            'Rice-paper rolls filled with herbs, noodles, and vegetables — light and fresh.',
        imageUrl:
            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=800&q=80',
        tags: const ['lunch', 'vietnamese', 'vegetarian'],
        steps: const [
          'Soak rice paper briefly until soft and pliable.',
          'Fill with rice vermicelli, lettuce, herbs, and sliced vegetables.',
          'Roll tightly and serve with peanut or nuoc cham dipping sauce.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-roll-1',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Rice paper',
            quantity: Quantity(8, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-roll-2',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Rice vermicelli',
            quantity: Quantity(100, MeasurementUnit.grams),
            substitutions: const ['Rice noodles'],
          ),
          ing(
            id: 'seed-ing-roll-3',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Lettuce',
            quantity: Quantity(1, MeasurementUnit.pieces),
            substitutions: const ['Butter lettuce'],
          ),
          ing(
            id: 'seed-ing-roll-4',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Carrot',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-roll-5',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Cucumber',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-roll-6',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Fresh herbs',
            optional: true,
            substitutions: const ['Mint', 'Cilantro'],
          ),
          ing(
            id: 'seed-ing-roll-7',
            recipeId: 'seed-recipe-spring-rolls',
            name: 'Peanut butter',
            optional: true,
            substitutions: const ['Hoisin sauce'],
          ),
        ],
      ),

      // --- Indian ---
      recipe(
        id: 'seed-recipe-dal-tadka',
        title: 'Dal tadka',
        prepTimeMinutes: 35,
        servings: 3,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Indian',
        description:
            'Comforting yellow lentils finished with a sizzling cumin-garlic tadka.',
        imageUrl:
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=800&q=80',
        tags: const ['dinner', 'indian', 'vegetarian'],
        steps: const [
          'Rinse and simmer lentils with turmeric until soft; mash lightly.',
          'In a small pan, heat ghee or oil; fry cumin, garlic, and chili.',
          'Pour the tadka over the dal, stir, and serve with rice or flatbread.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-dal-1',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Red lentils',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Masoor dal', 'Yellow lentils'],
          ),
          ing(
            id: 'seed-ing-dal-2',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Turmeric',
            quantity: Quantity(3, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-dal-3',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Cumin seeds',
            quantity: Quantity(5, MeasurementUnit.grams),
            substitutions: const ['Ground cumin'],
          ),
          ing(
            id: 'seed-ing-dal-4',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Garlic',
            quantity: Quantity(3, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-dal-5',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Ghee',
            quantity: Quantity(15, MeasurementUnit.grams),
            substitutions: const ['Butter', 'Vegetable oil'],
          ),
          ing(
            id: 'seed-ing-dal-6',
            recipeId: 'seed-recipe-dal-tadka',
            name: 'Onion',
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-vegetable-curry',
        title: 'Vegetable curry',
        prepTimeMinutes: 35,
        servings: 3,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Indian',
        description:
            'Mild tomato-onion curry packed with mixed vegetables and warm spices.',
        imageUrl:
            'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&q=80',
        tags: const ['dinner', 'indian', 'vegetarian'],
        steps: const [
          'Sauté onion in oil until golden; add garlic, ginger, and curry spices.',
          'Stir in tomatoes and cook down into a sauce.',
          'Add chopped vegetables and a splash of water; simmer until tender.',
          'Finish with cilantro if available; serve with rice.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-vcur-1',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Onion',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-vcur-2',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Tomatoes',
            quantity: Quantity(3, MeasurementUnit.pieces),
            substitutions: const ['Canned tomatoes'],
          ),
          ing(
            id: 'seed-ing-vcur-3',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Mixed vegetables',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Potato', 'Cauliflower', 'Peas'],
          ),
          ing(
            id: 'seed-ing-vcur-4',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Curry powder',
            quantity: Quantity(15, MeasurementUnit.grams),
            substitutions: const ['Garam masala', 'Curry paste'],
          ),
          ing(
            id: 'seed-ing-vcur-5',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-vcur-6',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Ginger',
            optional: true,
          ),
          ing(
            id: 'seed-ing-vcur-7',
            recipeId: 'seed-recipe-vegetable-curry',
            name: 'Coconut milk',
            quantity: Quantity(100, MeasurementUnit.milliliters),
            optional: true,
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-jeera-rice',
        title: 'Jeera rice',
        prepTimeMinutes: 25,
        servings: 3,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Indian',
        description:
            'Fluffy basmati rice tempered with cumin seeds — the perfect curry side.',
        imageUrl:
            'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=800&q=80',
        tags: const ['side', 'indian', 'vegetarian'],
        steps: const [
          'Rinse basmati rice until the water runs clearer.',
          'Toast cumin seeds in ghee or oil until fragrant.',
          'Add rice and water, cover, and cook until fluffy; rest 5 minutes before fluffing.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-jeera-1',
            recipeId: 'seed-recipe-jeera-rice',
            name: 'Basmati rice',
            quantity: Quantity(200, MeasurementUnit.grams),
            substitutions: const ['Rice'],
          ),
          ing(
            id: 'seed-ing-jeera-2',
            recipeId: 'seed-recipe-jeera-rice',
            name: 'Cumin seeds',
            quantity: Quantity(5, MeasurementUnit.grams),
          ),
          ing(
            id: 'seed-ing-jeera-3',
            recipeId: 'seed-recipe-jeera-rice',
            name: 'Ghee',
            quantity: Quantity(15, MeasurementUnit.grams),
            substitutions: const ['Butter', 'Vegetable oil'],
          ),
          ing(
            id: 'seed-ing-jeera-4',
            recipeId: 'seed-recipe-jeera-rice',
            name: 'Salt',
            optional: true,
          ),
        ],
      ),

      // --- Vegetarian Mediterranean ---
      recipe(
        id: 'seed-recipe-shakshuka',
        title: 'Shakshuka',
        prepTimeMinutes: 30,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Mediterranean',
        description:
            'Eggs poached in a spiced tomato-pepper sauce — North African / Levantine classic.',
        imageUrl:
            'https://images.unsplash.com/photo-1574484284002-952d92456975?w=800&q=80',
        tags: const ['breakfast', 'mediterranean', 'vegetarian'],
        steps: const [
          'Sauté onion and bell pepper in olive oil until soft.',
          'Add garlic, spices, and tomatoes; simmer into a thick sauce.',
          'Make wells, crack in eggs, cover, and cook until whites are set.',
          'Serve with bread for scooping.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-shak-1',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Eggs',
            quantity: Quantity(4, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-shak-2',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Tomatoes',
            quantity: Quantity(400, MeasurementUnit.grams),
            substitutions: const ['Canned tomatoes'],
          ),
          ing(
            id: 'seed-ing-shak-3',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Bell pepper',
            quantity: Quantity(1, MeasurementUnit.pieces),
            substitutions: const ['Red pepper'],
          ),
          ing(
            id: 'seed-ing-shak-4',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Onion',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-shak-5',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Garlic',
            quantity: Quantity(2, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-shak-6',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Cumin',
            optional: true,
            substitutions: const ['Paprika'],
          ),
          ing(
            id: 'seed-ing-shak-7',
            recipeId: 'seed-recipe-shakshuka',
            name: 'Bread',
            optional: true,
            substitutions: const ['Pita', 'Sourdough'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-hummus-plate',
        title: 'Hummus plate',
        prepTimeMinutes: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Mediterranean',
        description:
            'Creamy chickpea hummus with olive oil, vegetables, and warm pita.',
        imageUrl:
            'https://images.unsplash.com/photo-1623428187969-5da2dcea5ebf?w=800&q=80',
        tags: const ['lunch', 'mediterranean', 'vegetarian', 'quick'],
        steps: const [
          'Blend chickpeas with tahini, lemon, garlic, and a splash of water until smooth.',
          'Spread on a plate, drizzle with olive oil, and sprinkle paprika if available.',
          'Serve with pita and raw vegetables.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-hum-1',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Chickpeas',
            quantity: Quantity(240, MeasurementUnit.grams),
            substitutions: const ['Canned chickpeas'],
          ),
          ing(
            id: 'seed-ing-hum-2',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Tahini',
            quantity: Quantity(40, MeasurementUnit.grams),
            substitutions: const ['Sesame paste'],
          ),
          ing(
            id: 'seed-ing-hum-3',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Lemon',
            quantity: Quantity(1, MeasurementUnit.pieces),
            substitutions: const ['Lemon juice'],
          ),
          ing(
            id: 'seed-ing-hum-4',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Garlic',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-hum-5',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Olive oil',
            quantity: Quantity(20, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-hum-6',
            recipeId: 'seed-recipe-hummus-plate',
            name: 'Pita',
            optional: true,
            substitutions: const ['Flatbread', 'Bread'],
          ),
        ],
      ),
      recipe(
        id: 'seed-recipe-greek-salad',
        title: 'Greek salad',
        prepTimeMinutes: 15,
        servings: 2,
        difficulty: RecipeDifficulty.easy,
        cuisine: 'Mediterranean',
        description:
            'Chunky tomatoes, cucumber, olives, and feta with oregano and olive oil.',
        imageUrl:
            'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
        tags: const ['lunch', 'mediterranean', 'vegetarian', 'greek', 'quick'],
        steps: const [
          'Chop tomatoes, cucumber, and onion into bite-size pieces.',
          'Add olives and cubed feta; dress with olive oil and oregano.',
          'Season lightly and serve immediately.',
        ],
        ingredients: [
          ing(
            id: 'seed-ing-greek-1',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Tomatoes',
            quantity: Quantity(3, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-greek-2',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Cucumber',
            quantity: Quantity(1, MeasurementUnit.pieces),
          ),
          ing(
            id: 'seed-ing-greek-3',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Feta',
            quantity: Quantity(100, MeasurementUnit.grams),
            substitutions: const ['Feta cheese'],
          ),
          ing(
            id: 'seed-ing-greek-4',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Olives',
            quantity: Quantity(50, MeasurementUnit.grams),
            substitutions: const ['Kalamata olives'],
          ),
          ing(
            id: 'seed-ing-greek-5',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Red onion',
            quantity: Quantity(0.5, MeasurementUnit.pieces),
            optional: true,
            substitutions: const ['Onion'],
          ),
          ing(
            id: 'seed-ing-greek-6',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Olive oil',
            quantity: Quantity(30, MeasurementUnit.milliliters),
          ),
          ing(
            id: 'seed-ing-greek-7',
            recipeId: 'seed-recipe-greek-salad',
            name: 'Oregano',
            optional: true,
          ),
        ],
      ),
    ];
  }
}
