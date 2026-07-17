import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [InventoryRepository].
///
/// [applyMutation] writes the item state and its immutable event inside a single
/// transaction, guaranteeing the log and state never diverge
/// (docs/06-database-design.md §9).
final class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<InventoryItem>> watchActiveItems() {
    final query = _db.select(_db.inventoryItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(inventoryItemFromRow).toList());
  }

  @override
  Stream<List<InventoryItem>> watchByLocation(String locationId) {
    final query = _db.select(_db.inventoryItems)
      ..where((t) => t.deletedAt.isNull() & t.locationId.equals(locationId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(inventoryItemFromRow).toList());
  }

  @override
  Future<Result<InventoryItem?>> findById(String id) async {
    try {
      final row = await (_db.select(
        _db.inventoryItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return Result.success(row == null ? null : inventoryItemFromRow(row));
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('findById failed: $e'));
    }
  }

  @override
  Future<Result<void>> applyMutation(InventoryMutation mutation) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.inventoryItems)
            .insertOnConflictUpdate(inventoryItemToCompanion(mutation.item));
        // Events are append-only: always an insert, never an update.
        await _db
            .into(_db.inventoryEvents)
            .insert(inventoryEventToCompanion(mutation.event));
      });
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('applyMutation failed: $e'));
    }
  }

  @override
  Stream<List<InventoryEvent>> watchEvents({String? productId}) {
    final query = _db.select(_db.inventoryEvents)
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);
    if (productId != null) {
      query.where((t) => t.productId.equals(productId));
    }
    return query.watch().map(
      (rows) => rows.map(inventoryEventFromRow).toList(),
    );
  }
}
