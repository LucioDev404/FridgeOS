import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

void main() {
  group('Quantity', () {
    test('constructs a non-negative amount', () {
      final q = Quantity(2.5, MeasurementUnit.kilograms);
      expect(q.amount, 2.5);
      expect(q.unit, MeasurementUnit.kilograms);
      expect(q.isZero, isFalse);
    });

    test('zero factory', () {
      expect(Quantity.zero(MeasurementUnit.liters).isZero, isTrue);
    });

    test('rejects negative amounts', () {
      expect(() => Quantity(-1, MeasurementUnit.grams), throwsArgumentError);
    });

    test('rejects non-finite amounts', () {
      expect(
        () => Quantity(double.nan, MeasurementUnit.grams),
        throwsArgumentError,
      );
      expect(
        () => Quantity(double.infinity, MeasurementUnit.grams),
        throwsArgumentError,
      );
    });

    test('addition of same unit', () {
      final result =
          Quantity(1, MeasurementUnit.pieces) +
          Quantity(2, MeasurementUnit.pieces);
      expect(result, Quantity(3, MeasurementUnit.pieces));
    });

    test('subtraction of same unit', () {
      final result =
          Quantity(3, MeasurementUnit.pieces) -
          Quantity(2, MeasurementUnit.pieces);
      expect(result, Quantity(1, MeasurementUnit.pieces));
    });

    test('subtraction below zero throws', () {
      expect(
        () =>
            Quantity(1, MeasurementUnit.pieces) -
            Quantity(2, MeasurementUnit.pieces),
        throwsArgumentError,
      );
    });

    test('combining different units throws', () {
      expect(
        () =>
            Quantity(1, MeasurementUnit.grams) +
            Quantity(1, MeasurementUnit.kilograms),
        throwsArgumentError,
      );
    });

    test('equality is by amount and unit', () {
      expect(
        Quantity(1, MeasurementUnit.liters),
        Quantity(1, MeasurementUnit.liters),
      );
      expect(
        Quantity(1, MeasurementUnit.liters),
        isNot(Quantity(1, MeasurementUnit.milliliters)),
      );
    });
  });
}
