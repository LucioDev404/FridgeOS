import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Optional ranking preferences (subset of [UserPreferences]).
final class RecipeRankingPreferences {
  const RecipeRankingPreferences({
    this.maxPrepTimeMinutes,
    this.favoriteTags = const <String>[],
    this.blockedTags = const <String>[],
    this.expiringSoonWindowDays = 3,
  });

  final int? maxPrepTimeMinutes;
  final List<String> favoriteTags;
  final List<String> blockedTags;

  /// Days before expiry at which stock counts toward the expiration bonus.
  final int expiringSoonWindowDays;
}

/// A product's available stock for recipe matching.
final class AvailableInventoryItem {
  const AvailableInventoryItem({
    required this.productId,
    required this.amount,
    this.productName,
    this.expirationDate,
  });

  final String productId;
  final double amount;

  /// Optional display name used to match unlinked recipe ingredients.
  final String? productName;
  final DateOnly? expirationDate;
}

/// A recipe with its computed match score and ingredient availability breakdown.
final class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.score,
    required this.missingIngredientNames,
    required this.availableIngredientNames,
    required this.availableCount,
    required this.requiredCount,
    this.expiringAvailableCount = 0,
  });

  final Recipe recipe;
  final double score;
  final List<String> missingIngredientNames;
  final List<String> availableIngredientNames;
  final int availableCount;
  final int requiredCount;
  final int expiringAvailableCount;

  /// Completion ratio in `[0, 1]` (`availableCount / requiredCount`).
  double get completionRatio =>
      requiredCount == 0 ? 1.0 : availableCount / requiredCount;

  /// Completion percentage rounded to the nearest integer (0–100).
  int get completionPercent => (completionRatio * 100).round();

  int get missingCount => missingIngredientNames.length;
}

/// Pure service that ranks recipes by stock coverage against real inventory
/// (amount &gt; 0 only). See FR-REC-2/3 and docs/05-domain-model.md §6.
///
/// Sort order (highest priority first):
/// 1. Highest completion percentage
/// 2. Lowest number of missing required ingredients
/// 3. Most ingredients that are expiring soon
/// 4. Shortest preparation time
final class RecipeRanker {
  const RecipeRanker([this._expirationPolicy = const ExpirationPolicy()]);

  final ExpirationPolicy _expirationPolicy;

  /// Synonym groups so free-text ingredients match common product names.
  static const List<Set<String>> _aliasGroups = [
    {'egg', 'eggs'},
    {'tomato', 'tomatoes', 'passata'},
    {'pasta', 'spaghetti', 'penne', 'noodles', 'macaroni'},
    {'milk', 'whole milk', 'semi skimmed milk', 'skimmed milk'},
    {'olive oil', 'extra virgin olive oil'},
    {'butter'},
    {'lettuce', 'salad leaves', 'romaine', 'iceberg'},
    {'yogurt', 'yoghurt', 'greek yogurt', 'greek yoghurt'},
    {
      'berry',
      'berries',
      'mixed berries',
      'strawberry',
      'strawberries',
      'blueberry',
      'blueberries',
      'raspberry',
      'raspberries',
    },
    {'chicken', 'chicken breast', 'chicken thighs'},
    {'rice', 'basmati', 'jasmine rice'},
    {'onion', 'onions'},
    {'garlic'},
    {'cheese', 'cheddar', 'mozzarella'},
    {'parmesan', 'parmigiano', 'parmesan cheese', 'parmigiano reggiano'},
    {'black pepper', 'pepper', 'ground pepper'},
    {'guanciale', 'pancetta', 'bacon'},
    {'bread', 'toast', 'baguette'},
    {'salt'},
  ];

  /// Ranks [recipes] against [inventory] and [preferences].
  ///
  /// Hard filters (excluded entirely):
  /// * any [RecipeRankingPreferences.blockedTags] present on the recipe;
  /// * [Recipe.prepTimeMinutes] above [RecipeRankingPreferences.maxPrepTimeMinutes]
  ///   when that cap is set;
  /// * recipes with zero available required ingredients when [required] is
  ///   non-empty (must share at least one ingredient with real stock).
  List<RecipeMatch> rank({
    required List<Recipe> recipes,
    required List<AvailableInventoryItem> inventory,
    RecipeRankingPreferences preferences = const RecipeRankingPreferences(),
    DateOnly? today,
  }) {
    final stock = _aggregateStock(inventory);
    final referenceToday = today ?? DateOnly.fromDateTime(DateTime.now());
    final matches = <RecipeMatch>[];

    for (final recipe in recipes) {
      if (recipe.isDeleted) continue;
      if (_hasBlockedTag(recipe, preferences.blockedTags)) continue;

      final maxPrep = preferences.maxPrepTimeMinutes;
      if (maxPrep != null && recipe.prepTimeMinutes > maxPrep) continue;

      final match = _buildMatch(
        recipe: recipe,
        stock: stock,
        preferences: preferences,
        today: referenceToday,
      );
      if (match.requiredCount > 0 && match.availableCount == 0) continue;
      matches.add(match);
    }

    matches.sort(_compareMatches);
    return matches;
  }

  /// Evaluates a single [recipe] without the zero-match hard filter.
  ///
  /// Returns `null` when the recipe is deleted or blocked by preferences.
  /// Useful for recipe detail pages that must still show completion for a
  /// specific recipe id.
  RecipeMatch? evaluate({
    required Recipe recipe,
    required List<AvailableInventoryItem> inventory,
    RecipeRankingPreferences preferences = const RecipeRankingPreferences(),
    DateOnly? today,
  }) {
    if (recipe.isDeleted) return null;
    if (_hasBlockedTag(recipe, preferences.blockedTags)) return null;

    final maxPrep = preferences.maxPrepTimeMinutes;
    if (maxPrep != null && recipe.prepTimeMinutes > maxPrep) return null;

    return _buildMatch(
      recipe: recipe,
      stock: _aggregateStock(inventory),
      preferences: preferences,
      today: today ?? DateOnly.fromDateTime(DateTime.now()),
    );
  }

  RecipeMatch _buildMatch({
    required Recipe recipe,
    required Map<String, _AggregatedStock> stock,
    required RecipeRankingPreferences preferences,
    required DateOnly today,
  }) {
    final required = recipe.requiredIngredients.toList();
    final availability = _availability(
      required: required,
      stock: stock,
      today: today,
      windowDays: preferences.expiringSoonWindowDays,
    );

    return RecipeMatch(
      recipe: recipe,
      score: _score(
        availability: availability,
        recipe: recipe,
        preferences: preferences,
      ),
      missingIngredientNames: availability.missingNames,
      availableIngredientNames: availability.availableNames,
      availableCount: availability.availableCount,
      requiredCount: availability.requiredCount,
      expiringAvailableCount: availability.expiringAvailableCount,
    );
  }

  /// Whether [ingredient] is covered by [inventory] (amount &gt; 0).
  bool isIngredientAvailable(
    RecipeIngredient ingredient,
    List<AvailableInventoryItem> inventory,
  ) {
    return _matchStock(ingredient, _aggregateStock(inventory)) != null;
  }

  int _compareMatches(RecipeMatch a, RecipeMatch b) {
    final byCompletion = b.completionRatio.compareTo(a.completionRatio);
    if (byCompletion != 0) return byCompletion;

    final byMissing = a.missingCount.compareTo(b.missingCount);
    if (byMissing != 0) return byMissing;

    final byExpiring = b.expiringAvailableCount.compareTo(
      a.expiringAvailableCount,
    );
    if (byExpiring != 0) return byExpiring;

    final byPrep = a.recipe.prepTimeMinutes.compareTo(b.recipe.prepTimeMinutes);
    if (byPrep != 0) return byPrep;

    return a.recipe.title.compareTo(b.recipe.title);
  }

  bool _hasBlockedTag(Recipe recipe, List<String> blockedTags) {
    if (blockedTags.isEmpty) return false;
    final blocked = blockedTags.toSet();
    return recipe.tags.any(blocked.contains);
  }

  _IngredientAvailability _availability({
    required List<RecipeIngredient> required,
    required Map<String, _AggregatedStock> stock,
    required DateOnly today,
    required int windowDays,
  }) {
    if (required.isEmpty) {
      return const _IngredientAvailability(
        availableCount: 0,
        requiredCount: 0,
        missingNames: <String>[],
        availableNames: <String>[],
        expiringAvailableCount: 0,
      );
    }

    var availableCount = 0;
    var expiringAvailableCount = 0;
    final missingNames = <String>[];
    final availableNames = <String>[];

    for (final ingredient in required) {
      final matched = _matchStock(ingredient, stock);
      if (matched != null) {
        availableCount++;
        availableNames.add(ingredient.name);
        final status = _expirationPolicy.classify(
          expirationDate: matched.earliestExpiration,
          today: today,
          windowDays: windowDays,
        );
        if (status == ExpirationStatus.expiringSoon) {
          expiringAvailableCount++;
        }
      } else {
        missingNames.add(ingredient.name);
      }
    }

    return _IngredientAvailability(
      availableCount: availableCount,
      requiredCount: required.length,
      missingNames: missingNames,
      availableNames: availableNames,
      expiringAvailableCount: expiringAvailableCount,
    );
  }

  _AggregatedStock? _matchStock(
    RecipeIngredient ingredient,
    Map<String, _AggregatedStock> stock,
  ) {
    final productId = ingredient.productId;
    if (productId != null) {
      final byId = stock[productId];
      if (byId != null && byId.amount > 0) return byId;
    }

    final needle = _normalizeName(ingredient.name);
    if (needle.isEmpty) return null;
    final needleKeys = _matchKeys(needle);
    for (final entry in stock.entries) {
      if (entry.value.amount <= 0) continue;
      final name = entry.value.normalizedName;
      if (name == null || name.isEmpty) continue;
      if (_namesMatch(needleKeys, _matchKeys(name))) {
        return entry.value;
      }
    }
    return null;
  }

  bool _namesMatch(Set<String> a, Set<String> b) {
    for (final key in a) {
      if (b.contains(key)) return true;
    }
    // Substring fallback for compound product names ("free range eggs").
    for (final left in a) {
      for (final right in b) {
        if (left.length >= 3 &&
            right.length >= 3 &&
            (left.contains(right) || right.contains(left))) {
          return true;
        }
      }
    }
    return false;
  }

  Set<String> _matchKeys(String normalized) {
    final keys = <String>{normalized};
    if (normalized.endsWith('ies') && normalized.length > 4) {
      keys.add('${normalized.substring(0, normalized.length - 3)}y');
    } else if (normalized.endsWith('oes') && normalized.length > 4) {
      keys.add(normalized.substring(0, normalized.length - 2));
    } else if (normalized.endsWith('s') &&
        !normalized.endsWith('ss') &&
        normalized.length > 3) {
      keys.add(normalized.substring(0, normalized.length - 1));
    }

    for (final group in _aliasGroups) {
      var hits = false;
      for (final alias in group) {
        if (keys.contains(alias) ||
            normalized == alias ||
            (alias.length >= 4 && normalized.contains(alias)) ||
            (normalized.length >= 4 && alias.contains(normalized))) {
          hits = true;
          break;
        }
      }
      if (hits) keys.addAll(group);
    }
    return keys;
  }

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  double _score({
    required _IngredientAvailability availability,
    required Recipe recipe,
    required RecipeRankingPreferences preferences,
  }) {
    final requiredCount = availability.requiredCount;
    if (requiredCount == 0) return 1.0;

    // Score mirrors the primary ranking axes for display/tests.
    final coverage = availability.availableCount / requiredCount;
    final missingPenalty = availability.missingNames.length / requiredCount;
    final expiringScore = availability.availableCount == 0
        ? 0.0
        : availability.expiringAvailableCount / availability.availableCount;
    final prepCap = preferences.maxPrepTimeMinutes ?? 120;
    final prepScore =
        (prepCap - recipe.prepTimeMinutes).clamp(0, prepCap).toDouble() /
        prepCap;

    final favoriteMatches = recipe.tags
        .where(preferences.favoriteTags.contains)
        .length;
    final preferenceScore = preferences.favoriteTags.isEmpty
        ? 0.0
        : (favoriteMatches * 0.25).clamp(0.0, 1.0).toDouble();

    return (0.45 * coverage) -
        (0.20 * missingPenalty) +
        (0.20 * expiringScore) +
        (0.10 * prepScore) +
        (0.05 * preferenceScore);
  }

  Map<String, _AggregatedStock> _aggregateStock(
    List<AvailableInventoryItem> inventory,
  ) {
    final stock = <String, _AggregatedStock>{};
    for (final item in inventory) {
      if (item.amount <= 0) continue;
      final existing = stock[item.productId];
      if (existing == null) {
        stock[item.productId] = _AggregatedStock(
          amount: item.amount,
          earliestExpiration: item.expirationDate,
          normalizedName: item.productName == null
              ? null
              : _normalizeName(item.productName!),
        );
        continue;
      }
      stock[item.productId] = existing.merge(item);
    }
    return stock;
  }
}

final class _AggregatedStock {
  const _AggregatedStock({
    required this.amount,
    this.earliestExpiration,
    this.normalizedName,
  });

  final double amount;
  final DateOnly? earliestExpiration;
  final String? normalizedName;

  _AggregatedStock merge(AvailableInventoryItem item) {
    DateOnly? earliest = earliestExpiration;
    final expiration = item.expirationDate;
    if (expiration != null &&
        (earliest == null || expiration.isBefore(earliest))) {
      earliest = expiration;
    }
    return _AggregatedStock(
      amount: amount + item.amount,
      earliestExpiration: earliest,
      normalizedName: normalizedName,
    );
  }
}

final class _IngredientAvailability {
  const _IngredientAvailability({
    required this.availableCount,
    required this.requiredCount,
    required this.missingNames,
    required this.availableNames,
    required this.expiringAvailableCount,
  });

  final int availableCount;
  final int requiredCount;
  final List<String> missingNames;
  final List<String> availableNames;
  final int expiringAvailableCount;
}
