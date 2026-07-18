import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/features/statistics/application/statistics_providers.dart';
import 'package:fridgeos/features/statistics/presentation/statistics_charts.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Nested statistics detail pages. Back navigation is owned by [ShellScaffold].
class StatisticsChartsPage extends ConsumerWidget {
  const StatisticsChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsViewModelProvider);
    final filter = ref.watch(statisticsLocationFilterProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          StatisticsCharts(
            stats: stats,
            filter: filter,
            onFilterChanged: (value) =>
                ref.read(statisticsLocationFilterProvider.notifier).set(value),
          ),
        ],
      ),
    );
  }
}

class StatisticsInsightsPage extends ConsumerWidget {
  const StatisticsInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsViewModelProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          StatisticsMetricTile(
            title: l10n.statisticsDailyUsage,
            value: formatAmount(stats.averageDailyUsage),
            icon: Icons.today_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsVelocity,
            value: formatAmount(stats.consumptionVelocity),
            icon: Icons.speed_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsOscillation,
            value: formatAmount(stats.inventoryOscillation),
            icon: Icons.waves_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsRestockFrequency,
            value: '${stats.restockFrequency}',
            icon: Icons.add_box_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsLowStockFrequency,
            value: '${stats.lowStockFrequency}',
            icon: Icons.warning_amber_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsWeeklyConsumption,
            value: formatAmount(
              stats.weeklyConsumption.values.fold<double>(0, (a, b) => a + b),
            ),
            icon: Icons.date_range_outlined,
          ),
          StatisticsMetricTile(
            title: l10n.statisticsMonthlyConsumption,
            value: formatAmount(
              stats.monthlyConsumption.values.fold<double>(0, (a, b) => a + b),
            ),
            icon: Icons.calendar_month_outlined,
          ),
        ],
      ),
    );
  }
}

class StatisticsProductsPage extends ConsumerWidget {
  const StatisticsProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsViewModelProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.statisticsMostConsumedSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in stats.mostConsumed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.productName),
              trailing: Text(formatAmount(line.amount)),
            ),
          if (stats.leastConsumed.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.statisticsLeastConsumedSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final line in stats.leastConsumed.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.productName),
                trailing: Text(formatAmount(line.amount)),
              ),
          ],
          if (stats.wasteByProduct.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.statisticsWasteSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final line in stats.wasteByProduct)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.productName),
                trailing: Text(formatAmount(line.amount)),
              ),
          ],
        ],
      ),
    );
  }
}

class StatisticsForecastPage extends ConsumerWidget {
  const StatisticsForecastPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsViewModelProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (stats) {
        if (stats.forecasts.isEmpty) {
          return Center(child: Text(l10n.statisticsEmptyBody));
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final forecast in stats.forecasts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timeline_outlined),
                title: Text(
                  forecast.estimatedDaysUntilEmpty == null
                      ? l10n.forecastCadence(
                          forecast.productName,
                          forecast.averageDaysBetweenConsumption.round().clamp(
                            1,
                            9999,
                          ),
                        )
                      : l10n.forecastRunOut(
                          forecast.productName,
                          forecast.estimatedDaysUntilEmpty!.round().clamp(
                            1,
                            9999,
                          ),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}
