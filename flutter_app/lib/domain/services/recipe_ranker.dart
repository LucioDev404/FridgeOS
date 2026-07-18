import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/services/ingredient_lexicon.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/diet_preference.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Optional ranking preferences (subset of [UserPreferences]).
final class RecipeRankingPreferences {
  const RecipeRankingPreferences({
    this.maxPrepTimeMinutes,
    this.favoriteTags = const <String>[],
    this.blockedTags = const <String>[],
    this.expiringSoonWindowDays = 3,
    this.preferredCuisines = const <String>[],
    this.diet = DietPreference.omnivore,
  });

  final int? maxPrepTimeMinutes;
  final List<String> favoriteTags;
  final List<String> blockedTags;
  final int expiringSoonWindowDays;
  final List<String> preferredCuisines;
  final DietPreference diet;
}

/// A product's available stock for recipe matching.
final class AvailableInventoryItem {
  const AvailableInventoryItem({
    required this.productId,
    required this.amount,
    this.productName,
    this.locationName,
    this.expirationDate,
  });

  final String productId;
  final double amount;
  final String? productName;

  /// Storage location label (Fridge / Pantry / …) for UI breakdowns.
  final String? locationName;
  final DateOnly? expirationDate;
}

/// Per-ingredient match detail for UI and scoring.
final class IngredientMatchDetail {
  const IngredientMatchDetail({
    required this.ingredientName,
    required this.kind,
    required this.optional,
    this.matchedProductName,
    this.substitutionUsed,
    this.locations = const <String>[],
  });

  final String ingredientName;
  final IngredientMatchKind kind;
  final bool optional;
  final String? matchedProductName;
  final String? substitutionUsed;
  final List<String> locations;

  bool get countsAsAvailable =>
      kind == IngredientMatchKind.exact ||
      kind == IngredientMatchKind.substitution;
}

/// A recipe with its computed match score and ingredient availability breakdown.
final class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.score,
    required this.ingredientDetails,
    required this.availableCount,
    required this.requiredCount,
    this.expiringAvailableCount = 0,
  });

  final Recipe recipe;
  final double score;
  final List<IngredientMatchDetail> ingredientDetails;
  final int availableCount;
  final int requiredCount;
  final int expiringAvailableCount;

  double get completionRatio =>
      requiredCount == 0 ? 1.0 : availableCount / requiredCount;

  int get completionPercent => (completionRatio * 100).round();

  int get missingCount => missingIngredientNames.length;

  bool get isReadyToCook =>
      requiredCount == 0 || availableCount == requiredCount;

  List<String> get availableIngredientNames => [
    for (final d in ingredientDetails)
      if (!d.optional && d.countsAsAvailable) d.ingredientName,
  ];

  List<String> get missingIngredientNames => [
    for (final d in ingredientDetails)
      if (!d.optional &&
          (d.kind == IngredientMatchKind.missing ||
              d.kind == IngredientMatchKind.partial))
        d.ingredientName,
  ];

  List<String> get optionalIngredientNames => [
    for (final d in ingredientDetails)
      if (d.optional) d.ingredientName,
  ];

  List<String> get partialIngredientNames => [
    for (final d in ingredientDetails)
      if (!d.optional && d.kind == IngredientMatchKind.partial)
        d.ingredientName,
  ];

  List<String> get substitutionNotes => [
    for (final d in ingredientDetails)
      if (d.kind == IngredientMatchKind.substitution &&
          d.substitutionUsed != null)
        '${d.ingredientName} ← ${d.substitutionUsed}',
  ];

  List<String> get suggestedSubstitutions => [
    for (final ingredient in recipe.ingredients)
      if (!ingredient.optional &&
          ingredient.substitutions.isNotEmpty &&
          ingredientDetails.any(
            (d) =>
                d.ingredientName == ingredient.name &&
                d.kind == IngredientMatchKind.missing,
          ))
        '${ingredient.name}: ${ingredient.substitutions.join(", ")}',
  ];
}

/// Ranks recipes against real inventory with strict matching rules.
///
/// * **Exact** — productId, multilingual canonical id, or simple plural.
/// * **Substitution** — only names listed on the ingredient.
/// * **Partial** — related forms (tomato vs tomato sauce), never scored as stock.
/// * Optional ingredients never reduce completion.
/// * Diet preference hard-filters incompatible recipes.
final class RecipeRanker {
  const RecipeRanker([
    this._expirationPolicy = const ExpirationPolicy(),
    this._lexicon = const IngredientLexicon(),
    this._dietPolicy = const RecipeDietPolicy(),
  ]);

  final ExpirationPolicy _expirationPolicy;
  final IngredientLexicon _lexicon;
  final RecipeDietPolicy _dietPolicy;

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

      if (!_dietPolicy.isCompatible(
        tags: recipe.tags,
        ingredientNames: recipe.ingredients.map((i) => i.name),
        diet: preferences.diet,
      )) {
        continue;
      }

      final match = _buildMatch(
        recipe: recipe,
        stock: stock,
        preferences: preferences,
        today: referenceToday,
      );
      if (!_isRelevant(match)) continue;
      matches.add(match);
    }

    matches.sort(_compareMatches);
    return _diversifyCuisines(matches);
  }

  /// Drops weak single-ingredient hits on large recipes.
  bool _isRelevant(RecipeMatch match) {
    if (match.availableCount == 0) return false;
    if (match.requiredCount <= 2) return true;
    return match.availableCount >= 2 || match.completionRatio >= 0.5;
  }

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

    if (!_dietPolicy.isCompatible(
      tags: recipe.tags,
      ingredientNames: recipe.ingredients.map((i) => i.name),
      diet: preferences.diet,
    )) {
      return null;
    }

    return _buildMatch(
      recipe: recipe,
      stock: _aggregateStock(inventory),
      preferences: preferences,
      today: today ?? DateOnly.fromDateTime(DateTime.now()),
    );
  }

  bool isIngredientAvailable(
    RecipeIngredient ingredient,
    List<AvailableInventoryItem> inventory,
  ) {
    final detail = _matchIngredient(ingredient, _aggregateStock(inventory));
    return detail.countsAsAvailable;
  }

  /// Priority: availability → expiry → fewer missing → score (cuisine/prefs) → title.
  /// Diet is applied as a hard filter before ranking.
  int _compareMatches(RecipeMatch a, RecipeMatch b) {
    final byCompletion = b.completionRatio.compareTo(a.completionRatio);
    if (byCompletion != 0) return byCompletion;

    final byExpiring = b.expiringAvailableCount.compareTo(
      a.expiringAvailableCount,
    );
    if (byExpiring != 0) return byExpiring;

    final byMissing = a.missingCount.compareTo(b.missingCount);
    if (byMissing != 0) return byMissing;

    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;

    final byPrep = a.recipe.prepTimeMinutes.compareTo(b.recipe.prepTimeMinutes);
    if (byPrep != 0) return byPrep;

    return a.recipe.title.compareTo(b.recipe.title);
  }

  /// Soft cuisine variety: within the same completion band, avoid long runs
  /// of a single cuisine so browsing feels more like a curated feed.
  List<RecipeMatch> _diversifyCuisines(List<RecipeMatch> ranked) {
    if (ranked.length < 3) return ranked;

    final remaining = List<RecipeMatch>.of(ranked);
    final result = <RecipeMatch>[];
    String? lastCuisine;

    while (remaining.isNotEmpty) {
      final index = remaining.indexWhere((m) {
        final cuisine = m.recipe.cuisine?.toLowerCase();
        if (cuisine == null || cuisine.isEmpty) return true;
        if (lastCuisine == null) return true;
        if (cuisine == lastCuisine) return false;
        // Only swap within a close completion band.
        final head = remaining.first;
        return (head.completionRatio - m.completionRatio).abs() <= 0.15;
      });
      final pick = index >= 0
          ? remaining.removeAt(index)
          : remaining.removeAt(0);
      result.add(pick);
      lastCuisine = pick.recipe.cuisine?.toLowerCase();
    }
    return result;
  }

  bool _hasBlockedTag(Recipe recipe, List<String> blockedTags) {
    if (blockedTags.isEmpty) return false;
    final blocked = blockedTags.toSet();
    return recipe.tags.any(blocked.contains);
  }

  RecipeMatch _buildMatch({
    required Recipe recipe,
    required Map<String, _AggregatedStock> stock,
    required RecipeRankingPreferences preferences,
    required DateOnly today,
  }) {
    final details = <IngredientMatchDetail>[];
    var availableCount = 0;
    var requiredCount = 0;
    var expiringAvailableCount = 0;

    for (final ingredient in recipe.ingredients) {
      final detail = _matchIngredient(ingredient, stock);
      details.add(detail);
      if (ingredient.optional) continue;
      requiredCount++;
      if (detail.countsAsAvailable) {
        availableCount++;
        final matched = _findStockForDetail(detail, stock);
        if (matched != null) {
          final status = _expirationPolicy.classify(
            expirationDate: matched.earliestExpiration,
            today: today,
            windowDays: preferences.expiringSoonWindowDays,
          );
          if (status == ExpirationStatus.expiringSoon) {
            expiringAvailableCount++;
          }
        }
      }
    }

    final availability = _IngredientAvailability(
      availableCount: availableCount,
      requiredCount: requiredCount,
      expiringAvailableCount: expiringAvailableCount,
    );

    return RecipeMatch(
      recipe: recipe,
      score: _score(
        availability: availability,
        recipe: recipe,
        preferences: preferences,
        missingCount: requiredCount - availableCount,
      ),
      ingredientDetails: details,
      availableCount: availableCount,
      requiredCount: requiredCount,
      expiringAvailableCount: expiringAvailableCount,
    );
  }

  IngredientMatchDetail _matchIngredient(
    RecipeIngredient ingredient,
    Map<String, _AggregatedStock> stock,
  ) {
    final productId = ingredient.productId;
    if (productId != null) {
      final byId = stock[productId];
      if (byId != null && byId.amount > 0) {
        return IngredientMatchDetail(
          ingredientName: ingredient.name,
          kind: IngredientMatchKind.exact,
          optional: ingredient.optional,
          matchedProductName: byId.displayName ?? byId.normalizedName,
          locations: byId.locations,
        );
      }
    }

    final ingredientLabel = ingredient.name.trim();
    if (ingredientLabel.isEmpty) {
      return IngredientMatchDetail(
        ingredientName: ingredient.name,
        kind: IngredientMatchKind.missing,
        optional: ingredient.optional,
      );
    }

    // Exact via multilingual lexicon / plurals.
    for (final entry in stock.entries) {
      if (entry.value.amount <= 0) continue;
      final productLabel =
          entry.value.displayName ?? entry.value.normalizedName;
      if (productLabel == null || productLabel.isEmpty) continue;
      if (_lexicon.isExactMatch(ingredientLabel, productLabel)) {
        return IngredientMatchDetail(
          ingredientName: ingredient.name,
          kind: IngredientMatchKind.exact,
          optional: ingredient.optional,
          matchedProductName: entry.value.displayName ?? productLabel,
          locations: entry.value.locations,
        );
      }
    }

    // Explicit substitutions (also multilingual).
    for (final sub in ingredient.substitutions) {
      if (sub.trim().isEmpty) continue;
      for (final entry in stock.entries) {
        if (entry.value.amount <= 0) continue;
        final productLabel =
            entry.value.displayName ?? entry.value.normalizedName;
        if (productLabel == null) continue;
        if (_lexicon.isExactMatch(sub, productLabel)) {
          return IngredientMatchDetail(
            ingredientName: ingredient.name,
            kind: IngredientMatchKind.substitution,
            optional: ingredient.optional,
            matchedProductName: entry.value.displayName ?? productLabel,
            substitutionUsed: sub,
            locations: entry.value.locations,
          );
        }
      }
    }

    // Partial: related forms only (tomato ↔ tomato sauce), never stock.
    for (final entry in stock.entries) {
      if (entry.value.amount <= 0) continue;
      final productLabel =
          entry.value.displayName ?? entry.value.normalizedName;
      if (productLabel == null) continue;
      if (_lexicon.isRelated(ingredientLabel, productLabel)) {
        return IngredientMatchDetail(
          ingredientName: ingredient.name,
          kind: IngredientMatchKind.partial,
          optional: ingredient.optional,
          matchedProductName: entry.value.displayName ?? productLabel,
          locations: entry.value.locations,
        );
      }
    }

    return IngredientMatchDetail(
      ingredientName: ingredient.name,
      kind: IngredientMatchKind.missing,
      optional: ingredient.optional,
    );
  }

  _AggregatedStock? _findStockForDetail(
    IngredientMatchDetail detail,
    Map<String, _AggregatedStock> stock,
  ) {
    final matched = detail.matchedProductName;
    if (matched == null) return null;
    final needle = _normalizeName(matched);
    for (final entry in stock.values) {
      if (entry.normalizedName == needle) return entry;
      if (entry.displayName != null &&
          _normalizeName(entry.displayName!) == needle) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  double _score({
    required _IngredientAvailability availability,
    required Recipe recipe,
    required RecipeRankingPreferences preferences,
    required int missingCount,
  }) {
    final requiredCount = availability.requiredCount;
    if (requiredCount == 0) return 1.0;

    final coverage = availability.availableCount / requiredCount;
    final missingPenalty = missingCount / requiredCount;
    final expiringScore = availability.availableCount == 0
        ? 0.0
        : availability.expiringAvailableCount / availability.availableCount;
    final prepCap = preferences.maxPrepTimeMinutes ?? 120;
    final prepScore =
        (prepCap - recipe.prepTimeMinutes).clamp(0, prepCap).toDouble() /
        prepCap;

    final cuisineBoost =
        preferences.preferredCuisines.isNotEmpty &&
            recipe.cuisine != null &&
            preferences.preferredCuisines.any(
              (c) => c.toLowerCase() == recipe.cuisine!.toLowerCase(),
            )
        ? 1.0
        : 0.0;

    final favoriteMatches = recipe.tags
        .where(preferences.favoriteTags.contains)
        .length;
    final preferenceScore = preferences.favoriteTags.isEmpty
        ? cuisineBoost
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
          displayName: item.productName,
          locations: [
            if (item.locationName != null && item.locationName!.isNotEmpty)
              item.locationName!,
          ],
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
    this.displayName,
    this.locations = const <String>[],
  });

  final double amount;
  final DateOnly? earliestExpiration;
  final String? normalizedName;
  final String? displayName;
  final List<String> locations;

  _AggregatedStock merge(AvailableInventoryItem item) {
    DateOnly? earliest = earliestExpiration;
    final expiration = item.expirationDate;
    if (expiration != null &&
        (earliest == null || expiration.isBefore(earliest))) {
      earliest = expiration;
    }
    final locs = [...locations];
    final loc = item.locationName;
    if (loc != null && loc.isNotEmpty && !locs.contains(loc)) {
      locs.add(loc);
    }
    return _AggregatedStock(
      amount: amount + item.amount,
      earliestExpiration: earliest,
      normalizedName: normalizedName,
      displayName: displayName,
      locations: locs,
    );
  }
}

final class _IngredientAvailability {
  const _IngredientAvailability({
    required this.availableCount,
    required this.requiredCount,
    required this.expiringAvailableCount,
  });

  final int availableCount;
  final int requiredCount;
  final int expiringAvailableCount;
}
