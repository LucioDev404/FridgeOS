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
    this.expirationDate,
  });

  final String productId;
  final double amount;
  final DateOnly? expirationDate;
}

/// A recipe with its computed match score and ingredient availability breakdown.
final class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.score,
    required this.missingIngredientNames,
    required this.availableCount,
    required this.requiredCount,
  });

  final Recipe recipe;
  final double score;
  final List<String> missingIngredientNames;
  final int availableCount;
  final int requiredCount;
}

/// Pure service that ranks recipes by stock coverage, preferences, and expiration
/// urgency (see FR-REC-2/3, docs/05-domain-model.md §6).
final class RecipeRanker {
  const RecipeRanker([this._expirationPolicy = const ExpirationPolicy()]);

  final ExpirationPolicy _expirationPolicy;

  static const _coverageWeight = 0.70;
  static const _favoriteTagWeight = 0.15;
  static const _expiringWeight = 0.15;
  static const _favoriteTagBonusPerMatch = 0.25;

  /// Ranks [recipes] against [inventory] and [preferences].
  ///
  /// Hard filters (excluded entirely):
  /// * any [RecipeRankingPreferences.blockedTags] present on the recipe;
  /// * [Recipe.prepTimeMinutes] above [RecipeRankingPreferences.maxPrepTimeMinutes]
  ///   when that cap is set;
  /// * any required ingredient with a [RecipeIngredient.productId] that is
  ///   completely absent from stock (zero or missing).
  ///
  /// Remaining recipes are scored in `[0, 1]` and sorted by descending score,
  /// then ascending title.
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

      final required = recipe.requiredIngredients.toList();
      if (_hasMissingLinkedIngredient(required, stock)) continue;

      final availability = _availability(
        required: required,
        stock: stock,
        today: referenceToday,
        windowDays: preferences.expiringSoonWindowDays,
      );
      final score = _score(
        availability: availability,
        recipe: recipe,
        preferences: preferences,
      );

      matches.add(
        RecipeMatch(
          recipe: recipe,
          score: score,
          missingIngredientNames: availability.missingNames,
          availableCount: availability.availableCount,
          requiredCount: availability.requiredCount,
        ),
      );
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.recipe.title.compareTo(b.recipe.title);
    });
    return matches;
  }

  bool _hasBlockedTag(Recipe recipe, List<String> blockedTags) {
    if (blockedTags.isEmpty) return false;
    final blocked = blockedTags.toSet();
    return recipe.tags.any(blocked.contains);
  }

  bool _hasMissingLinkedIngredient(
    List<RecipeIngredient> required,
    Map<String, _AggregatedStock> stock,
  ) {
    for (final ingredient in required) {
      final productId = ingredient.productId;
      if (productId == null) continue;
      final amount = stock[productId]?.amount ?? 0;
      if (amount <= 0) return true;
    }
    return false;
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
        expiringAvailableCount: 0,
      );
    }

    var availableCount = 0;
    var expiringAvailableCount = 0;
    final missingNames = <String>[];

    for (final ingredient in required) {
      final productId = ingredient.productId;
      final isAvailable = productId != null
          ? (stock[productId]?.amount ?? 0) > 0
          : false;

      if (isAvailable) {
        availableCount++;
        final aggregated = stock[productId]!;
        final status = _expirationPolicy.classify(
          expirationDate: aggregated.earliestExpiration,
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
      expiringAvailableCount: expiringAvailableCount,
    );
  }

  double _score({
    required _IngredientAvailability availability,
    required Recipe recipe,
    required RecipeRankingPreferences preferences,
  }) {
    final requiredCount = availability.requiredCount;
    if (requiredCount == 0) return 1.0;

    final coverage = availability.availableCount / requiredCount;

    final favoriteMatches = recipe.tags
        .where(preferences.favoriteTags.contains)
        .length;
    final favoriteScore = preferences.favoriteTags.isEmpty
        ? 0.0
        : (favoriteMatches * _favoriteTagBonusPerMatch)
              .clamp(0.0, 1.0)
              .toDouble();

    final expiringScore = availability.availableCount == 0
        ? 0.0
        : availability.expiringAvailableCount / availability.availableCount;

    return (_coverageWeight * coverage) +
        (_favoriteTagWeight * favoriteScore) +
        (_expiringWeight * expiringScore);
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
        );
        continue;
      }
      stock[item.productId] = existing.merge(item);
    }
    return stock;
  }
}

final class _AggregatedStock {
  const _AggregatedStock({required this.amount, this.earliestExpiration});

  final double amount;
  final DateOnly? earliestExpiration;

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
    );
  }
}

final class _IngredientAvailability {
  const _IngredientAvailability({
    required this.availableCount,
    required this.requiredCount,
    required this.missingNames,
    required this.expiringAvailableCount,
  });

  final int availableCount;
  final int requiredCount;
  final List<String> missingNames;
  final int expiringAvailableCount;
}
