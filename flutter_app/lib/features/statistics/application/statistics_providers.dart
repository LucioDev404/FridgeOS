import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/services/consumption_forecast_service.dart';
import 'package:fridgeos/domain/services/statistics_calculator.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

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
    required this.leastConsumed,
    required this.wasteByProduct,
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
    required this.forecasts,
  });

  final double consumptionTotal;
  final double wasteTotal;
  final List<StatisticsLine> mostConsumed;
  final List<StatisticsLine> leastConsumed;
  final List<StatisticsLine> wasteByProduct;
  final Map<String, double> dailyConsumption;
  final Map<String, double> weeklyConsumption;
  final Map<String, double> monthlyConsumption;
  final double averageDailyUsage;
  final double consumptionVelocity;
  final double inventoryOscillation;
  final int restockFrequency;
  final int lowStockFrequency;
  final Map<String, double> dailyStockChanges;
  final Map<String, double> consumptionByLocation;
  final Map<String, double> stockByLocation;
  final List<ForecastLine> forecasts;

  bool get isEmpty =>
      consumptionTotal == 0 &&
      wasteTotal == 0 &&
      dailyStockChanges.isEmpty &&
      forecasts.isEmpty;
}

final class ForecastLine {
  const ForecastLine({
    required this.productId,
    required this.productName,
    required this.averageDaysBetweenConsumption,
    required this.estimatedDaysUntilEmpty,
  });

  final String productId;
  final String productName;
  final double averageDaysBetweenConsumption;
  final double? estimatedDaysUntilEmpty;
}

final statisticsCalculatorProvider = Provider<StatisticsCalculator>(
  (ref) => const StatisticsCalculator(),
);

final consumptionForecastServiceProvider = Provider<ConsumptionForecastService>(
  (ref) => const ConsumptionForecastService(),
);

/// Location-type filter for statistics charts (`null` = all).
final statisticsLocationFilterProvider =
    NotifierProvider<StatisticsLocationFilterNotifier, LocationType?>(
      StatisticsLocationFilterNotifier.new,
    );

class StatisticsLocationFilterNotifier extends Notifier<LocationType?> {
  @override
  LocationType? build() => null;

  void set(LocationType? value) => state = value;
}

final _statisticsEventsProvider = StreamProvider(
  (ref) => ref.watch(inventoryRepositoryProvider).watchEvents(),
);

final _statisticsProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

final _statisticsLocationsProvider = StreamProvider<List<Location>>(
  (ref) => ref.watch(locationRepositoryProvider).watchAll(),
);

final _statisticsItemsProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchActiveItems(),
);

/// Consumption and waste metrics joined with product names (FR-STAT-1/2/4).
final statisticsViewModelProvider = Provider<AsyncValue<StatisticsViewModel>>((
  ref,
) {
  final eventsAsync = ref.watch(_statisticsEventsProvider);
  final productsAsync = ref.watch(_statisticsProductsProvider);
  final locationsAsync = ref.watch(_statisticsLocationsProvider);
  final itemsAsync = ref.watch(_statisticsItemsProvider);
  final filter = ref.watch(statisticsLocationFilterProvider);
  final calculator = ref.watch(statisticsCalculatorProvider);
  final forecastService = ref.watch(consumptionForecastServiceProvider);

  return eventsAsync.whenData((events) {
    final locations = locationsAsync.value ?? const <Location>[];
    final locationTypeById = {
      for (final location in locations) location.id: location.type,
    };

    final result = calculator.compute(
      events: events,
      locationFilter: filter,
      locationTypeById: locationTypeById,
    );
    final snapshot = result.valueOrNull;
    if (snapshot == null) {
      return const StatisticsViewModel(
        consumptionTotal: 0,
        wasteTotal: 0,
        mostConsumed: [],
        leastConsumed: [],
        wasteByProduct: [],
        dailyConsumption: {},
        weeklyConsumption: {},
        monthlyConsumption: {},
        averageDailyUsage: 0,
        consumptionVelocity: 0,
        inventoryOscillation: 0,
        restockFrequency: 0,
        lowStockFrequency: 0,
        dailyStockChanges: {},
        consumptionByLocation: {},
        stockByLocation: {},
        forecasts: [],
      );
    }

    final products = {
      for (final product in productsAsync.value ?? const <Product>[])
        product.id: product,
    };

    final locationNames = {
      for (final location in locations) location.id: location.name,
    };

    List<StatisticsLine> rankedLines(
      Map<String, double> amounts, {
      bool ascending = false,
    }) {
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
            ..sort(
              (a, b) => ascending
                  ? a.amount.compareTo(b.amount)
                  : b.amount.compareTo(a.amount),
            );
      return lines;
    }

    Map<String, double> namedLocationMap(Map<String, double> source) => {
      for (final entry in source.entries)
        locationNames[entry.key] ?? entry.key: entry.value,
    };

    final quantityByProduct = <String, double>{};
    for (final item in itemsAsync.value ?? const <InventoryItem>[]) {
      quantityByProduct[item.productId] =
          (quantityByProduct[item.productId] ?? 0) + item.quantity.amount;
    }

    final forecasts = forecastService
        .forecast(events: events, currentQuantityByProduct: quantityByProduct)
        .map(
          (f) => ForecastLine(
            productId: f.productId,
            productName: products[f.productId]?.name ?? f.productId,
            averageDaysBetweenConsumption: f.averageDaysBetweenConsumption,
            estimatedDaysUntilEmpty: f.estimatedDaysUntilEmpty,
          ),
        )
        .toList();

    return StatisticsViewModel(
      consumptionTotal: snapshot.consumptionTotal,
      wasteTotal: snapshot.wasteTotal,
      mostConsumed: rankedLines(snapshot.mostConsumed),
      leastConsumed: rankedLines(snapshot.leastConsumed, ascending: true),
      wasteByProduct: rankedLines(snapshot.wasteByProduct),
      dailyConsumption: snapshot.dailyConsumption,
      weeklyConsumption: snapshot.weeklyConsumption,
      monthlyConsumption: snapshot.monthlyConsumption,
      averageDailyUsage: snapshot.averageDailyUsage,
      consumptionVelocity: snapshot.consumptionVelocity,
      inventoryOscillation: snapshot.inventoryOscillation,
      restockFrequency: snapshot.restockFrequency,
      lowStockFrequency: snapshot.lowStockFrequency,
      dailyStockChanges: snapshot.dailyStockChanges,
      consumptionByLocation: namedLocationMap(snapshot.consumptionByLocation),
      stockByLocation: namedLocationMap(snapshot.stockByLocation),
      forecasts: forecasts,
    );
  });
});
