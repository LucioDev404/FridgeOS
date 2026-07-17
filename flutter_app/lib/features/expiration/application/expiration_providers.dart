import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/expiration/application/notification_scheduler.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => const StubNotificationScheduler(),
);

/// User preferences stream (singleton row).
final userPreferencesProvider = StreamProvider(
  (ref) => ref.watch(preferencesRepositoryProvider).watch(),
);

/// Expiring/expired inventory lines, grouped: expired first, then expiring soon.
final expiringLineItemsProvider = Provider<AsyncValue<ExpiringLineItems>>((
  ref,
) {
  return ref.watch(inventoryLineItemsProvider).whenData((lines) {
    final expired = <InventoryLineItem>[];
    final expiringSoon = <InventoryLineItem>[];
    for (final line in lines) {
      switch (line.status) {
        case ExpirationStatus.expired:
          expired.add(line);
        case ExpirationStatus.expiringSoon:
          expiringSoon.add(line);
        case ExpirationStatus.fresh:
          break;
      }
    }
    return ExpiringLineItems(expired: expired, expiringSoon: expiringSoon);
  });
});

/// Grouped expiring inventory for the expiration screen.
final class ExpiringLineItems {
  const ExpiringLineItems({required this.expired, required this.expiringSoon});

  final List<InventoryLineItem> expired;
  final List<InventoryLineItem> expiringSoon;

  bool get isEmpty => expired.isEmpty && expiringSoon.isEmpty;
  int get totalCount => expired.length + expiringSoon.length;
}
