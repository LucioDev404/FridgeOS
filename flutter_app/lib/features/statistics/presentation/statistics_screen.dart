import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/features/statistics/application/statistics_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Statistics hub. Detail pages live on nested routes so the shell AppBar can
/// show a Back button and Android system back remains consistent.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statisticsViewModelProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (stats) {
        if (stats.isEmpty) {
          return EmptyState(
            icon: Icons.insights_outlined,
            title: l10n.statisticsEmptyTitle,
            body: l10n.statisticsEmptyBody,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              l10n.statisticsTotalsSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant_outlined),
              title: Text(l10n.statisticsConsumptionTotal),
              trailing: Text(_fmt(stats.consumptionTotal)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.statisticsWasteTotal),
              trailing: Text(_fmt(stats.wasteTotal)),
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.statisticsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavTile(
              icon: Icons.show_chart,
              title: l10n.statisticsChartsSection,
              onTap: () => context.push('/statistics/charts'),
            ),
            _NavTile(
              icon: Icons.insights_outlined,
              title: l10n.statisticsMetricsSection,
              onTap: () => context.push('/statistics/insights'),
            ),
            _NavTile(
              icon: Icons.category_outlined,
              title: l10n.statisticsMostConsumedSection,
              onTap: () => context.push('/statistics/products'),
            ),
            _NavTile(
              icon: Icons.timeline_outlined,
              title: l10n.forecastSection,
              onTap: () => context.push('/statistics/forecast'),
            ),
          ],
        );
      },
    );
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
