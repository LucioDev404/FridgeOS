import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// A history row with enough context to render without further lookups.
final class HistoryLine {
  const HistoryLine({required this.event, required this.productName});

  final InventoryEvent event;
  final String? productName;
}

final _eventsProvider = StreamProvider<List<InventoryEvent>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchEvents(),
);

final _productsForHistoryProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

/// Optional filter by event type (`null` = all).
final historyEventTypeFilterProvider =
    NotifierProvider<HistoryEventTypeFilterNotifier, InventoryEventType?>(
      HistoryEventTypeFilterNotifier.new,
    );

class HistoryEventTypeFilterNotifier extends Notifier<InventoryEventType?> {
  @override
  InventoryEventType? build() => null;

  void select(InventoryEventType? type) => state = type;
}

/// Chronological history joined with product names (FR-HIST-1..4).
final historyLinesProvider = Provider<AsyncValue<List<HistoryLine>>>((ref) {
  final eventsAsync = ref.watch(_eventsProvider);
  final productsAsync = ref.watch(_productsForHistoryProvider);
  final typeFilter = ref.watch(historyEventTypeFilterProvider);

  return eventsAsync.whenData((events) {
    final products = {
      for (final p in productsAsync.value ?? const <Product>[]) p.id: p,
    };
    final filtered = typeFilter == null
        ? events
        : events.where((e) => e.type == typeFilter).toList();
    return [
      for (final event in filtered)
        HistoryLine(
          event: event,
          productName: event.productId == null
              ? null
              : products[event.productId!]?.name,
        ),
    ];
  });
});
