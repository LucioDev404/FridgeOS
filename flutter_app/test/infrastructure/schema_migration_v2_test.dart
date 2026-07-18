import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates v1 database to v2 without losing product rows', () async {
    final dir = await Directory.systemTemp.createTemp('fridgeos-mig-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File(p.join(dir.path, 'fridgeos.sqlite'));

    // Simulate a v1 on-disk database (pre-servings/difficulty columns).
    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA foreign_keys = ON');
    raw.execute('''
      CREATE TABLE products (
        id TEXT NOT NULL PRIMARY KEY,
        barcode TEXT NULL UNIQUE,
        name TEXT NOT NULL,
        brand TEXT NULL,
        category TEXT NOT NULL,
        default_unit TEXT NOT NULL,
        source TEXT NOT NULL,
        image_url TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        sync_version INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE locations (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        shelf_life_bonus_days INTEGER NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        sync_version INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE inventory_items (
        id TEXT NOT NULL PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id),
        location_id TEXT NOT NULL REFERENCES locations(id),
        quantity_amount REAL NOT NULL,
        quantity_unit TEXT NOT NULL,
        expiration_date TEXT NULL,
        low_stock_threshold REAL NULL,
        note TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        sync_version INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE inventory_events (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        product_id TEXT NULL,
        inventory_item_id TEXT NULL,
        location_id TEXT NULL,
        from_location_id TEXT NULL,
        to_location_id TEXT NULL,
        quantity_delta REAL NULL,
        quantity_before REAL NULL,
        quantity_after REAL NULL,
        reason TEXT NULL,
        metadata_json TEXT NOT NULL DEFAULT '{}'
      );
    ''');
    raw.execute('''
      CREATE TABLE recipes (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        prep_time_minutes INTEGER NOT NULL,
        steps_json TEXT NOT NULL,
        tags_json TEXT NOT NULL DEFAULT '[]',
        source TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        sync_version INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE recipe_ingredients (
        id TEXT NOT NULL PRIMARY KEY,
        recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
        product_id TEXT NULL REFERENCES products(id),
        ingredient_name TEXT NOT NULL,
        quantity_amount REAL NULL,
        quantity_unit TEXT NULL,
        optional INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE shopping_list_items (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        product_id TEXT NULL REFERENCES products(id),
        quantity_amount REAL NULL,
        quantity_unit TEXT NULL,
        origin TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        sync_version INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE notification_schedules (
        id TEXT NOT NULL PRIMARY KEY,
        inventory_item_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        scheduled_for INTEGER NOT NULL,
        delivered_at INTEGER NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE barcode_lookups (
        barcode TEXT NOT NULL PRIMARY KEY,
        payload_json TEXT NOT NULL,
        fetched_at INTEGER NOT NULL,
        expires_at INTEGER NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE user_preferences (
        id INTEGER NOT NULL PRIMARY KEY,
        locale TEXT NULL,
        max_prep_time_minutes INTEGER NULL,
        favorite_tags_json TEXT NOT NULL DEFAULT '[]',
        blocked_tags_json TEXT NOT NULL DEFAULT '[]',
        expiring_soon_window_days INTEGER NOT NULL DEFAULT 3,
        digest_time TEXT NULL,
        enrichment_enabled INTEGER NOT NULL DEFAULT 1,
        theme TEXT NOT NULL DEFAULT 'system'
      );
    ''');
    raw.execute('''
      CREATE TABLE app_meta (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO app_meta (key, value) VALUES ('schema_version', '1');",
    );
    raw.execute(
      "INSERT INTO products (id, name, category, default_unit, source, created_at, updated_at) "
      "VALUES ('p1', 'Milk', 'dairy', 'l', 'manual', 1, 1);",
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final products = await db.select(db.products).get();
    expect(products, hasLength(1));
    expect(products.single.name, 'Milk');

    final columns = await db.customSelect('PRAGMA table_info(recipes)').get();
    final names = columns.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(<String>['servings', 'difficulty']));

    final meta = await (db.select(
      db.appMeta,
    )..where((t) => t.key.equals('schema_version'))).getSingle();
    expect(meta.value, '2');
  });
}
