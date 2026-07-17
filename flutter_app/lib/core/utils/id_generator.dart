import 'package:uuid/uuid.dart';

/// Abstraction over immutable identifier generation.
///
/// All entities use UUID v4 string primary keys (see
/// docs/06-database-design.md §1). Injected so tests can use deterministic ids.
abstract interface class IdGenerator {
  /// Returns a new globally-unique identifier.
  String newId();
}

/// Default [IdGenerator] producing RFC 4122 v4 UUIDs.
final class UuidGenerator implements IdGenerator {
  UuidGenerator([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String newId() => _uuid.v4();
}
