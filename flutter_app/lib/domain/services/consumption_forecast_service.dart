import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// A single consumption prediction derived from historical inventory events.
final class ConsumptionForecast {
  const ConsumptionForecast({
    required this.productId,
    required this.averageDaysBetweenConsumption,
    required this.estimatedDaysUntilEmpty,
    required this.sampleSize,
  });

  final String productId;

  /// Typical gap between CONSUME events for this product.
  final double averageDaysBetweenConsumption;

  /// Estimated days until stock reaches zero given current quantity and
  /// average daily usage. `null` when insufficient history.
  final double? estimatedDaysUntilEmpty;

  /// Number of consume events used for the estimate.
  final int sampleSize;
}

/// Builds consumption predictions from the immutable event log.
///
/// Architecture scaffolding for inventory forecast (FR-STAT future). Pure and
/// deterministic — UI layers decide how to present the strings.
final class ConsumptionForecastService {
  const ConsumptionForecastService();

  /// Returns forecasts for products with at least two CONSUME events.
  ///
  /// [currentQuantityByProduct] supplies the live stock used for run-out
  /// estimates. When absent for a product, only the consumption cadence is
  /// returned.
  List<ConsumptionForecast> forecast({
    required List<InventoryEvent> events,
    Map<String, double> currentQuantityByProduct = const {},
  }) {
    final consumeTimes = <String, List<DateTime>>{};
    final consumeAmounts = <String, List<double>>{};

    for (final event in events) {
      if (event.type != InventoryEventType.consume) continue;
      final productId = event.productId;
      final delta = event.quantityDelta;
      if (productId == null || delta == null || delta == 0) continue;
      (consumeTimes[productId] ??= <DateTime>[]).add(event.occurredAt);
      (consumeAmounts[productId] ??= <double>[]).add(delta.abs());
    }

    final forecasts = <ConsumptionForecast>[];
    for (final entry in consumeTimes.entries) {
      final times = entry.value..sort();
      if (times.length < 2) continue;

      var gapSum = 0.0;
      for (var i = 1; i < times.length; i++) {
        gapSum += times[i].difference(times[i - 1]).inHours / 24.0;
      }
      final avgGap = gapSum / (times.length - 1);

      final amounts = consumeAmounts[entry.key]!;
      final totalConsumed = amounts.fold<double>(0, (a, b) => a + b);
      final spanDays = times.last.difference(times.first).inHours / 24.0;
      final dailyUsage = spanDays <= 0 ? 0.0 : totalConsumed / spanDays;

      final stock = currentQuantityByProduct[entry.key];
      double? daysUntilEmpty;
      if (stock != null && dailyUsage > 0) {
        daysUntilEmpty = stock / dailyUsage;
      }

      forecasts.add(
        ConsumptionForecast(
          productId: entry.key,
          averageDaysBetweenConsumption: avgGap,
          estimatedDaysUntilEmpty: daysUntilEmpty,
          sampleSize: times.length,
        ),
      );
    }

    forecasts.sort(
      (a, b) => (a.estimatedDaysUntilEmpty ?? double.infinity).compareTo(
        b.estimatedDaysUntilEmpty ?? double.infinity,
      ),
    );
    return forecasts;
  }
}
