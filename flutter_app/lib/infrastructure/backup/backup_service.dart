import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/infrastructure/backup/backup_crypto.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Current plaintext backup payload schema version.
const int kBackupPayloadVersion = 1;

/// Exports and restores encrypted local database snapshots (FR-SET-3).
final class BackupService {
  BackupService(this._db, {BackupCrypto? crypto})
    : _crypto = crypto ?? BackupCrypto();

  final AppDatabase _db;
  final BackupCrypto _crypto;

  Future<Result<Uint8List>> exportEncrypted(String passphrase) async {
    final payloadResult = await _buildPayload();
    if (payloadResult.isFailure) {
      return Result.failure(payloadResult.failureOrNull!);
    }

    final encrypted = await _crypto.encrypt(
      plaintext: payloadResult.valueOrNull!,
      passphrase: passphrase,
    );
    if (encrypted.isFailure) {
      return Result.failure(encrypted.failureOrNull!);
    }

    return Result.success(encrypted.valueOrNull!.toBytes());
  }

  Future<Result<void>> importEncrypted(
    Uint8List bytes,
    String passphrase,
  ) async {
    Map<String, dynamic> envelopeJson;
    try {
      envelopeJson = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } on FormatException {
      return const Result.failure(CryptoFailure('Malformed backup file'));
    }

    final envelopeResult = BackupEnvelope.fromJson(envelopeJson);
    if (envelopeResult.isFailure) {
      return Result.failure(envelopeResult.failureOrNull!);
    }
    final envelope = envelopeResult.valueOrNull!;
    if (envelope.version != kBackupEnvelopeVersion) {
      return const Result.failure(CryptoFailure('Unsupported backup version'));
    }

    final decrypted = await _crypto.decrypt(
      envelope: envelope,
      passphrase: passphrase,
    );
    if (decrypted.isFailure) {
      return Result.failure(decrypted.failureOrNull!);
    }

    return _restorePayload(decrypted.valueOrNull!);
  }

  /// Clears user inventory data and restores default locations.
  Future<Result<void>> factoryReset() async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.inventoryEvents).go();
        await _db.delete(_db.inventoryItems).go();
        await _db.delete(_db.products).go();
        await _db.delete(_db.shoppingListItems).go();
        await _db.delete(_db.locations).go();
      });
      await _db.reseedDefaultLocations();
      return const Result.success(null);
    } on Object {
      return const Result.failure(PersistenceFailure('Factory reset failed'));
    }
  }

  Future<Result<Uint8List>> _buildPayload() async {
    try {
      final products = await _db.select(_db.products).get();
      final locations = await _db.select(_db.locations).get();
      final inventoryItems = await _db.select(_db.inventoryItems).get();
      final inventoryEvents = await _db.select(_db.inventoryEvents).get();
      final recipes = await _db.select(_db.recipes).get();
      final recipeIngredients = await _db.select(_db.recipeIngredients).get();
      final shoppingListItems = await _db.select(_db.shoppingListItems).get();
      final preferences = await _db.select(_db.preferences).get();

      final payload = {
        'schemaVersion': kBackupPayloadVersion,
        'products': products.map((row) => row.toJson()).toList(),
        'locations': locations.map((row) => row.toJson()).toList(),
        'inventory_items': inventoryItems.map((row) => row.toJson()).toList(),
        'inventory_events': inventoryEvents.map((row) => row.toJson()).toList(),
        'recipes': recipes.map((row) => row.toJson()).toList(),
        'recipe_ingredients': recipeIngredients
            .map((row) => row.toJson())
            .toList(),
        'shopping_list_items': shoppingListItems
            .map((row) => row.toJson())
            .toList(),
        'preferences': preferences.map((row) => row.toJson()).toList(),
      };

      return Result.success(
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
    } on Object {
      return const Result.failure(PersistenceFailure('Export failed'));
    }
  }

  Future<Result<void>> _restorePayload(Uint8List plaintext) async {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } on FormatException {
      return const Result.failure(CryptoFailure('Invalid backup payload'));
    }

    final schemaVersion = payload['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != kBackupPayloadVersion) {
      return const Result.failure(CryptoFailure('Unsupported backup payload'));
    }

    try {
      await _db.transaction(() async {
        await _db.delete(_db.inventoryEvents).go();
        await _db.delete(_db.inventoryItems).go();
        await _db.delete(_db.recipeIngredients).go();
        await _db.delete(_db.shoppingListItems).go();
        await _db.delete(_db.recipes).go();
        await _db.delete(_db.products).go();
        await _db.delete(_db.locations).go();

        await _insertLocations(payload['locations']);
        await _insertProducts(payload['products']);
        await _insertInventoryItems(payload['inventory_items']);
        await _insertInventoryEvents(payload['inventory_events']);
        await _insertRecipes(payload['recipes']);
        await _insertRecipeIngredients(payload['recipe_ingredients']);
        await _insertShoppingListItems(payload['shopping_list_items']);
        await _replacePreferences(payload['preferences']);
      });
      return const Result.success(null);
    } on Object {
      return const Result.failure(PersistenceFailure('Import failed'));
    }
  }

  Future<void> _insertLocations(Object? rawRows) =>
      _insertRows(_db.locations, rawRows, LocationRow.fromJson);

  Future<void> _insertProducts(Object? rawRows) =>
      _insertRows(_db.products, rawRows, ProductRow.fromJson);

  Future<void> _insertInventoryItems(Object? rawRows) =>
      _insertRows(_db.inventoryItems, rawRows, InventoryItemRow.fromJson);

  Future<void> _insertInventoryEvents(Object? rawRows) =>
      _insertRows(_db.inventoryEvents, rawRows, InventoryEventRow.fromJson);

  Future<void> _insertRecipes(Object? rawRows) =>
      _insertRows(_db.recipes, rawRows, RecipeRow.fromJson);

  Future<void> _insertRecipeIngredients(Object? rawRows) =>
      _insertRows(_db.recipeIngredients, rawRows, RecipeIngredientRow.fromJson);

  Future<void> _insertShoppingListItems(Object? rawRows) =>
      _insertRows(_db.shoppingListItems, rawRows, ShoppingListItemRow.fromJson);

  Future<void> _insertRows<T extends Insertable<T>>(
    TableInfo<Table, dynamic> table,
    Object? rawRows,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (rawRows is! List || rawRows.isEmpty) return;
    final rows = <T>[
      for (final entry in rawRows)
        if (entry is Map<String, dynamic>) fromJson(entry),
    ];
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(table, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> _replacePreferences(Object? rawRows) async {
    if (rawRows is! List || rawRows.isEmpty) return;
    final first = rawRows.first;
    if (first is! Map<String, dynamic>) return;
    final row = PreferencesRow.fromJson(first);
    await _db.into(_db.preferences).insertOnConflictUpdate(row);
  }
}
