/// Failure taxonomy for expected, recoverable errors.
///
/// The domain and data layers return [Failure]s via `Result` instead of
/// throwing for anticipated error conditions (see docs/07-architecture.md §6).
/// Unexpected programming errors remain exceptions and are caught at the
/// composition boundary.
sealed class Failure {
  const Failure(this.message);

  /// Human-readable, non-sensitive description. Never contains secrets or PII.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// Input failed validation (self-validating value object, validator, or
/// sanitizer rejected the value). See docs/09-security-design.md §4.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// A requested entity could not be found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// A network operation failed (offline, timeout, non-2xx). Must never block a
/// core offline flow (see docs/03-non-functional-requirements.md NFR-REL-4).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// A local persistence operation failed.
final class PersistenceFailure extends Failure {
  const PersistenceFailure(super.message);
}

/// A required OS permission was denied.
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// A cryptographic operation failed (e.g. backup decryption / integrity check).
final class CryptoFailure extends Failure {
  const CryptoFailure(super.message);
}
