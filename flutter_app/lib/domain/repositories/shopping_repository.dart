import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';

/// Contract for the shopping list.
abstract interface class ShoppingRepository {
  /// Emits pending (non-deleted) items, updating on change.
  Stream<List<ShoppingListItem>> watchPending();

  /// Emits all non-deleted items (any status), for policy deduplication.
  Stream<List<ShoppingListItem>> watchAll();

  /// Persists [item] (insert or update).
  Future<Result<void>> upsert(ShoppingListItem item);
}
