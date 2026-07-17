/// Recognized barcode symbologies for commercial food products.
enum BarcodeFormat {
  ean8('EAN_8', 8),
  upcA('UPC_A', 12),
  ean13('EAN_13', 13);

  const BarcodeFormat(this.wire, this.length);

  final String wire;
  final int length;
}

/// A validated EAN-8 / UPC-A / EAN-13 barcode.
///
/// A [Barcode] cannot be constructed in an invalid state: the value must be
/// numeric, of a supported length, and carry a correct GTIN check digit
/// (see docs/05-domain-model.md §3 and docs/08-threat-model.md — barcode data is
/// never trusted; it is only ever used as a normalized lookup key).
final class Barcode {
  const Barcode._(this.value, this.format);

  /// Normalized digit string (no whitespace).
  final String value;

  /// The detected symbology.
  final BarcodeFormat format;

  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// Attempts to parse [input]; returns `null` when it is not a valid barcode.
  static Barcode? tryParse(String? input) {
    if (input == null) return null;
    final normalized = input.trim();
    if (!_digitsOnly.hasMatch(normalized)) return null;

    final format = switch (normalized.length) {
      8 => BarcodeFormat.ean8,
      12 => BarcodeFormat.upcA,
      13 => BarcodeFormat.ean13,
      _ => null,
    };
    if (format == null) return null;
    if (!_hasValidCheckDigit(normalized)) return null;

    return Barcode._(normalized, format);
  }

  /// Parses [input], throwing [FormatException] when invalid.
  static Barcode parse(String input) {
    final barcode = tryParse(input);
    if (barcode == null) {
      throw FormatException('Invalid barcode', input);
    }
    return barcode;
  }

  /// Validates the trailing GTIN check digit for the whole [code].
  static bool _hasValidCheckDigit(String code) {
    final payload = code.substring(0, code.length - 1);
    final expected = code.codeUnitAt(code.length - 1) - 0x30;
    return _computeCheckDigit(payload) == expected;
  }

  /// Computes the GTIN mod-10 check digit for [payload] (digits excluding the
  /// check digit). The rightmost payload digit is weighted by 3, then weights
  /// alternate 1, 3, 1, ... toward the left.
  static int _computeCheckDigit(String payload) {
    var sum = 0;
    for (var i = 0; i < payload.length; i++) {
      final digit = payload.codeUnitAt(payload.length - 1 - i) - 0x30;
      final weight = i.isEven ? 3 : 1;
      sum += digit * weight;
    }
    return (10 - (sum % 10)) % 10;
  }

  @override
  bool operator ==(Object other) =>
      other is Barcode && other.value == value && other.format == format;

  @override
  int get hashCode => Object.hash(value, format);

  @override
  String toString() => 'Barcode($value, ${format.wire})';
}
