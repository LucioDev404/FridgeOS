import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';

/// A digest entry describing items that need attention in a notification.
final class ExpirationDigestEntry {
  const ExpirationDigestEntry({
    required this.productName,
    required this.status,
    this.daysToExpiry,
  });

  final String productName;
  final ExpirationStatus status;
  final int? daysToExpiry;
}

/// Schedules expiration digest notifications. Platform implementations may use
/// flutter_local_notifications; tests use [InMemoryNotificationScheduler].
abstract interface class NotificationScheduler {
  /// Computes and schedules a digest for [items] at [digestTime] (`HH:mm`).
  Future<Result<void>> scheduleExpirationDigest({
    required List<InventoryLineItem> items,
    required String digestTime,
  });

  /// Cancels all pending expiration digests.
  Future<Result<void>> cancelAll();
}

/// In-memory scheduler for unit tests (no platform plugins).
final class InMemoryNotificationScheduler implements NotificationScheduler {
  InMemoryNotificationScheduler();

  final List<ExpirationDigestEntry> scheduledEntries =
      <ExpirationDigestEntry>[];
  String? lastDigestTime;
  int cancelCount = 0;

  @override
  Future<Result<void>> scheduleExpirationDigest({
    required List<InventoryLineItem> items,
    required String digestTime,
  }) async {
    lastDigestTime = digestTime;
    scheduledEntries
      ..clear()
      ..addAll(computeDigestEntries(items));
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancelAll() async {
    cancelCount++;
    scheduledEntries.clear();
    lastDigestTime = null;
    return const Result.success(null);
  }
}

/// No-op scheduler for production stub until platform wiring lands.
final class StubNotificationScheduler implements NotificationScheduler {
  const StubNotificationScheduler();

  @override
  Future<Result<void>> scheduleExpirationDigest({
    required List<InventoryLineItem> items,
    required String digestTime,
  }) async => const Result.success(null);

  @override
  Future<Result<void>> cancelAll() async => const Result.success(null);
}

/// Pure helper: items that are expired or expiring soon.
List<ExpirationDigestEntry> computeDigestEntries(
  List<InventoryLineItem> items,
) {
  final entries = <ExpirationDigestEntry>[];
  for (final line in items) {
    if (line.status == ExpirationStatus.fresh) continue;
    entries.add(
      ExpirationDigestEntry(
        productName: line.product.name,
        status: line.status,
        daysToExpiry: line.daysToExpiry,
      ),
    );
  }
  entries.sort((a, b) {
    final aExpired = a.status == ExpirationStatus.expired ? 0 : 1;
    final bExpired = b.status == ExpirationStatus.expired ? 0 : 1;
    final byStatus = aExpired.compareTo(bExpired);
    if (byStatus != 0) return byStatus;
    final aDays = a.daysToExpiry ?? 999;
    final bDays = b.daysToExpiry ?? 999;
    return aDays.compareTo(bDays);
  });
  return entries;
}
