import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/user_preferences.dart';
import 'package:fridgeos/domain/repositories/preferences_repository.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [PreferencesRepository] for the singleton preferences row.
final class DriftPreferencesRepository implements PreferencesRepository {
  DriftPreferencesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<UserPreferences> watch() {
    final query = _db.select(_db.preferences)..where((t) => t.id.equals(1));
    return query.watch().map((rows) {
      if (rows.isEmpty) return const UserPreferences();
      return preferencesFromRow(rows.single);
    });
  }

  @override
  Future<Result<UserPreferences>> load() async {
    try {
      final row = await (_db.select(
        _db.preferences,
      )..where((t) => t.id.equals(1))).getSingleOrNull();
      return Result.success(
        row == null ? const UserPreferences() : preferencesFromRow(row),
      );
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('load preferences failed: $e'));
    }
  }

  @override
  Future<Result<void>> save(UserPreferences preferences) async {
    try {
      await _db
          .into(_db.preferences)
          .insertOnConflictUpdate(preferencesToCompanion(preferences));
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('save preferences failed: $e'));
    }
  }
}
