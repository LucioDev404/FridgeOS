import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/infrastructure/security/database_key_manager.dart';

import '../support/fakes.dart';

void main() {
  group('DatabaseKeyManager', () {
    test('generates a 256-bit (64 hex char) key on first use', () async {
      final manager = DatabaseKeyManager(InMemorySecretStore());
      final key = await manager.getOrCreateKey();
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
    });

    test('returns the same key on subsequent calls', () async {
      final manager = DatabaseKeyManager(InMemorySecretStore());
      final first = await manager.getOrCreateKey();
      final second = await manager.getOrCreateKey();
      expect(second, first);
    });

    test('hasKey reflects provisioning state', () async {
      final manager = DatabaseKeyManager(InMemorySecretStore());
      expect(await manager.hasKey(), isFalse);
      await manager.getOrCreateKey();
      expect(await manager.hasKey(), isTrue);
    });

    test('uses the injected RNG deterministically', () async {
      final manager = DatabaseKeyManager(
        InMemorySecretStore(),
        random: Random(42),
      );
      final key = await manager.getOrCreateKey();
      final expected = DatabaseKeyManager(
        InMemorySecretStore(),
        random: Random(42),
      );
      expect(await expected.getOrCreateKey(), key);
    });
  });
}
