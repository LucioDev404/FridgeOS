import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/expiration_badge.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Expiring-soon and expired items grouped by urgency.
class ExpiringScreen extends ConsumerWidget {
  const ExpiringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(expiringLineItemsProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (groups) {
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.schedule_outlined,
            title: l10n.expiringEmptyTitle,
            body: l10n.expiringEmptyBody,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (groups.expired.isNotEmpty) ...[
              _SectionHeader(title: l10n.sectionExpired),
              ...groups.expired.map(
                (line) => _ExpiringTile(line: line, key: ValueKey(line.id)),
              ),
            ],
            if (groups.expiringSoon.isNotEmpty) ...[
              if (groups.expired.isNotEmpty)
                const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: l10n.sectionExpiringSoon),
              ...groups.expiringSoon.map(
                (line) => _ExpiringTile(line: line, key: ValueKey(line.id)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ExpiringTile extends ConsumerWidget {
  const _ExpiringTile({required this.line, super.key});

  final InventoryLineItem line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actions = ref.read(inventoryActionsProvider);
    final product = line.product;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line.location.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ExpirationBadge(
                    status: line.status,
                    daysToExpiry: line.daysToExpiry,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.markAsUsed,
              onPressed: () => runWithFeedback(
                context,
                actions.consume(
                  item: line.item,
                  amount: line.item.quantity.amount,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline),
            ),
            IconButton(
              tooltip: l10n.throwAway,
              onPressed: () => runWithFeedback(
                context,
                actions.discard(
                  item: line.item,
                  amount: line.item.quantity.amount,
                ),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
