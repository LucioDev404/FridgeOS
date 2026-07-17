import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Pure policy that classifies expiration status and computes days-to-expiry
/// (see FR-EXP-4, docs/05-domain-model.md §5). Deterministic given the item's
/// expiration date and a reference "today".
final class ExpirationPolicy {
  const ExpirationPolicy();

  /// Days from [today] until [expirationDate]. Negative when already past;
  /// `null` when the item has no expiration date.
  int? daysUntilExpiry(DateOnly? expirationDate, DateOnly today) {
    if (expirationDate == null) return null;
    return today.daysUntil(expirationDate);
  }

  /// Classifies an item's expiration status.
  ///
  /// * no date -> [ExpirationStatus.fresh];
  /// * before today -> [ExpirationStatus.expired];
  /// * within `[today, today + windowDays]` -> [ExpirationStatus.expiringSoon];
  /// * otherwise -> [ExpirationStatus.fresh].
  ExpirationStatus classify({
    required DateOnly? expirationDate,
    required DateOnly today,
    required int windowDays,
  }) {
    final days = daysUntilExpiry(expirationDate, today);
    if (days == null) return ExpirationStatus.fresh;
    if (days < 0) return ExpirationStatus.expired;
    if (days <= windowDays) return ExpirationStatus.expiringSoon;
    return ExpirationStatus.fresh;
  }
}
