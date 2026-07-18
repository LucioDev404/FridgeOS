import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Aggregated consumption and waste metrics derived from inventory events.
final class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.mostConsumed,
    required this.leastConsumed,
    required this.wasteByProduct,
    required this.wasteTotal,
    required this.consumptionTotal,
    required this.dailyConsumption,
    required this.weeklyConsumption,
    required this.monthlyConsumption,
    required this.averageDailyUsage,
    required this.consumptionVelocity,
    required this.inventoryOscillation,
    required this.restockFrequency,
    required this.lowStockFrequency,
    required this.dailyStockChanges,
    required this.consumptionByLocation,
    required this.stockByLocation,
  });

  /// Consumption per product (`productId` -> total amount).
  final Map<String, double> mostConsumed;

  /// Products with the lowest non-zero consumption (ascending).
  final Map<String, double> leastConsumed;
  final Map<String, double> wasteByProduct;
  final double wasteTotal;
  final double consumptionTotal;

  /// Calendar-day keyed consumption totals (`yyyy-MM-dd` -> amount).
  final Map<String, double> dailyConsumption;

  /// ISO week keyed consumption (`yyyy-Www` -> amount).
  final Map<String, double> weeklyConsumption;

  /// Calendar-month keyed consumption (`yyyy-MM` -> amount).
  final Map<String, double> monthlyConsumption;

  /// Mean daily consumption across days that had activity (0 when none).
  final double averageDailyUsage;

  /// Consumption per day of span covered by events (velocity proxy).
  final double consumptionVelocity;

  /// Mean absolute day-to-day stock delta magnitude (oscillation).
  final double inventoryOscillation;

  /// Count of RESTOCK / positive ADD_PRODUCT style restocks.
  final int restockFrequency;

  /// Count of quantity-after values that touch or cross a low-stock signal
  /// recorded via metadata or post-consume residual of 1 or less.
  final int lowStockFrequency;

  /// Net quantity change per calendar day.
  final Map<String, double> dailyStockChanges;

  /// Consumption totals keyed by location id.
  final Map<String, double> consumptionByLocation;

  /// Latest known quantity-after per location (distribution snapshot).
  final Map<String, double> stockByLocation;
}

/// Pure service that projects statistics from the immutable event log
/// (see FR-STAT-1/2/4, docs/05-domain-model.md §7).
final class StatisticsCalculator {
  const StatisticsCalculator();

  /// Computes consumption and waste totals from [events], optionally restricted
  /// to [[rangeStart], [rangeEnd]] (inclusive on both ends when set).
  ///
  /// When [locationId] is set, only events at that location are included.
  /// [locationTypeById] maps location ids to types for type-level filters.
  /// [locationFilter] accepts a [LocationType] wire or `null` for all.
  Result<StatisticsSnapshot> compute({
    required List<InventoryEvent> events,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? locationId,
    LocationType? locationFilter,
    Map<String, LocationType> locationTypeById = const {},
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
    final dailyConsumption = <String, double>{};
    final weeklyConsumption = <String, double>{};
    final monthlyConsumption = <String, double>{};
    final dailyStockChanges = <String, double>{};
    final consumptionByLocation = <String, double>{};
    final stockByLocation = <String, double>{};
    var wasteTotal = 0.0;
    var consumptionTotal = 0.0;
    var restockFrequency = 0;
    var lowStockFrequency = 0;

    DateTime? earliest;
    DateTime? latest;

    for (final event in events) {
      if (!_isInRange(event.occurredAt, rangeStart, rangeEnd)) continue;
      if (!_matchesLocation(
        event,
        locationId: locationId,
        locationFilter: locationFilter,
        locationTypeById: locationTypeById,
      )) {
        continue;
      }

      earliest = earliest == null || event.occurredAt.isBefore(earliest)
          ? event.occurredAt
          : earliest;
      latest = latest == null || event.occurredAt.isAfter(latest)
          ? event.occurredAt
          : latest;

      final dayKey = _dayKey(event.occurredAt);
      final delta = event.quantityDelta;
      if (delta != null && delta != 0) {
        dailyStockChanges[dayKey] = (dailyStockChanges[dayKey] ?? 0) + delta;
      }

      final locId = event.locationId;
      if (locId != null && event.quantityAfter != null) {
        stockByLocation[locId] = event.quantityAfter!;
      }

      if (event.type == InventoryEventType.restock ||
          (event.type == InventoryEventType.addProduct && (delta ?? 0) > 0)) {
        restockFrequency++;
      }

      final after = event.quantityAfter;
      if (after != null &&
          after > 0 &&
          after <= 1 &&
          (event.type == InventoryEventType.consume ||
              event.type == InventoryEventType.updateQuantity ||
              event.type == InventoryEventType.manualCorrection)) {
        lowStockFrequency++;
      }

      final productId = event.productId;
      if (productId == null) continue;
      if (delta == null || delta == 0) continue;

      if (event.type == InventoryEventType.consume) {
        final amount = delta.abs();
        mostConsumed[productId] = (mostConsumed[productId] ?? 0) + amount;
        consumptionTotal += amount;
        dailyConsumption[dayKey] = (dailyConsumption[dayKey] ?? 0) + amount;
        final weekKey = _weekKey(event.occurredAt);
        weeklyConsumption[weekKey] = (weeklyConsumption[weekKey] ?? 0) + amount;
        final monthKey = _monthKey(event.occurredAt);
        monthlyConsumption[monthKey] =
            (monthlyConsumption[monthKey] ?? 0) + amount;
        if (locId != null) {
          consumptionByLocation[locId] =
              (consumptionByLocation[locId] ?? 0) + amount;
        }
        continue;
      }

      if (event.type == InventoryEventType.discard &&
          event.reason == kWasteReason) {
        final amount = delta.abs();
        wasteByProduct[productId] = (wasteByProduct[productId] ?? 0) + amount;
        wasteTotal += amount;
      }
    }

    final leastConsumed = Map.fromEntries(
      mostConsumed.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );

    final averageDailyUsage = dailyConsumption.isEmpty
        ? 0.0
        : consumptionTotal / dailyConsumption.length;

    final spanDays = _spanDays(earliest, latest);
    final consumptionVelocity = spanDays <= 0
        ? 0.0
        : consumptionTotal / spanDays;

    final oscillation = _oscillation(dailyStockChanges);

    return Result.success(
      StatisticsSnapshot(
        mostConsumed: mostConsumed,
        leastConsumed: leastConsumed,
        wasteByProduct: wasteByProduct,
        wasteTotal: wasteTotal,
        consumptionTotal: consumptionTotal,
        dailyConsumption: dailyConsumption,
        weeklyConsumption: weeklyConsumption,
        monthlyConsumption: monthlyConsumption,
        averageDailyUsage: averageDailyUsage,
        consumptionVelocity: consumptionVelocity,
        inventoryOscillation: oscillation,
        restockFrequency: restockFrequency,
        lowStockFrequency: lowStockFrequency,
        dailyStockChanges: dailyStockChanges,
        consumptionByLocation: consumptionByLocation,
        stockByLocation: stockByLocation,
      ),
    );
  }

  bool _matchesLocation(
    InventoryEvent event, {
    required String? locationId,
    required LocationType? locationFilter,
    required Map<String, LocationType> locationTypeById,
  }) {
    if (locationId != null) {
      return event.locationId == locationId ||
          event.fromLocationId == locationId ||
          event.toLocationId == locationId;
    }
    if (locationFilter == null) return true;
    final id = event.locationId;
    if (id == null) return false;
    return locationTypeById[id] == locationFilter;
  }

  bool _isInRange(DateTime occurredAt, DateTime? start, DateTime? end) {
    if (start != null && occurredAt.isBefore(start)) return false;
    if (end != null && occurredAt.isAfter(end)) return false;
    return true;
  }

  String _dayKey(DateTime dt) {
    final d = dt.toUtc();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _monthKey(DateTime dt) {
    final d = dt.toUtc();
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}-$m';
  }

  String _weekKey(DateTime dt) {
    final d = dt.toUtc();
    // ISO-8601 week: week starts Monday; week 1 contains Jan 4.
    final thursday = d.add(Duration(days: 4 - (d.weekday)));
    final yearStart = DateTime.utc(thursday.year);
    final week = 1 + ((thursday.difference(yearStart).inDays) / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  int _spanDays(DateTime? earliest, DateTime? latest) {
    if (earliest == null || latest == null) return 0;
    final days = latest.difference(earliest).inDays + 1;
    return days < 1 ? 1 : days;
  }

  double _oscillation(Map<String, double> dailyStockChanges) {
    if (dailyStockChanges.isEmpty) return 0;
    final keys = dailyStockChanges.keys.toList()..sort();
    if (keys.length < 2) {
      return dailyStockChanges.values.first.abs();
    }
    var total = 0.0;
    var count = 0;
    for (var i = 1; i < keys.length; i++) {
      final prev = dailyStockChanges[keys[i - 1]]!;
      final curr = dailyStockChanges[keys[i]]!;
      total += (curr - prev).abs();
      count++;
    }
    return count == 0 ? 0 : total / count;
  }
}
