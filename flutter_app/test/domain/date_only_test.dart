import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';

void main() {
  group('DateOnly', () {
    test('round-trips ISO format', () {
      final d = DateOnly(2026, 7, 5);
      expect(d.toIso(), '2026-07-05');
      expect(DateOnly.parseIso('2026-07-05'), d);
    });

    test('rejects invalid calendar dates', () {
      expect(() => DateOnly(2026, 2, 30), throwsArgumentError);
      expect(() => DateOnly(2026, 13, 1), throwsArgumentError);
    });

    test('rejects malformed ISO strings', () {
      expect(() => DateOnly.parseIso('2026/07/05'), throwsFormatException);
      expect(() => DateOnly.parseIso('2026-07'), throwsFormatException);
      expect(() => DateOnly.parseIso('x-07-05'), throwsFormatException);
    });

    test('daysUntil computes signed difference', () {
      expect(DateOnly(2026, 1, 1).daysUntil(DateOnly(2026, 1, 4)), 3);
      expect(DateOnly(2026, 1, 4).daysUntil(DateOnly(2026, 1, 1)), -3);
      expect(DateOnly(2026, 1, 1).daysUntil(DateOnly(2026, 1, 1)), 0);
    });

    test('crosses month/year boundaries correctly', () {
      expect(DateOnly(2025, 12, 31).daysUntil(DateOnly(2026, 1, 1)), 1);
    });

    test('comparison operators', () {
      expect(DateOnly(2026, 1, 1).isBefore(DateOnly(2026, 1, 2)), isTrue);
      expect(DateOnly(2026, 1, 2).isAfter(DateOnly(2026, 1, 1)), isTrue);
    });

    test('fromDateTime keeps the calendar date', () {
      final d = DateOnly.fromDateTime(DateTime(2026, 3, 9, 23, 59));
      expect(d, DateOnly(2026, 3, 9));
    });
  });
}
