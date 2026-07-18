/// Controlled domain enumerations.
///
/// Each enum carries a stable [wire] string used for persistence and backups.
/// The wire value must never change once shipped (it is part of the on-disk and
/// backup format); display strings are localized separately in the UI.
library;

/// Measurement unit for a [quantity]. Units are grouped by physical dimension so
/// that only compatible units can be combined (see `Quantity`).
enum MeasurementUnit {
  pieces('pcs', UnitDimension.count),
  grams('g', UnitDimension.mass),
  kilograms('kg', UnitDimension.mass),
  milliliters('ml', UnitDimension.volume),
  liters('l', UnitDimension.volume),
  pack('pack', UnitDimension.count);

  const MeasurementUnit(this.wire, this.dimension);

  /// Stable persisted identifier.
  final String wire;

  /// Physical dimension used to gate conversions/combinations.
  final UnitDimension dimension;

  /// Parses a [wire] value, throwing [ArgumentError] if unknown.
  static MeasurementUnit fromWire(String wire) => values.firstWhere(
    (u) => u.wire == wire,
    orElse: () => throw ArgumentError.value(wire, 'wire', 'Unknown unit'),
  );
}

/// Physical dimension of a [MeasurementUnit].
enum UnitDimension { count, mass, volume }

/// Product category (controlled, extensible set).
enum FoodCategory {
  dairy('dairy'),
  produce('produce'),
  meat('meat'),
  bakery('bakery'),
  beverages('beverages'),
  frozen('frozen'),
  pantryStaple('pantry_staple'),
  other('other');

  const FoodCategory(this.wire);

  final String wire;

  static FoodCategory fromWire(String wire) => values.firstWhere(
    (c) => c.wire == wire,
    orElse: () => throw ArgumentError.value(wire, 'wire', 'Unknown category'),
  );
}

/// Type of a storage location.
enum LocationType {
  refrigerator('refrigerator'),
  freezer('freezer'),
  pantry('pantry');

  const LocationType(this.wire);

  final String wire;

  static LocationType fromWire(String wire) => values.firstWhere(
    (t) => t.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown location type'),
  );
}

/// Where a product's data originated.
enum ProductSource {
  local('local'),
  openFoodFacts('open_food_facts'),
  manual('manual');

  const ProductSource(this.wire);

  final String wire;

  static ProductSource fromWire(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown product source'),
  );
}

/// Type of an immutable inventory event (see docs/05-domain-model.md).
enum InventoryEventType {
  addProduct('ADD_PRODUCT'),
  removeProduct('REMOVE_PRODUCT'),
  updateQuantity('UPDATE_QUANTITY'),
  restock('RESTOCK'),
  manualCorrection('MANUAL_CORRECTION'),
  changeLocation('CHANGE_LOCATION'),
  consume('CONSUME'),
  discard('DISCARD');

  const InventoryEventType(this.wire);

  final String wire;

  static InventoryEventType fromWire(String wire) => values.firstWhere(
    (t) => t.wire == wire,
    orElse: () => throw ArgumentError.value(wire, 'wire', 'Unknown event type'),
  );
}

/// Derived expiration status of an inventory item.
enum ExpirationStatus { fresh, expiringSoon, expired }

/// Origin of a shopping-list item.
enum ShoppingItemOrigin {
  manual('MANUAL'),
  auto('AUTO');

  const ShoppingItemOrigin(this.wire);

  final String wire;

  static ShoppingItemOrigin fromWire(String wire) => values.firstWhere(
    (o) => o.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown shopping origin'),
  );
}

/// Lifecycle status of a shopping-list item.
enum ShoppingItemStatus {
  pending('PENDING'),
  done('DONE'),
  dismissed('DISMISSED');

  const ShoppingItemStatus(this.wire);

  final String wire;

  static ShoppingItemStatus fromWire(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown shopping status'),
  );
}

/// Origin of a recipe.
enum RecipeSource {
  builtin('builtin'),
  user('user');

  const RecipeSource(this.wire);

  final String wire;

  static RecipeSource fromWire(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown recipe source'),
  );
}

/// Relative cooking difficulty for a recipe (persisted on schema v2+).
enum RecipeDifficulty {
  easy('EASY'),
  medium('MEDIUM'),
  hard('HARD');

  const RecipeDifficulty(this.wire);

  final String wire;

  static RecipeDifficulty fromWire(String wire) => values.firstWhere(
    (d) => d.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'Unknown recipe difficulty'),
  );
}
