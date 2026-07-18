import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/location.dart';
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

final recipesListProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchAll(),
);

final _inventoryItemsForRecipesProvider = StreamProvider(
  (ref) => ref.watch(inventoryRepositoryProvider).watchActiveItems(),
);

final _productsForRecipesProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

/// Live inventory rows with amount &gt; 0, named for recipe matching.
final availableInventoryForRecipesProvider =
    Provider<AsyncValue<List<AvailableInventoryItem>>>((ref) {
      final itemsAsync = ref.watch(_inventoryItemsForRecipesProvider);
      final productsAsync = ref.watch(_productsForRecipesProvider);
      final locationsAsync = ref.watch(locationsProvider);

      if (itemsAsync.isLoading ||
          productsAsync.isLoading ||
          locationsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (itemsAsync.hasError) {
        return AsyncValue.error(itemsAsync.error!, itemsAsync.stackTrace!);
      }
      if (productsAsync.hasError) {
        return AsyncValue.error(
          productsAsync.error!,
          productsAsync.stackTrace!,
        );
      }
      if (locationsAsync.hasError) {
        return AsyncValue.error(
          locationsAsync.error!,
          locationsAsync.stackTrace!,
        );
      }

      final products = {
        for (final product in productsAsync.value ?? const <Product>[])
          product.id: product,
      };
      final locations = {
        for (final location in locationsAsync.value ?? const <Location>[])
          location.id: location,
      };
      final items = itemsAsync.value ?? const [];
      final available = items
          .where((i) => i.isActive && i.quantity.amount > 0)
          .map(
            (i) => AvailableInventoryItem(
              productId: i.productId,
              productName: products[i.productId]?.name,
              locationName: locations[i.locationId]?.name,
              amount: i.quantity.amount,
              expirationDate: i.expirationDate,
            ),
          )
          .toList();
      return AsyncValue.data(available);
    });

/// Ranked recipe matches derived from live recipes and inventory.
final rankedRecipesProvider = Provider<AsyncValue<List<RecipeMatch>>>((ref) {
  final recipesAsync = ref.watch(recipesListProvider);
  final availableAsync = ref.watch(availableInventoryForRecipesProvider);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final today = ref.watch(todayProvider);
  final window = ref.watch(expiringSoonWindowProvider);
  final ranker = ref.watch(recipeRankerProvider);

  if (recipesAsync.isLoading || availableAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (recipesAsync.hasError) {
    return AsyncValue.error(recipesAsync.error!, recipesAsync.stackTrace!);
  }
  if (availableAsync.hasError) {
    return AsyncValue.error(availableAsync.error!, availableAsync.stackTrace!);
  }

  final recipes = recipesAsync.value ?? const <Recipe>[];
  final available = availableAsync.value ?? const <AvailableInventoryItem>[];
  final prefs = prefsAsync.value ?? const UserPreferences();

  final rankingPrefs = RecipeRankingPreferences(
    maxPrepTimeMinutes: prefs.maxPrepTimeMinutes,
    favoriteTags: prefs.favoriteTags,
    blockedTags: prefs.blockedTags,
    expiringSoonWindowDays: window,
    diet: prefs.dietPreference,
  );

  final matches = ranker.rank(
    recipes: recipes,
    inventory: available,
    preferences: rankingPrefs,
    today: today,
  );
  return AsyncValue.data(matches);
});

/// Single recipe match for detail view (includes 0% completion recipes).
final recipeMatchProvider = Provider.family<AsyncValue<RecipeMatch?>, String>((
  ref,
  recipeId,
) {
  final recipesAsync = ref.watch(recipesListProvider);
  final availableAsync = ref.watch(availableInventoryForRecipesProvider);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final today = ref.watch(todayProvider);
  final window = ref.watch(expiringSoonWindowProvider);
  final ranker = ref.watch(recipeRankerProvider);

  if (recipesAsync.isLoading || availableAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (recipesAsync.hasError) {
    return AsyncValue.error(recipesAsync.error!, recipesAsync.stackTrace!);
  }
  if (availableAsync.hasError) {
    return AsyncValue.error(availableAsync.error!, availableAsync.stackTrace!);
  }

  Recipe? recipe;
  for (final r in recipesAsync.value ?? const <Recipe>[]) {
    if (r.id == recipeId) {
      recipe = r;
      break;
    }
  }
  if (recipe == null) return const AsyncValue.data(null);

  final prefs = prefsAsync.value ?? const UserPreferences();
  final match = ranker.evaluate(
    recipe: recipe,
    inventory: availableAsync.value ?? const <AvailableInventoryItem>[],
    preferences: RecipeRankingPreferences(
      maxPrepTimeMinutes: prefs.maxPrepTimeMinutes,
      favoriteTags: prefs.favoriteTags,
      blockedTags: prefs.blockedTags,
      expiringSoonWindowDays: window,
      diet: prefs.dietPreference,
    ),
    today: today,
  );
  return AsyncValue.data(match);
});
