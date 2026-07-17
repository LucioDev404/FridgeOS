import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Aggregated consumption and waste metrics derived from inventory events.
final class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.mostConsumed,
    required this.wasteByProduct,
    required this.wasteTotal,
    required this.consumptionTotal,
  });

  /// Consumption per product (`productId` -> total amount).
  final Map<String, double> mostConsumed;
  final Map<String, double> wasteByProduct;
  final double wasteTotal;
  final double consumptionTotal;
}

/// Pure service that projects statistics from the immutable event log
/// (see FR-STAT-1/2/4, docs/05-domain-model.md §7).
final class StatisticsCalculator {
  const StatisticsCalculator();

  /// Computes consumption and waste totals from [events], optionally restricted
  /// to [[rangeStart], [rangeEnd]] (inclusive on both ends when set).
  Result<StatisticsSnapshot> compute({
    required List<InventoryEvent> events,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    if (rangeStart != null &&
        rangeEnd != null &&
        rangeStart.isAfter(rangeEnd)) {
      return const Result.failure(
        ValidationFailure('rangeStart must not be after rangeEnd'),
      );
    }

    final mostConsumed = <String, double>{};
    final wasteByProduct = <String, double>{};
    var wasteTotal = 0.0;
    var consumptionTotal = 0.0;

    for (final event in events) {
      if (!_isInRange(event.occurredAt, rangeStart, rangeEnd)) continue;

      final productId = event.productId;
      if (productId == null) continue;

      final delta = event.quantityDelta;
      if (delta == null || delta == 0) continue;

      if (event.type == InventoryEventType.consume) {
        final amount = delta.abs();
        mostConsumed[productId] = (mostConsumed[productId] ?? 0) + amount;
        consumptionTotal += amount;
        continue;
      }

      if (event.type == InventoryEventType.discard &&
          event.reason == kWasteReason) {
        final amount = delta.abs();
        wasteByProduct[productId] = (wasteByProduct[productId] ?? 0) + amount;
        wasteTotal += amount;
      }
    }

    return Result.success(
      StatisticsSnapshot(
        mostConsumed: mostConsumed,
        wasteByProduct: wasteByProduct,
        wasteTotal: wasteTotal,
        consumptionTotal: consumptionTotal,
      ),
    );
  }

  bool _isInRange(DateTime occurredAt, DateTime? start, DateTime? end) {
    if (start != null && occurredAt.isBefore(start)) return false;
    if (end != null && occurredAt.isAfter(end)) return false;
    return true;
  }
}
