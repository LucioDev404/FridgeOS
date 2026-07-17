import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// Reason string used on discard events representing food waste.
const String kWasteReason = 'WASTE';

/// The result of an inventory mutation: the new item state paired with the
/// immutable event that records the change. The data layer must persist both in
/// a single transaction (docs/05-domain-model.md invariant 3, FR-HIST-1).
final class InventoryMutation {
  const InventoryMutation({required this.item, required this.event});

  final InventoryItem item;
  final InventoryEvent event;
}

/// Pure domain service that applies inventory changes while enforcing the core
/// invariants (non-negative quantity, one event per mutation) and generating the
/// paired [InventoryEvent].
///
/// Time and identifiers are injected so mutations are deterministic in tests.
final class InventoryMutationService {
  const InventoryMutationService(this._clock, this._ids);

  final Clock _clock;
  final IdGenerator _ids;

  /// Creates a brand-new inventory item and its `ADD_PRODUCT` event.
  InventoryMutation createItem({
    required String productId,
    required String locationId,
    required Quantity quantity,
    DateOnly? expirationDate,
    double? lowStockThreshold,
    String? note,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final now = _clock.nowUtc();
    final item = InventoryItem(
      id: _ids.newId(),
      productId: productId,
      locationId: locationId,
      quantity: quantity,
      expirationDate: expirationDate,
      lowStockThreshold: lowStockThreshold,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    final event = InventoryEvent(
      id: _ids.newId(),
      type: InventoryEventType.addProduct,
      occurredAt: now,
      productId: productId,
      inventoryItemId: item.id,
      locationId: locationId,
      quantityDelta: quantity.amount,
      quantityBefore: 0,
      quantityAfter: quantity.amount,
      metadata: metadata,
    );
    return InventoryMutation(item: item, event: event);
  }

  /// Applies a signed [deltaAmount] (in the item's unit) to [item].
  ///
  /// Returns a [ValidationFailure] when the resulting amount would be negative.
  /// When the amount reaches zero the item is soft-deleted (leaves active
  /// stock) while its history is retained (FR-INV-4).
  Result<InventoryMutation> applyQuantityDelta({
    required InventoryItem item,
    required double deltaAmount,
    required InventoryEventType type,
    String? reason,
    Map<String, String> metadata = const <String, String>{},
  }) {
    if (!item.isActive) {
      return const Result.failure(
        ValidationFailure('Cannot modify a removed inventory item'),
      );
    }
    final before = item.quantity.amount;
    final after = before + deltaAmount;
    if (after < 0) {
      return Result.failure(
        ValidationFailure(
          'Quantity cannot go below zero (have $before, delta $deltaAmount)',
        ),
      );
    }

    final now = _clock.nowUtc();
    final depleted = after == 0;
    final newItem = item.copyWith(
      quantity: Quantity(after, item.quantity.unit),
      updatedAt: now,
      deletedAt: depleted ? now : null,
    );
    final event = InventoryEvent(
      id: _ids.newId(),
      type: type,
      occurredAt: now,
      productId: item.productId,
      inventoryItemId: item.id,
      locationId: item.locationId,
      quantityDelta: deltaAmount,
      quantityBefore: before,
      quantityAfter: after,
      reason: reason,
      metadata: metadata,
    );
    return Result.success(InventoryMutation(item: newItem, event: event));
  }

  /// Consumes [amount] of an item's unit, recording a `CONSUME` event.
  Result<InventoryMutation> consume({
    required InventoryItem item,
    required double amount,
    Map<String, String> metadata = const <String, String>{},
  }) {
    if (amount <= 0) {
      return const Result.failure(
        ValidationFailure('Consumed amount must be positive'),
      );
    }
    return applyQuantityDelta(
      item: item,
      deltaAmount: -amount,
      type: InventoryEventType.consume,
      metadata: metadata,
    );
  }

  /// Discards [amount] as waste, recording a `DISCARD` event with reason
  /// [kWasteReason] (feeds food-waste statistics — FR-STAT-2).
  Result<InventoryMutation> discard({
    required InventoryItem item,
    required double amount,
    Map<String, String> metadata = const <String, String>{},
  }) {
    if (amount <= 0) {
      return const Result.failure(
        ValidationFailure('Discarded amount must be positive'),
      );
    }
    return applyQuantityDelta(
      item: item,
      deltaAmount: -amount,
      type: InventoryEventType.discard,
      reason: kWasteReason,
      metadata: metadata,
    );
  }

  /// Removes the item entirely (sets quantity to zero), recording a
  /// `REMOVE_PRODUCT` event.
  Result<InventoryMutation> removeAll({
    required InventoryItem item,
    Map<String, String> metadata = const <String, String>{},
  }) {
    return applyQuantityDelta(
      item: item,
      deltaAmount: -item.quantity.amount,
      type: InventoryEventType.removeProduct,
      metadata: metadata,
    );
  }

  /// Moves an item to [toLocationId], recording a `CHANGE_LOCATION` event.
  /// Returns a [ValidationFailure] when the target equals the current location.
  Result<InventoryMutation> changeLocation({
    required InventoryItem item,
    required String toLocationId,
    Map<String, String> metadata = const <String, String>{},
  }) {
    if (!item.isActive) {
      return const Result.failure(
        ValidationFailure('Cannot move a removed inventory item'),
      );
    }
    if (toLocationId == item.locationId) {
      return const Result.failure(
        ValidationFailure('Item is already in the target location'),
      );
    }
    final now = _clock.nowUtc();
    final fromLocationId = item.locationId;
    final newItem = item.copyWith(locationId: toLocationId, updatedAt: now);
    final event = InventoryEvent(
      id: _ids.newId(),
      type: InventoryEventType.changeLocation,
      occurredAt: now,
      productId: item.productId,
      inventoryItemId: item.id,
      locationId: toLocationId,
      fromLocationId: fromLocationId,
      toLocationId: toLocationId,
      quantityBefore: item.quantity.amount,
      quantityAfter: item.quantity.amount,
      metadata: metadata,
    );
    return Result.success(InventoryMutation(item: newItem, event: event));
  }
}
