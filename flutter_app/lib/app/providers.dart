import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/router.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:go_router/go_router.dart';

/// Cross-cutting infrastructure providers (composition root).
///
/// Concrete implementations are wired here and overridden in tests
/// (see docs/07-architecture.md §3).

/// System time source; overridden with a fixed clock in tests.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// UUID-based identifier generator; overridden with a deterministic generator
/// in tests.
final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidGenerator());

/// Shared input sanitizer for untrusted text.
final inputSanitizerProvider = Provider<InputSanitizer>(
  (ref) => const InputSanitizer(),
);

/// The application router. Created once for the app's lifetime.
final routerProvider = Provider<GoRouter>((ref) => createRouter());
