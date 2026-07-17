import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';

/// Contract for reading inventory stock and applying mutations.
///
/// [applyMutation] must persist the new item state and its paired event in a
/// single transaction so that state and the immutable log never diverge
/// (docs/06-database-design.md §9, FR-HIST-1).
abstract interface class InventoryRepository {
  /// Emits active (non-deleted) inventory items, updating on change.
  Stream<List<InventoryItem>> watchActiveItems();

  /// Emits active inventory items in [locationId].
  Stream<List<InventoryItem>> watchByLocation(String locationId);

  /// Returns the item with [id] (including soft-deleted), or `null`.
  Future<Result<InventoryItem?>> findById(String id);

  /// Atomically persists [mutation]'s item state and its event.
  Future<Result<void>> applyMutation(InventoryMutation mutation);

  /// Emits the immutable event log, optionally filtered by [productId], most
  /// recent first.
  Stream<List<InventoryEvent>> watchEvents({String? productId});
}
