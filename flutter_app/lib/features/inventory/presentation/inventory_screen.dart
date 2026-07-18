import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/add_item_sheet.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/inventory_tile.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Inventory list with search and per-location filtering (FR-INV-6/9/10).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allAsync = ref.watch(inventoryLineItemsProvider);
    final filteredAsync = ref.watch(filteredInventoryProvider);
    final hasAnyItems = (allAsync.value ?? const []).isNotEmpty;

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
                  controller: _searchController,
                  onChanged: (value) => ref
                      .read(inventorySearchQueryProvider.notifier)
                      .set(value),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => showAddItemSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addProduct),
              ),
            ],
          ),
        ),
        const _LocationFilterBar(),
        const _CategoryFilterBar(),
        const Divider(height: 1),
        Expanded(
          child: filteredAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.actionFailed)),
            data: (lines) {
              if (lines.isEmpty) {
                if (!hasAnyItems) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.inventoryEmptyTitle,
                    body: l10n.inventoryEmptyBody,
                    action: FilledButton.icon(
                      onPressed: () => showAddItemSheet(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addProduct),
                    ),
                  );
                }
                return Center(
                  child: Text(
                    l10n.inventoryEmptyBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: lines.length,
                itemBuilder: (context, index) =>
                    InventoryTile(line: lines[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocationFilterBar extends ConsumerWidget {
  const _LocationFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locations = ref.watch(locationsProvider).value ?? const [];
    final selected = ref.watch(inventoryLocationFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.allLocations),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(inventoryLocationFilterProvider.notifier).select(null),
          ),
          for (final location in locations) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(location.name),
              selected: selected == location.id,
              onSelected: (_) => ref
                  .read(inventoryLocationFilterProvider.notifier)
                  .select(location.id),
            ),
          ],
          const SizedBox(width: AppSpacing.md),
          TextButton.icon(
            onPressed: () => context.push('/locations'),
            icon: const Icon(Icons.tune),
            label: Text(l10n.manageLocations),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(inventoryCategoryFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.allCategories),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(inventoryCategoryFilterProvider.notifier).select(null),
          ),
          for (final category in FoodCategory.values) ...[
            const SizedBox(width: AppSpacing.sm),
            FilterChip(
              label: Text(category.label(l10n)),
              selected: selected == category,
              onSelected: (_) => ref
                  .read(inventoryCategoryFilterProvider.notifier)
                  .select(category),
            ),
          ],
        ],
      ),
    );
  }
}
