import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/infrastructure/security/secret_store.dart';

/// A [Clock] that always returns a fixed instant, for deterministic tests.
final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  /// Advances the clock by [duration] (useful for time-dependent assertions).
  void advance(Duration duration) => _now = _now.add(duration);

  @override
  DateTime nowUtc() => _now.toUtc();
}

/// An [IdGenerator] producing predictable, monotonically increasing ids.
final class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator([this._prefix = 'id']);

  final String _prefix;
  int _counter = 0;

  @override
  String newId() => '$_prefix-${_counter++}';
}

/// An in-memory [SecretStore] for tests (never touches the platform Keystore).
final class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
