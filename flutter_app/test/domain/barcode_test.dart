import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';

void main() {
  group('Barcode', () {
    test('parses a valid EAN-13 with correct check digit', () {
      // 4006381333931 is a well-known valid EAN-13.
      final barcode = Barcode.tryParse('4006381333931');
      expect(barcode, isNotNull);
      expect(barcode!.format, BarcodeFormat.ean13);
      expect(barcode.value, '4006381333931');
    });

    test('parses a valid UPC-A (12 digits)', () {
      // 036000291452 is a canonical valid UPC-A.
      final barcode = Barcode.tryParse('036000291452');
      expect(barcode, isNotNull);
      expect(barcode!.format, BarcodeFormat.upcA);
    });

    test('parses a valid EAN-8', () {
      // 96385074 is a valid EAN-8.
      final barcode = Barcode.tryParse('96385074');
      expect(barcode, isNotNull);
      expect(barcode!.format, BarcodeFormat.ean8);
    });

    test('rejects an invalid check digit', () {
      expect(Barcode.tryParse('4006381333930'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(Barcode.tryParse('40063813339AB'), isNull);
      expect(Barcode.tryParse(' 4006381333931 '), isNotNull); // trims
    });

    test('rejects unsupported lengths', () {
      expect(Barcode.tryParse('12345'), isNull);
      expect(Barcode.tryParse('123456789012345'), isNull);
    });

    test('rejects null', () {
      expect(Barcode.tryParse(null), isNull);
    });

    test('parse throws FormatException on invalid input', () {
      expect(() => Barcode.parse('123'), throwsFormatException);
    });

    test('equality is by value and format', () {
      expect(Barcode.parse('96385074'), Barcode.parse('96385074'));
    });
  });
}
