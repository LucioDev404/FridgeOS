import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

void main() {
  test('opens an in-memory database and applies seed data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final locations = await db.select(db.locations).get();
    expect(
      locations.map((l) => l.id),
      containsAll(<String>[
        kDefaultFridgeId,
        kDefaultFreezerId,
        kDefaultPantryId,
      ]),
    );

    final prefs = await db.select(db.preferences).getSingle();
    expect(prefs.id, 1);
    expect(prefs.expiringSoonWindowDays, 3);
    expect(prefs.enrichmentEnabled, isTrue);

    final schemaVersion = await (db.select(
      db.appMeta,
    )..where((t) => t.key.equals('schema_version'))).getSingle();
    expect(schemaVersion.value, '$kSchemaVersion');
  });

  test('creates the full normalized schema (v1)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final tableNames = db.allTables.map((t) => t.actualTableName).toSet();
    expect(tableNames, <String>{
      'products',
      'locations',
      'inventory_items',
      'inventory_events',
      'recipes',
      'recipe_ingredients',
      'shopping_list_items',
      'notification_schedules',
      'barcode_lookups',
      'user_preferences',
      'app_meta',
    });
  });

  test('enforces foreign keys at runtime', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(result.data.values.first, 1);
  });
}
