import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/app/theme/app_theme.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

import 'fake_repositories.dart';
import 'fakes.dart';

/// A widget-test harness backed by in-memory fake repositories (no drift, no
/// timers), with deterministic clock/ids, a seeding [InventoryActions], and a
/// builder that wraps a screen in a localized [MaterialApp] with the same
/// repository provider overrides.
final class TestHarness {
  TestHarness()
    : clock = FixedClock(DateTime.utc(2026, 7, 17, 10)),
      ids = SequentialIdGenerator() {
    final now = DateTime.utc(2026, 7, 1);
    locations = FakeLocationRepository([
      Location(
        id: kDefaultFridgeId,
        name: 'Refrigerator',
        type: LocationType.refrigerator,
        createdAt: now,
        updatedAt: now,
      ),
      Location(
        id: kDefaultFreezerId,
        name: 'Freezer',
        type: LocationType.freezer,
        createdAt: now,
        updatedAt: now,
      ),
      Location(
        id: kDefaultPantryId,
        name: 'Pantry',
        type: LocationType.pantry,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    products = FakeProductRepository();
    inventory = FakeInventoryRepository();
    actions = InventoryActions(
      products: products,
      inventory: inventory,
      mutations: InventoryMutationService(clock, ids),
      sanitizer: const InputSanitizer(),
      clock: clock,
      ids: ids,
    );
  }

  final FixedClock clock;
  final SequentialIdGenerator ids;
  late final FakeProductRepository products;
  late final FakeLocationRepository locations;
  late final FakeInventoryRepository inventory;
  late final InventoryActions actions;

  Widget wrap(Widget screen) {
    return ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        locationRepositoryProvider.overrideWithValue(locations),
        inventoryRepositoryProvider.overrideWithValue(inventory),
        preferencesRepositoryProvider.overrideWithValue(
          FakePreferencesRepository(),
        ),
        recipeRepositoryProvider.overrideWithValue(FakeRecipeRepository()),
        shoppingRepositoryProvider.overrideWithValue(FakeShoppingRepository()),
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(ids),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: screen),
      ),
    );
  }
}
