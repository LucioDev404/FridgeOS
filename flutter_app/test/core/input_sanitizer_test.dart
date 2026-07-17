import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';

void main() {
  const sanitizer = InputSanitizer();

  group('InputSanitizer.sanitize', () {
    test('returns empty string for null or empty input', () {
      expect(sanitizer.sanitize(null), '');
      expect(sanitizer.sanitize(''), '');
    });

    test('strips control characters', () {
      expect(sanitizer.sanitize('a\u0000b\u0007c'), 'abc');
    });

    test('collapses whitespace runs and trims', () {
      expect(sanitizer.sanitize('  hello   world  '), 'hello world');
      expect(sanitizer.sanitize('line\t\tbreak'), 'line break');
    });

    test('strips Unicode line/paragraph separators', () {
      expect(sanitizer.sanitize('a\u2028b\u2029c'), 'a b c');
    });
  });

  group('InputSanitizer.requireText', () {
    test('accepts a valid value', () {
      final result = sanitizer.requireText('Milk', maxLength: 50);
      expect(result.valueOrNull, 'Milk');
    });

    test('rejects empty (post-sanitization) values', () {
      final result = sanitizer.requireText('   ', maxLength: 50);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects values exceeding maxLength', () {
      final result = sanitizer.requireText('x' * 51, maxLength: 50);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('InputSanitizer.optionalText', () {
    test('maps empty input to a null success', () {
      final result = sanitizer.optionalText('  ', maxLength: 10);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('rejects overly long input', () {
      final result = sanitizer.optionalText('x' * 11, maxLength: 10);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
