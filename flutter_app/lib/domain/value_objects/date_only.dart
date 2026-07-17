/// A calendar date without time-of-day or timezone.
///
/// Expiration is a calendar concept; storing a full timestamp would introduce
/// timezone drift (see docs/06-database-design.md §1). [DateOnly] is persisted
/// as an ISO `YYYY-MM-DD` string.
final class DateOnly implements Comparable<DateOnly> {
  /// Creates a date, throwing [ArgumentError] for an invalid calendar date.
  factory DateOnly(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Month must be 1..12');
    }
    final normalized = DateTime(year, month, day);
    if (normalized.month != month || normalized.day != day) {
      throw ArgumentError('Invalid date: $year-$month-$day');
    }
    return DateOnly._(year, month, day);
  }

  const DateOnly._(this.year, this.month, this.day);

  /// The calendar date of [dateTime] in its own timezone.
  factory DateOnly.fromDateTime(DateTime dateTime) =>
      DateOnly(dateTime.year, dateTime.month, dateTime.day);

  /// Parses an ISO `YYYY-MM-DD` string.
  factory DateOnly.parseIso(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw FormatException('Non-numeric date component', iso);
    }
    return DateOnly(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  /// ISO `YYYY-MM-DD` representation (zero-padded).
  String toIso() {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  /// Number of whole days from this date to [other] (positive when [other] is
  /// later). Uses UTC midnight to avoid DST arithmetic issues.
  int daysUntil(DateOnly other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return b.difference(a).inDays;
  }

  bool isBefore(DateOnly other) => compareTo(other) < 0;
  bool isAfter(DateOnly other) => compareTo(other) > 0;

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'DateOnly(${toIso()})';
}
