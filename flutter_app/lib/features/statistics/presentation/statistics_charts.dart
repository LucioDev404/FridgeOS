import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/statistics/application/statistics_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Tablet-friendly chart block used by the statistics screen.
class StatisticsCharts extends StatelessWidget {
  const StatisticsCharts({
    required this.stats,
    required this.filter,
    required this.onFilterChanged,
    super.key,
  });

  final StatisticsViewModel stats;
  final LocationType? filter;
  final ValueChanged<LocationType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.statisticsChartsSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.statisticsFilterAll),
              selected: filter == null,
              onSelected: (_) => onFilterChanged(null),
            ),
            for (final type in LocationType.values)
              ChoiceChip(
                label: Text(_labelFor(type, l10n)),
                selected: filter == type,
                onSelected: (_) => onFilterChanged(type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChartCard(
          title: l10n.chartConsumptionTrend,
          child: _LineChart(values: _sortedMap(stats.dailyConsumption)),
        ),
        _ChartCard(
          title: l10n.chartDailyStockChanges,
          child: _BarChart(values: _sortedMap(stats.dailyStockChanges)),
        ),
        _ChartCard(
          title: l10n.chartInventoryEvolution,
          child: _LineChart(values: _cumulative(stats.dailyStockChanges)),
        ),
        _ChartCard(
          title: l10n.chartConsumptionByLocation,
          child: _BarChart(
            values: {
              for (final e in stats.consumptionByLocation.entries)
                e.key: e.value,
            },
          ),
        ),
        _ChartCard(
          title: l10n.chartStockDistribution,
          child: _BarChart(
            values: {
              for (final e in stats.stockByLocation.entries) e.key: e.value,
            },
          ),
        ),
      ],
    );
  }

  String _labelFor(LocationType type, AppLocalizations l10n) => switch (type) {
    LocationType.refrigerator => l10n.typeRefrigerator,
    LocationType.freezer => l10n.typeFreezer,
    LocationType.pantry => l10n.typePantry,
  };

  Map<String, double> _sortedMap(Map<String, double> source) {
    final keys = source.keys.toList()..sort();
    return {for (final k in keys) k: source[k]!};
  }

  Map<String, double> _cumulative(Map<String, double> daily) {
    final sorted = _sortedMap(daily);
    var running = 0.0;
    final out = <String, double>{};
    for (final entry in sorted.entries) {
      running += entry.value;
      out[entry.key] = running;
    }
    return out;
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('—'));
    }
    final entries = values.entries.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].value),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (entries.length / 4).clamp(1, 999).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox.shrink();
                }
                final label = entries[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label.length > 7 ? label.substring(5) : label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('—'));
    }
    final entries = values.entries.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox.shrink();
                }
                final label = entries[i].key;
                final short = label.length > 8 ? label.substring(0, 8) : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    short,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.abs(),
                  width: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Compact metric row for numeric insights.
class StatisticsMetricTile extends StatelessWidget {
  const StatisticsMetricTile({
    required this.title,
    required this.value,
    this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon ?? Icons.insights_outlined),
      title: Text(title),
      trailing: Text(value),
    );
  }
}

String formatMetric(double value) => formatAmount(value);
