import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/repositories/barcode_lookup_repository.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

final class DriftBarcodeLookupRepository implements BarcodeLookupRepository {
  DriftBarcodeLookupRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<BarcodeLookup?>> find(Barcode barcode) async {
    try {
      final row = await (_db.select(
        _db.barcodeLookups,
      )..where((t) => t.barcode.equals(barcode.value))).getSingleOrNull();
      if (row == null) return const Result.success(null);
      return Result.success(
        BarcodeLookup(
          barcode: barcode,
          result: row.result == 'found'
              ? BarcodeLookupResult.found
              : BarcodeLookupResult.notFound,
          productId: row.productId,
          fetchedAt: DateTime.fromMillisecondsSinceEpoch(
            row.fetchedAt,
            isUtc: true,
          ),
          ttlUntil: row.ttlUntil == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(row.ttlUntil!, isUtc: true),
        ),
      );
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('barcode lookup find: $e'));
    }
  }

  @override
  Future<Result<void>> upsert(BarcodeLookup lookup) async {
    try {
      await _db
          .into(_db.barcodeLookups)
          .insertOnConflictUpdate(
            BarcodeLookupsCompanion(
              barcode: Value(lookup.barcode.value),
              result: Value(
                lookup.result == BarcodeLookupResult.found
                    ? 'found'
                    : 'not_found',
              ),
              productId: Value(lookup.productId),
              fetchedAt: Value(lookup.fetchedAt.toUtc().millisecondsSinceEpoch),
              ttlUntil: Value(lookup.ttlUntil?.toUtc().millisecondsSinceEpoch),
            ),
          );
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('barcode lookup upsert: $e'));
    }
  }
}
