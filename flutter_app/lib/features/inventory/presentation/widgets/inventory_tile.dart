import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/edit_product_sheet.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/expiration_badge.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/move_location_dialog.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/set_quantity_dialog.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

enum _ItemMenuAction { edit, move, markUsed, throwAway, remove }

/// A single inventory row: product identity, location, expiration/low-stock
/// badges, an inline quantity stepper and an overflow menu of item actions.
class InventoryTile extends ConsumerWidget {
  const InventoryTile({required this.line, super.key});

  final InventoryLineItem line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final product = line.product;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    _subtitle(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (line.item.expirationDate != null)
                        ExpirationBadge(
                          status: line.status,
                          daysToExpiry: line.daysToExpiry,
                        ),
                      if (line.isBelowThreshold) _LowStockChip(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _QuantityStepper(line: line),
            PopupMenuButton<_ItemMenuAction>(
              onSelected: (action) => _onMenu(context, ref, action),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ItemMenuAction.edit,
                  child: Text(l10n.editProduct),
                ),
                PopupMenuItem(
                  value: _ItemMenuAction.move,
                  child: Text(l10n.moveTo),
                ),
                PopupMenuItem(
                  value: _ItemMenuAction.markUsed,
                  child: Text(l10n.markAsUsed),
                ),
                PopupMenuItem(
                  value: _ItemMenuAction.throwAway,
                  child: Text(l10n.throwAway),
                ),
                PopupMenuItem(
                  value: _ItemMenuAction.remove,
                  child: Text(l10n.removeItem),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final brand = line.product.brand;
    final location = line.location.name;
    return brand == null || brand.isEmpty ? location : '$brand · $location';
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _ItemMenuAction action,
  ) async {
    final actions = ref.read(inventoryActionsProvider);
    switch (action) {
      case _ItemMenuAction.edit:
        await showEditProductSheet(context, line: line);
      case _ItemMenuAction.move:
        final target = await showMoveLocationDialog(
          context,
          currentLocationId: line.location.id,
        );
        if (target == null || !context.mounted) return;
        await runWithFeedback(
          context,
          actions.move(item: line.item, toLocationId: target),
        );
      case _ItemMenuAction.markUsed:
        await runWithFeedback(
          context,
          actions.consume(item: line.item, amount: line.item.quantity.amount),
        );
      case _ItemMenuAction.throwAway:
        await runWithFeedback(
          context,
          actions.discard(item: line.item, amount: line.item.quantity.amount),
        );
      case _ItemMenuAction.remove:
        await runWithFeedback(context, actions.remove(item: line.item));
    }
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.line});

  final InventoryLineItem line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(inventoryActionsProvider);
    final unit = line.item.quantity.unit;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.decrease,
          onPressed: () => runWithFeedback(
            context,
            actions.adjust(item: line.item, delta: -1),
          ),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        InkWell(
          onTap: () => _editQuantity(context, actions),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              '${formatAmount(line.item.quantity.amount)} ${unit.label(l10n)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.increase,
          onPressed: () => runWithFeedback(
            context,
            actions.adjust(item: line.item, delta: 1),
          ),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Future<void> _editQuantity(
    BuildContext context,
    InventoryActions actions,
  ) async {
    final target = await showSetQuantityDialog(
      context,
      current: line.item.quantity.amount,
      unit: line.item.quantity.unit,
    );
    if (target == null || !context.mounted) return;
    await runWithFeedback(
      context,
      actions.setQuantity(item: line.item, targetAmount: target),
    );
  }
}

class _LowStockChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        l10n.lowStock,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
