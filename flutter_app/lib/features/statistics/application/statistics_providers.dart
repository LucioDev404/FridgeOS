import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/services/statistics_calculator.dart';

/// A ranked consumption or waste row for the statistics list.
final class StatisticsLine {
  const StatisticsLine({
    required this.productId,
    required this.productName,
    required this.amount,
  });

  final String productId;
  final String productName;
  final double amount;
}

/// View model derived from [StatisticsSnapshot] with product names resolved.
final class StatisticsViewModel {
  const StatisticsViewModel({
    required this.consumptionTotal,
    required this.wasteTotal,
    required this.mostConsumed,
    required this.wasteByProduct,
  });

  final double consumptionTotal;
  final double wasteTotal;
  final List<StatisticsLine> mostConsumed;
  final List<StatisticsLine> wasteByProduct;

  bool get isEmpty => consumptionTotal == 0 && wasteTotal == 0;
}

final statisticsCalculatorProvider = Provider<StatisticsCalculator>(
  (ref) => const StatisticsCalculator(),
);

final _statisticsEventsProvider = StreamProvider(
  (ref) => ref.watch(inventoryRepositoryProvider).watchEvents(),
);

final _statisticsProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

/// Consumption and waste metrics joined with product names (FR-STAT-1/2/4).
final statisticsViewModelProvider = Provider<AsyncValue<StatisticsViewModel>>((
  ref,
) {
  final eventsAsync = ref.watch(_statisticsEventsProvider);
  final productsAsync = ref.watch(_statisticsProductsProvider);
  final calculator = ref.watch(statisticsCalculatorProvider);

  return eventsAsync.whenData((events) {
    final result = calculator.compute(events: events);
    final snapshot = result.valueOrNull;
    if (snapshot == null) {
      return const StatisticsViewModel(
        consumptionTotal: 0,
        wasteTotal: 0,
        mostConsumed: [],
        wasteByProduct: [],
      );
    }

    final products = {
      for (final product in productsAsync.value ?? const <Product>[])
        product.id: product,
    };

    List<StatisticsLine> rankedLines(Map<String, double> amounts) {
      final lines =
          amounts.entries
              .map(
                (entry) => StatisticsLine(
                  productId: entry.key,
                  productName: products[entry.key]?.name ?? entry.key,
                  amount: entry.value,
                ),
              )
              .toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));
      return lines;
    }

    return StatisticsViewModel(
      consumptionTotal: snapshot.consumptionTotal,
      wasteTotal: snapshot.wasteTotal,
      mostConsumed: rankedLines(snapshot.mostConsumed),
      wasteByProduct: rankedLines(snapshot.wasteByProduct),
    );
  });
});
