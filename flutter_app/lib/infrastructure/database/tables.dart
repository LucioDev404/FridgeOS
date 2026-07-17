import 'package:drift/drift.dart';

/// Drift table definitions for the FridgeOS local database.
///
/// The schema mirrors docs/06-database-design.md: normalized (3NF), UUID text
/// primary keys, epoch-millisecond UTC timestamps, soft-delete + `sync_version`
/// audit columns for future synchronization, and an append-only event log.

/// Catalog of distinct food articles.
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get brand => text().nullable()();
  TextColumn get category => text()();
  TextColumn get defaultUnit => text()();
  TextColumn get source => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Storage locations (refrigerator / freezer / pantry).
@DataClassName('LocationRow')
class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()();
  IntColumn get shelfLifeBonusDays => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Concrete stock of a product in a location.
@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get locationId => text().references(Locations, #id)();
  RealColumn get quantityAmount => real()();
  TextColumn get quantityUnit => text()();
  TextColumn get expirationDate => text().nullable()();
  RealColumn get lowStockThreshold => real().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (quantity_amount >= 0)'];
}

/// Immutable, append-only log of inventory changes.
@DataClassName('InventoryEventRow')
class InventoryEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get occurredAt => integer()();
  TextColumn get productId => text().nullable().references(Products, #id)();

  /// Snapshot of the affected item id (deliberately not a foreign key so that
  /// history survives item soft-deletion).
  TextColumn get inventoryItemId => text().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get fromLocationId => text().nullable()();
  TextColumn get toLocationId => text().nullable()();
  RealColumn get quantityDelta => real().nullable()();
  RealColumn get quantityBefore => real().nullable()();
  RealColumn get quantityAfter => real().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get metadataJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recipes with ordered steps and tags (JSON-encoded lists).
@DataClassName('RecipeRow')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get prepTimeMinutes => integer()();
  TextColumn get stepsJson => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get source => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ingredients belonging to a recipe (child rows; cascade on recipe delete).
@DataClassName('RecipeIngredientRow')
class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get ingredientName => text().withLength(min: 1, max: 200)();
  RealColumn get quantityAmount => real().nullable()();
  TextColumn get quantityUnit => text().nullable()();
  BoolColumn get optional => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shopping-list items (manual or auto-generated).
@DataClassName('ShoppingListItemRow')
class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  RealColumn get quantityAmount => real().nullable()();
  TextColumn get quantityUnit => text().nullable()();
  TextColumn get origin => text()();
  TextColumn get status => text()();
  IntColumn get dismissedUntil => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// On-device notification schedule entries.
@DataClassName('NotificationScheduleRow')
class NotificationSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  IntColumn get scheduledFor => integer()();
  TextColumn get payloadJson => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Positive/negative barcode lookup cache controlling remote re-queries
/// (FR-BAR-6: never repeatedly query the same barcode).
@DataClassName('BarcodeLookupRow')
class BarcodeLookups extends Table {
  TextColumn get barcode => text()();
  TextColumn get result => text()();
  TextColumn get productId => text().nullable().references(Products, #id)();
  IntColumn get fetchedAt => integer()();
  IntColumn get ttlUntil => integer().nullable()();

  @override
  Set<Column> get primaryKey => {barcode};
}

/// Single-row user preferences. The Dart class is named `Preferences` so the
/// generated accessor is `db.preferences`; the SQL table remains
/// `user_preferences`.
@DataClassName('PreferencesRow')
class Preferences extends Table {
  @override
  String get tableName => 'user_preferences';

  IntColumn get id => integer()();
  IntColumn get maxPrepTimeMinutes => integer().nullable()();
  TextColumn get favoriteTagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get blockedTagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get expiringSoonWindowDays =>
      integer().withDefault(const Constant(3))();
  TextColumn get digestTime => text().withDefault(const Constant('09:00'))();
  BoolColumn get enrichmentEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get theme => text().withDefault(const Constant('system'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

/// Key/value application metadata (schema version, encryption state, ...).
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  @override
  String get tableName => 'app_meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
