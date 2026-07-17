import 'package:fridgeos/domain/value_objects/enums.dart';

/// A non-negative amount paired with a [MeasurementUnit].
///
/// Invariants (see docs/05-domain-model.md §3–4):
/// * amount is finite and `>= 0`;
/// * arithmetic returns new instances and never produces a negative amount;
/// * addition/subtraction is only allowed between the same unit.
final class Quantity {
  /// Creates a quantity, throwing [ArgumentError] for a negative or non-finite
  /// amount.
  factory Quantity(double amount, MeasurementUnit unit) {
    if (amount.isNaN || amount.isInfinite) {
      throw ArgumentError.value(amount, 'amount', 'Amount must be finite');
    }
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Amount must be >= 0');
    }
    return Quantity._(amount, unit);
  }

  const Quantity._(this.amount, this.unit);

  /// A zero amount in [unit].
  factory Quantity.zero(MeasurementUnit unit) => Quantity._(0, unit);

  final double amount;
  final MeasurementUnit unit;

  bool get isZero => amount == 0;

  /// Returns a new quantity with [delta] added. Throws [ArgumentError] when the
  /// units differ or the result would be negative.
  Quantity operator +(Quantity delta) {
    _assertSameUnit(delta);
    return Quantity(amount + delta.amount, unit);
  }

  /// Returns a new quantity with [delta] subtracted. Throws [ArgumentError]
  /// when the units differ or the result would be negative.
  Quantity operator -(Quantity delta) {
    _assertSameUnit(delta);
    return Quantity(amount - delta.amount, unit);
  }

  void _assertSameUnit(Quantity other) {
    if (other.unit != unit) {
      throw ArgumentError(
        'Cannot combine ${unit.wire} with ${other.unit.wire}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => 'Quantity($amount ${unit.wire})';
}
