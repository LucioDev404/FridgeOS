import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/application/inventory_actions.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_projection.dart';

/// Application/presentation providers for the inventory feature.

/// Use-case facade exposed to controllers/widgets.
final inventoryActionsProvider = Provider<InventoryActions>(
  (ref) => InventoryActions(
    products: ref.watch(productRepositoryProvider),
    inventory: ref.watch(inventoryRepositoryProvider),
    mutations: ref.watch(inventoryMutationServiceProvider),
    sanitizer: ref.watch(inputSanitizerProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// "Today" as a calendar date in the device's local timezone. Overridable in
/// tests for deterministic expiration classification.
final todayProvider = Provider<DateOnly>(
  (ref) => DateOnly.fromDateTime(ref.watch(clockProvider).nowUtc().toLocal()),
);

/// Window (in days) before expiry that flags an item as "expiring soon".
final expiringSoonWindowProvider = Provider<int>((ref) {
  return ref
      .watch(userPreferencesProvider)
      .maybeWhen(
        data: (prefs) => prefs.expiringSoonWindowDays,
        orElse: () => 3,
      );
});

final _productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

final locationsProvider = StreamProvider<List<Location>>(
  (ref) => ref.watch(locationRepositoryProvider).watchAll(),
);

final _inventoryItemsProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchActiveItems(),
);

/// Text query filtering the inventory list by product name/brand.
final inventorySearchQueryProvider =
    NotifierProvider<InventorySearchQueryNotifier, String>(
      InventorySearchQueryNotifier.new,
    );

/// Notifier backing [inventorySearchQueryProvider].
class InventorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Optional location filter (`null` = all locations).
final inventoryLocationFilterProvider =
    NotifierProvider<InventoryLocationFilterNotifier, String?>(
      InventoryLocationFilterNotifier.new,
    );

/// Notifier backing [inventoryLocationFilterProvider].
class InventoryLocationFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? locationId) => state = locationId;
}

/// Optional category filter (`null` = all categories). FR-INV-6.
final inventoryCategoryFilterProvider =
    NotifierProvider<InventoryCategoryFilterNotifier, FoodCategory?>(
      InventoryCategoryFilterNotifier.new,
    );

/// Notifier backing [inventoryCategoryFilterProvider].
class InventoryCategoryFilterNotifier extends Notifier<FoodCategory?> {
  @override
  FoodCategory? build() => null;

  void select(FoodCategory? category) => state = category;
}

/// All active stock, joined with product/location and classified by expiration.
final inventoryLineItemsProvider =
    Provider<AsyncValue<List<InventoryLineItem>>>((ref) {
      final itemsAsync = ref.watch(_inventoryItemsProvider);
      final productsAsync = ref.watch(_productsProvider);
      final locationsAsync = ref.watch(locationsProvider);
      final policy = ref.watch(expirationPolicyProvider);
      final today = ref.watch(todayProvider);
      final window = ref.watch(expiringSoonWindowProvider);

      return itemsAsync.whenData((items) {
        final products = productsAsync.value;
        final locations = locationsAsync.value;
        if (products == null || locations == null) {
          return const <InventoryLineItem>[];
        }
        return buildInventoryLineItems(
          items: items,
          products: products,
          locations: locations,
          policy: policy,
          today: today,
          window: window,
        );
      });
    });

/// [inventoryLineItemsProvider] with search / location / category filters.
/// Search matches name, brand, and barcode (FR-INV-5/6/9).
final filteredInventoryProvider = Provider<AsyncValue<List<InventoryLineItem>>>(
  (ref) {
    final all = ref.watch(inventoryLineItemsProvider);
    final query = ref.watch(inventorySearchQueryProvider).trim().toLowerCase();
    final locationFilter = ref.watch(inventoryLocationFilterProvider);
    final categoryFilter = ref.watch(inventoryCategoryFilterProvider);

    return all.whenData((lines) {
      return lines.where((line) {
        if (locationFilter != null && line.location.id != locationFilter) {
          return false;
        }
        if (categoryFilter != null && line.product.category != categoryFilter) {
          return false;
        }
        if (query.isEmpty) return true;
        final barcode = line.product.barcode?.value ?? '';
        final haystack =
            '${line.product.name} ${line.product.brand ?? ''} $barcode'
                .toLowerCase();
        return haystack.contains(query);
      }).toList();
    });
  },
);

/// Glanceable dashboard counters derived from the joined inventory.
final homeSummaryProvider = Provider<AsyncValue<InventorySummary>>((ref) {
  return ref.watch(inventoryLineItemsProvider).whenData(computeSummary);
});
