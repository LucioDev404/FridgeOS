import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/features/barcode/application/scan_detection.dart';

void main() {
  group('firstValidBarcodeValue', () {
    test('returns the first valid EAN-13', () {
      expect(
        firstValidBarcodeValue(const ['not-a-code', '4006381333931', 'x']),
        '4006381333931',
      );
    });

    test('rejects invalid check digits and non-numeric payloads', () {
      expect(firstValidBarcodeValue(const ['4006381333930']), isNull);
      expect(firstValidBarcodeValue(const ['https://example.com']), isNull);
      expect(firstValidBarcodeValue(const [null, '']), isNull);
    });

    test('accepts EAN-8 and UPC-A', () {
      expect(firstValidBarcodeValue(const ['96385074']), '96385074');
      expect(firstValidBarcodeValue(const ['036000291452']), '036000291452');
    });
  });
}
