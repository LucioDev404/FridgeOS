import 'package:fridgeos/domain/value_objects/barcode.dart';

/// Extracts the first domain-valid commercial barcode from raw scanner values.
///
/// Scanner plugins may emit QR payloads and other symbologies; FridgeOS only
/// accepts EAN-8 / UPC-A / EAN-13 with a valid check digit (never trust raw
/// camera output — docs/08-threat-model.md).
String? firstValidBarcodeValue(Iterable<String?> rawValues) {
  for (final raw in rawValues) {
    if (raw == null) continue;
    final barcode = Barcode.tryParse(raw);
    if (barcode != null) return barcode.value;
  }
  return null;
}
