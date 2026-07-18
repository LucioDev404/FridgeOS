import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/entities/user_preferences.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/recipes/application/recipe_actions.dart';

final recipeActionsProvider = Provider<RecipeActions>(
  (ref) => RecipeActions(
    recipes: ref.watch(recipeRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    inventory: ref.watch(inventoryRepositoryProvider),
    shopping: ref.watch(shoppingRepositoryProvider),
    inventoryActions: ref.watch(inventoryActionsProvider),
    ranker: ref.watch(recipeRankerProvider),
    sanitizer: ref.watch(inputSanitizerProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final _recipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchAll(),
);

final _inventoryItemsForRecipesProvider = StreamProvider(
  (ref) => ref.watch(inventoryRepositoryProvider).watchActiveItems(),
);

final _productsForRecipesProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

/// Ranked recipe matches derived from live recipes and inventory.
final rankedRecipesProvider = Provider<AsyncValue<List<RecipeMatch>>>((ref) {
  final recipesAsync = ref.watch(_recipesProvider);
  final itemsAsync = ref.watch(_inventoryItemsForRecipesProvider);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final today = ref.watch(todayProvider);
  final window = ref.watch(expiringSoonWindowProvider);
  final ranker = ref.watch(recipeRankerProvider);

  if (recipesAsync.isLoading || itemsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (recipesAsync.hasError) {
    return AsyncValue.error(recipesAsync.error!, recipesAsync.stackTrace!);
  }
  if (itemsAsync.hasError) {
    return AsyncValue.error(itemsAsync.error!, itemsAsync.stackTrace!);
  }

  final recipes = recipesAsync.value ?? const <Recipe>[];
  final items = itemsAsync.value ?? const [];
  final prefs = prefsAsync.value ?? const UserPreferences();

  final rankingPrefs = RecipeRankingPreferences(
    maxPrepTimeMinutes: prefs.maxPrepTimeMinutes,
    favoriteTags: prefs.favoriteTags,
    blockedTags: prefs.blockedTags,
    expiringSoonWindowDays: window,
  );

  final products = {
    for (final product
        in ref.watch(_productsForRecipesProvider).value ?? const <Product>[])
      product.id: product,
  };

  final available = items
      .where((i) => i.isActive && i.quantity.amount > 0)
      .map(
        (i) => AvailableInventoryItem(
          productId: i.productId,
          productName: products[i.productId]?.name,
          amount: i.quantity.amount,
          expirationDate: i.expirationDate,
        ),
      )
      .toList();

  final matches = ranker.rank(
    recipes: recipes,
    inventory: available,
    preferences: rankingPrefs,
    today: today,
  );
  return AsyncValue.data(matches);
});
