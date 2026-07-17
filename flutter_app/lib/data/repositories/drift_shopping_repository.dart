import 'package:drift/drift.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/repositories/shopping_repository.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Drift-backed [ShoppingRepository].
final class DriftShoppingRepository implements ShoppingRepository {
  DriftShoppingRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ShoppingListItem>> watchPending() {
    final query = _db.select(_db.shoppingListItems)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.status.equals(ShoppingItemStatus.pending.wire),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map(shoppingListItemFromRow).toList(),
    );
  }

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    final query = _db.select(_db.shoppingListItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map(shoppingListItemFromRow).toList(),
    );
  }

  @override
  Future<Result<void>> upsert(ShoppingListItem item) async {
    try {
      await _db
          .into(_db.shoppingListItems)
          .insertOnConflictUpdate(shoppingListItemToCompanion(item));
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(PersistenceFailure('upsert shopping item: $e'));
    }
  }
}
