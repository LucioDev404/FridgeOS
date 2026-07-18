import 'package:drift/drift.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/infrastructure/database/tables.dart';

part 'app_database.g.dart';

/// Current on-disk schema version. Bump on every schema change and add a
/// migration step + migration test (docs/06-database-design.md §5).
const int kSchemaVersion = 2;

/// Fixed identifiers for the seeded default locations. Using stable ids keeps
/// seeding idempotent and merge-safe for a future sync engine.
const String kDefaultFridgeId = 'seed-location-refrigerator';
const String kDefaultFreezerId = 'seed-location-freezer';
const String kDefaultPantryId = 'seed-location-pantry';

/// The FridgeOS local database.
///
/// Business logic lives in the domain layer; this type only defines the schema,
/// migrations and seed data. Repositories/DAOs build on top of it.
@DriftDatabase(
  tables: [
    Products,
    Locations,
    InventoryItems,
    InventoryEvents,
    Recipes,
    RecipeIngredients,
    ShoppingListItems,
    NotificationSchedules,
    BarcodeLookups,
    Preferences,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seed();
    },
    onUpgrade: (m, from, to) async {
      // Never drop tables or recreate the database — preserve user data.
      if (from < 2) {
        await m.addColumn(recipes, recipes.servings);
        await m.addColumn(recipes, recipes.difficulty);
      }
      await into(appMeta).insertOnConflictUpdate(
        AppMetaCompanion.insert(
          key: 'schema_version',
          value: '$kSchemaVersion',
        ),
      );
    },
    beforeOpen: (details) async {
      // Enforce referential integrity (docs/06-database-design.md §4).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Seeds first-run data: default locations, the preferences singleton and the
  /// schema-version marker. Idempotent via fixed ids / insertOnConflictUpdate.
  Future<void> _seed() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    await batch((b) {
      b.insertAll(locations, [
        _seedLocation(
          kDefaultFridgeId,
          'Refrigerator',
          LocationType.refrigerator,
          now,
        ),
        _seedLocation(kDefaultFreezerId, 'Freezer', LocationType.freezer, now),
        _seedLocation(kDefaultPantryId, 'Pantry', LocationType.pantry, now),
      ]);
      b.insert(
        preferences,
        const PreferencesCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
      b.insert(
        appMeta,
        AppMetaCompanion.insert(
          key: 'schema_version',
          value: '$kSchemaVersion',
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  LocationsCompanion _seedLocation(
    String id,
    String name,
    LocationType type,
    int now,
  ) {
    return LocationsCompanion.insert(
      id: id,
      name: name,
      type: type.wire,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Re-inserts the three default storage locations after a factory reset.
  Future<void> reseedDefaultLocations() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await batch((b) {
      b.insertAll(locations, [
        _seedLocation(
          kDefaultFridgeId,
          'Refrigerator',
          LocationType.refrigerator,
          now,
        ),
        _seedLocation(kDefaultFreezerId, 'Freezer', LocationType.freezer, now),
        _seedLocation(kDefaultPantryId, 'Pantry', LocationType.pantry, now),
      ], mode: InsertMode.insertOrReplace);
    });
  }
}
