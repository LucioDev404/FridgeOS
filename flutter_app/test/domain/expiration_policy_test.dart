import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

void main() {
  const policy = ExpirationPolicy();
  final today = DateOnly(2026, 7, 17);

  group('ExpirationPolicy.classify', () {
    test('no expiration date is fresh', () {
      expect(
        policy.classify(expirationDate: null, today: today, windowDays: 3),
        ExpirationStatus.fresh,
      );
    });

    test('a past date is expired', () {
      expect(
        policy.classify(
          expirationDate: DateOnly(2026, 7, 16),
          today: today,
          windowDays: 3,
        ),
        ExpirationStatus.expired,
      );
    });

    test('today is expiring soon (boundary at 0 days)', () {
      expect(
        policy.classify(expirationDate: today, today: today, windowDays: 3),
        ExpirationStatus.expiringSoon,
      );
    });

    test('exactly at the window edge is expiring soon', () {
      expect(
        policy.classify(
          expirationDate: DateOnly(2026, 7, 20),
          today: today,
          windowDays: 3,
        ),
        ExpirationStatus.expiringSoon,
      );
    });

    test('beyond the window is fresh', () {
      expect(
        policy.classify(
          expirationDate: DateOnly(2026, 7, 21),
          today: today,
          windowDays: 3,
        ),
        ExpirationStatus.fresh,
      );
    });
  });

  group('ExpirationPolicy.daysUntilExpiry', () {
    test('returns null without a date', () {
      expect(policy.daysUntilExpiry(null, today), isNull);
    });

    test('returns signed day difference', () {
      expect(policy.daysUntilExpiry(DateOnly(2026, 7, 20), today), 3);
      expect(policy.daysUntilExpiry(DateOnly(2026, 7, 14), today), -3);
    });
  });
}
