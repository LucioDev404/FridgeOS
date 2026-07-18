import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/app/router.dart';

void main() {
  test('statistics nested detail routes are registered', () {
    final router = createRouter();
    for (final path in const [
      '/statistics',
      '/statistics/charts',
      '/statistics/insights',
      '/statistics/products',
      '/statistics/forecast',
    ]) {
      expect(
        () => router.go(path),
        returnsNormally,
        reason: 'route $path must be registered',
      );
    }
  });
}
