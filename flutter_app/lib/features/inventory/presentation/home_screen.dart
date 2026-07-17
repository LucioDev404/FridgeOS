import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_projection.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/add_item_sheet.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/inventory_tile.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Dashboard: glanceable counters plus a "needs attention" list of expired and
/// soon-to-expire items (docs/10-ui-guidelines.md §3, FR-EXP-*).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final linesAsync = ref.watch(inventoryLineItemsProvider);

    return linesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (lines) {
        if (lines.isEmpty) {
          return EmptyState(
            icon: Icons.kitchen_outlined,
            title: l10n.homeEmptyTitle,
            body: l10n.homeEmptyBody,
            action: FilledButton.icon(
              onPressed: () => showAddItemSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addProduct),
            ),
          );
        }
        return _Dashboard(lines: lines);
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.lines});

  final List<InventoryLineItem> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(homeSummaryProvider).value;
    final attention = lines
        .where((l) => l.status != ExpirationStatus.fresh)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (summary != null) _SummaryGrid(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.needsAttention,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/inventory'),
              child: Text(l10n.viewInventory),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (attention.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l10n.expiringEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final line in attention) InventoryTile(line: line),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final InventorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      _SummaryCard(
        label: l10n.summaryInStock,
        value: summary.totalItems,
        icon: Icons.inventory_2_outlined,
        color: scheme.primary,
      ),
      _SummaryCard(
        label: l10n.summaryExpiringSoon,
        value: summary.expiringSoon,
        icon: Icons.schedule,
        color: scheme.tertiary,
      ),
      _SummaryCard(
        label: l10n.summaryExpired,
        value: summary.expired,
        icon: Icons.warning_amber_rounded,
        color: scheme.error,
      ),
      _SummaryCard(
        label: l10n.summaryLowStock,
        value: summary.lowStock,
        icon: Icons.trending_down,
        color: scheme.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / AppSpacing.minTileWidth)
            .floor()
            .clamp(1, 4);
        const spacing = AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: tileWidth, child: card),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text('$value', style: theme.textTheme.headlineMedium),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
