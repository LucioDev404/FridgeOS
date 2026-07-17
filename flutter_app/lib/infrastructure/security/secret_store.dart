import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over Keystore-backed secure storage.
///
/// Injected so that security-sensitive components (e.g. the database key
/// manager) can be unit-tested with an in-memory fake and never touch the real
/// platform Keystore in tests (docs/09-security-design.md §5).
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecretStore] backed by `flutter_secure_storage`, which uses the Android
/// Keystore (via encrypted shared preferences) to protect values at rest.
final class FlutterSecureSecretStore implements SecretStore {
  FlutterSecureSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
