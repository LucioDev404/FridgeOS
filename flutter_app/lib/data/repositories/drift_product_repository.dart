import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [ProductRepository].
final class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Result<Product?>> findById(String id) async {
    try {
      final row =
          await (_db.select(_db.products)
                ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
              .getSingleOrNull();
      return Result.success(row == null ? null : productFromRow(row));
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('findById failed: $e'));
    }
  }

  @override
  Future<Result<Product?>> findByBarcode(String barcode) async {
    try {
      final row =
          await (_db.select(
                _db.products,
              )..where((t) => t.barcode.equals(barcode) & t.deletedAt.isNull()))
              .getSingleOrNull();
      return Result.success(row == null ? null : productFromRow(row));
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('findByBarcode failed: $e'));
    }
  }

  @override
  Stream<List<Product>> watchAll() {
    final query = _db.select(_db.products)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(productFromRow).toList());
  }

  @override
  Future<Result<void>> upsert(Product product) async {
    try {
      await _db
          .into(_db.products)
          .insertOnConflictUpdate(productToCompanion(product));
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('upsert failed: $e'));
    }
  }

  @override
  Future<Result<void>> softDelete(String id, DateTime deletedAt) async {
    try {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          deletedAt: Value(deletedAt.toUtc().millisecondsSinceEpoch),
          updatedAt: Value(deletedAt.toUtc().millisecondsSinceEpoch),
        ),
      );
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('softDelete failed: $e'));
    }
  }
}
