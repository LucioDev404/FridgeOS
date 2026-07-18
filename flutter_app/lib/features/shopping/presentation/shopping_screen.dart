import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/shopping/application/shopping_actions.dart';
import 'package:fridgeos/features/shopping/application/shopping_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Shopping list (manual + auto-generated).
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addManual() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final actions = ref.read(shoppingActionsProvider);
    await runWithFeedback(context, actions.addManual(name: name));
    if (!mounted) return;
    _nameController.clear();
  }

  Future<void> _syncProposals() async {
    final actions = ref.read(shoppingActionsProvider);
    final itemsAsync = ref.read(_inventoryItemsProvider);
    final productsAsync = ref.read(_productsProvider);
    final items = itemsAsync.value;
    final products = productsAsync.value;
    if (items == null || products == null) return;

    final result = await actions.syncAutoProposals(
      items: items,
      products: products,
    );
    if (!mounted) return;
    if (result.isFailure) {
      showActionFailure(context, AppLocalizations.of(context).actionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final itemsAsync = ref.watch(pendingShoppingItemsProvider);
    final actions = ref.read(shoppingActionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: l10n.shoppingAddHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addManual(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(onPressed: _addManual, child: Text(l10n.add)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _syncProposals,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.shoppingRefreshProposals),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/shopping/export'),
                icon: const Icon(Icons.ios_share_outlined),
                label: Text(l10n.shoppingExport),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/shopping/qr-import'),
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(l10n.shoppingQrImport),
              ),
            ],
          ),
        ),
        const Divider(height: AppSpacing.lg),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.actionFailed)),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: l10n.shoppingEmptyTitle,
                  body: l10n.shoppingEmptyBody,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  return _ShoppingTile(item: items[index], actions: actions);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

final _inventoryItemsProvider = StreamProvider(
  (ref) => ref.watch(inventoryRepositoryProvider).watchActiveItems(),
);

final _productsProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

class _ShoppingTile extends StatelessWidget {
  const _ShoppingTile({required this.item, required this.actions});

  final ShoppingListItem item;
  final ShoppingActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quantity = item.quantity;

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (_) => runWithFeedback(context, actions.markDone(item)),
        ),
        title: Text(item.name),
        subtitle: quantity == null
            ? Text(
                item.origin == ShoppingItemOrigin.auto
                    ? l10n.shoppingOriginAuto
                    : l10n.shoppingOriginManual,
                style: theme.textTheme.bodySmall,
              )
            : Text(
                '${formatAmount(quantity.amount)} ${quantity.unit.label(l10n)}',
                style: theme.textTheme.bodySmall,
              ),
        trailing: IconButton(
          tooltip: l10n.shoppingDismiss,
          onPressed: () => runWithFeedback(context, actions.dismiss(item)),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
