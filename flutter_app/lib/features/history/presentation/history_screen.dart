import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/history/application/history_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Immutable event history (FR-HIST-1..4). Most recent first.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final linesAsync = ref.watch(historyLinesProvider);
    final typeFilter = ref.watch(historyEventTypeFilterProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.allEvents),
                selected: typeFilter == null,
                onSelected: (_) => ref
                    .read(historyEventTypeFilterProvider.notifier)
                    .select(null),
              ),
              for (final type in InventoryEventType.values) ...[
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text(type.label(l10n)),
                  selected: typeFilter == type,
                  onSelected: (_) => ref
                      .read(historyEventTypeFilterProvider.notifier)
                      .select(type),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: linesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.actionFailed)),
            data: (lines) {
              if (lines.isEmpty) {
                return EmptyState(
                  icon: Icons.history_outlined,
                  title: l10n.historyEmptyTitle,
                  body: l10n.historyEmptyBody,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: lines.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final line = lines[index];
                  final event = line.event;
                  final theme = Theme.of(context);
                  final subtitle = _subtitle(l10n, event);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(_iconFor(event.type)),
                    ),
                    title: Text(
                      line.productName ?? l10n.unknownProduct,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        event.type.label(l10n),
                        ?subtitle,
                        dateFormat.format(event.occurredAt.toLocal()),
                      ].join(' · '),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String? _subtitle(AppLocalizations l10n, InventoryEvent event) {
    final delta = event.quantityDelta;
    if (delta == null) return null;
    final formatted = formatAmount(delta.abs());
    if (delta > 0) return l10n.historyDeltaPlus(formatted);
    if (delta < 0) return l10n.historyDeltaMinus(formatted);
    return null;
  }

  IconData _iconFor(InventoryEventType type) => switch (type) {
    InventoryEventType.addProduct => Icons.add_circle_outline,
    InventoryEventType.removeProduct => Icons.remove_circle_outline,
    InventoryEventType.updateQuantity => Icons.tune,
    InventoryEventType.changeLocation => Icons.swap_horiz,
    InventoryEventType.consume => Icons.restaurant_outlined,
    InventoryEventType.discard => Icons.delete_outline,
  };
}
