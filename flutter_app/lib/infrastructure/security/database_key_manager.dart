import 'dart:math';

import 'package:fridgeos/infrastructure/security/secret_store.dart';

/// Manages the lifecycle of the database encryption key
/// (docs/06-database-design.md §6, docs/09-security-design.md §5).
///
/// The key is a 256-bit value generated with a cryptographically secure RNG on
/// first use and persisted in Keystore-backed [SecretStore]. It is never logged
/// and never leaves the device.
final class DatabaseKeyManager {
  DatabaseKeyManager(this._store, {Random? random})
    : _random = random ?? Random.secure();

  /// Storage key under which the hex-encoded database key is kept.
  static const String storageKey = 'db_encryption_key';

  /// Key length in bytes (256-bit).
  static const int keyLengthBytes = 32;

  final SecretStore _store;
  final Random _random;

  /// Returns the existing database key, generating and persisting one on first
  /// use. The returned value is a 64-character lowercase hex string.
  Future<String> getOrCreateKey() async {
    final existing = await _store.read(storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final key = _generateHexKey();
    await _store.write(storageKey, key);
    return key;
  }

  /// Whether a database key has already been provisioned.
  Future<bool> hasKey() async {
    final existing = await _store.read(storageKey);
    return existing != null && existing.isNotEmpty;
  }

  String _generateHexKey() {
    final buffer = StringBuffer();
    for (var i = 0; i < keyLengthBytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
