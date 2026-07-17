import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/repositories/location_repository.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [LocationRepository].
final class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Location>> watchAll() {
    final query = _db.select(_db.locations)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(locationFromRow).toList());
  }

  @override
  Future<Result<Location?>> findById(String id) async {
    try {
      final row =
          await (_db.select(_db.locations)
                ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
              .getSingleOrNull();
      return Result.success(row == null ? null : locationFromRow(row));
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('findById failed: $e'));
    }
  }

  @override
  Future<Result<void>> upsert(Location location) async {
    try {
      await _db
          .into(_db.locations)
          .insertOnConflictUpdate(locationToCompanion(location));
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('upsert failed: $e'));
    }
  }
}
