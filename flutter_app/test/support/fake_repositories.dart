import 'dart:async';

import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/entities/user_preferences.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
import 'package:fridgeos/domain/repositories/location_repository.dart';
import 'package:fridgeos/domain/repositories/preferences_repository.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/domain/repositories/recipe_repository.dart';
import 'package:fridgeos/domain/repositories/shopping_repository.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// In-memory fakes used by widget tests. They emit via microtask-based streams
/// (no timers), so they play nicely with the widget tester's fake-async clock —
/// unlike drift, which is covered separately by the data-layer tests.

final class FakeProductRepository implements ProductRepository {
  final Map<String, Product> _products = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Product> get _active =>
      _products.values.where((p) => !p.isDeleted).toList();

  @override
  Future<Result<Product?>> findById(String id) async =>
      Result.success(_products[id]);

  @override
  Future<Result<Product?>> findByBarcode(String barcode) async {
    for (final product in _active) {
      if (product.barcode?.value == barcode) return Result.success(product);
    }
    return const Result.success(null);
  }

  @override
  Stream<List<Product>> watchAll() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Future<Result<void>> upsert(Product product) async {
    _products[product.id] = product;
    _changes.add(null);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> softDelete(String id, DateTime deletedAt) async {
    final existing = _products[id];
    if (existing != null) {
      _products[id] = existing.copyWith(deletedAt: deletedAt);
      _changes.add(null);
    }
    return const Result.success(null);
  }
}

final class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository(List<Location> initial) {
    for (final location in initial) {
      _locations[location.id] = location;
    }
  }

  final Map<String, Location> _locations = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Location> get _active =>
      _locations.values.where((l) => !l.isDeleted).toList();

  @override
  Stream<List<Location>> watchAll() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Future<Result<Location?>> findById(String id) async =>
      Result.success(_locations[id]);

  @override
  Future<Result<void>> upsert(Location location) async {
    _locations[location.id] = location;
    _changes.add(null);
    return const Result.success(null);
  }
}

final class FakeInventoryRepository implements InventoryRepository {
  final Map<String, InventoryItem> _items = {};
  final List<InventoryEvent> _events = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<InventoryItem> get _active =>
      _items.values.where((i) => i.isActive).toList();

  @override
  Stream<List<InventoryItem>> watchActiveItems() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Stream<List<InventoryItem>> watchByLocation(String locationId) async* {
    List<InventoryItem> inLocation() =>
        _active.where((i) => i.locationId == locationId).toList();
    yield inLocation();
    yield* _changes.stream.map((_) => inLocation());
  }

  @override
  Future<Result<InventoryItem?>> findById(String id) async =>
      Result.success(_items[id]);

  @override
  Future<Result<void>> applyMutation(InventoryMutation mutation) async {
    _items[mutation.item.id] = mutation.item;
    _events.add(mutation.event);
    _changes.add(null);
    return const Result.success(null);
  }

  @override
  Stream<List<InventoryEvent>> watchEvents({String? productId}) async* {
    List<InventoryEvent> filtered() => productId == null
        ? List.of(_events)
        : _events.where((e) => e.productId == productId).toList();
    yield filtered();
    yield* _changes.stream.map((_) => filtered());
  }
}

final class FakePreferencesRepository implements PreferencesRepository {
  UserPreferences _prefs = const UserPreferences();
  final StreamController<UserPreferences> _controller =
      StreamController<UserPreferences>.broadcast();

  @override
  Stream<UserPreferences> watch() async* {
    yield _prefs;
    yield* _controller.stream;
  }

  @override
  Future<Result<UserPreferences>> load() async => Result.success(_prefs);

  @override
  Future<Result<void>> save(UserPreferences preferences) async {
    _prefs = preferences;
    _controller.add(_prefs);
    return const Result.success(null);
  }
}

final class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository([List<Recipe> initial = const []]) {
    for (final recipe in initial) {
      _recipes[recipe.id] = recipe;
    }
  }

  final Map<String, Recipe> _recipes = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Recipe> get _active =>
      _recipes.values.where((r) => !r.isDeleted).toList();

  @override
  Stream<List<Recipe>> watchAll() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Future<Result<void>> upsert(Recipe recipe) async {
    _recipes[recipe.id] = recipe;
    _changes.add(null);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> ensureBuiltinRecipes() async =>
      const Result.success(null);
}

final class FakeShoppingRepository implements ShoppingRepository {
  final Map<String, ShoppingListItem> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<ShoppingListItem> get _active =>
      _items.values.where((i) => !i.isDeleted).toList();

  @override
  Stream<List<ShoppingListItem>> watchPending() async* {
    List<ShoppingListItem> pending() =>
        _active.where((i) => i.status == ShoppingItemStatus.pending).toList();
    yield pending();
    yield* _changes.stream.map((_) => pending());
  }

  @override
  Stream<List<ShoppingListItem>> watchAll() async* {
    yield _active;
    yield* _changes.stream.map((_) => _active);
  }

  @override
  Future<Result<void>> upsert(ShoppingListItem item) async {
    _items[item.id] = item;
    _changes.add(null);
    return const Result.success(null);
  }
}
