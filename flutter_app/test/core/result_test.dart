import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';

void main() {
  group('Result', () {
    test('success carries a value', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('failure carries a Failure', () {
      const result = Result<int>.failure(NotFoundFailure('missing'));
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('fold selects the correct branch', () {
      const ok = Result<int>.success(2);
      const err = Result<int>.failure(ValidationFailure('bad'));
      expect(ok.fold((_) => 'f', (v) => 'v$v'), 'v2');
      expect(err.fold((_) => 'f', (v) => 'v$v'), 'f');
    });

    test('map transforms success and preserves failure', () {
      const ok = Result<int>.success(2);
      expect(ok.map((v) => v * 10).valueOrNull, 20);

      const err = Result<int>.failure(PersistenceFailure('db'));
      final mapped = err.map((v) => v * 10);
      expect(mapped.failureOrNull, isA<PersistenceFailure>());
    });

    test('value equality', () {
      expect(const Result<int>.success(1), const Result<int>.success(1));
      expect(
        const Result<int>.failure(NotFoundFailure('x')),
        const Result<int>.failure(NotFoundFailure('x')),
      );
    });
  });
}
