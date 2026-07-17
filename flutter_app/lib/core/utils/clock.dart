/// Abstraction over the current time so that time-dependent logic (expiration,
/// event timestamps, notification scheduling) is deterministic in tests.
///
/// Injected via Riverpod (see docs/07-architecture.md §10). Production uses
/// [SystemClock]; tests use a fixed/fake clock.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();
}

/// Default [Clock] backed by the system wall clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
