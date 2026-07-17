import 'dart:core';

import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';

/// Central input sanitization/validation for untrusted text.
///
/// Every value that originates outside the app (OpenFoodFacts responses,
/// scanned barcode payloads, restored backups, free-text user notes) passes
/// through here before being persisted or displayed. See
/// docs/09-security-design.md §4 and docs/08-threat-model.md (M4).
///
/// This is deliberately conservative: it strips control/formatting characters,
/// collapses whitespace, normalizes to a canonical form and enforces a maximum
/// length. It never renders or interprets markup.
final class InputSanitizer {
  const InputSanitizer();

  /// Matches ASCII/Unicode control characters. Whitespace (including the
  /// Unicode line/paragraph separators U+2028/U+2029, matched by `\s`) is
  /// handled separately by [_whitespaceRun] so word boundaries are preserved.
  static final RegExp _controlChars = RegExp(
    r'[\u0000-\u0008\u000E-\u001F\u007F-\u009F]',
  );

  static final RegExp _whitespaceRun = RegExp(r'\s+');

  /// Sanitizes free-form [input]:
  /// * removes control characters,
  /// * collapses internal whitespace runs (incl. tabs, newlines and Unicode
  ///   separators) to a single space,
  /// * trims leading/trailing whitespace.
  ///
  /// Returns an empty string for `null` input.
  String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';
    final withoutControls = input.replaceAll(_controlChars, '');
    final collapsed = withoutControls.replaceAll(_whitespaceRun, ' ');
    return collapsed.trim();
  }

  /// Sanitizes and validates a required text field of at most [maxLength]
  /// characters.
  ///
  /// Returns a [ValidationFailure] when the sanitized value is empty or exceeds
  /// [maxLength].
  Result<String> requireText(
    String? input, {
    required int maxLength,
    String fieldName = 'value',
  }) {
    final value = sanitize(input);
    if (value.isEmpty) {
      return Result.failure(ValidationFailure('$fieldName must not be empty'));
    }
    if (value.length > maxLength) {
      return Result.failure(
        ValidationFailure('$fieldName must be at most $maxLength characters'),
      );
    }
    return Result.success(value);
  }

  /// Sanitizes an optional text field, enforcing [maxLength] when present.
  ///
  /// Returns a success carrying `null` when the sanitized value is empty.
  Result<String?> optionalText(
    String? input, {
    required int maxLength,
    String fieldName = 'value',
  }) {
    final value = sanitize(input);
    if (value.isEmpty) return const Result.success(null);
    if (value.length > maxLength) {
      return Result.failure(
        ValidationFailure('$fieldName must be at most $maxLength characters'),
      );
    }
    return Result.success(value);
  }
}
