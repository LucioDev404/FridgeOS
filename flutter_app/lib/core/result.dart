import 'package:fridgeos/core/error/failure.dart';

/// A lightweight functional result type: either a [Success] carrying a value of
/// type [T], or a [ResultFailure] carrying a [Failure].
///
/// Used across the domain and data layers so expected errors are explicit and
/// testable rather than thrown (see docs/07-architecture.md §6).
sealed class Result<T> {
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result.
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// Whether this result represents success.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents failure.
  bool get isFailure => this is ResultFailure<T>;

  /// Returns the value if successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    ResultFailure<T>() => null,
  };

  /// Returns the failure if failed, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    ResultFailure<T>(:final failure) => failure,
  };

  /// Folds both branches into a single value of type [R].
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    ResultFailure<T>(:final failure) => onFailure(failure),
  };

  /// Maps the success value, preserving a failure unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Success<R>(transform(value)),
    ResultFailure<T>(:final failure) => ResultFailure<R>(failure),
  };
}

/// Successful [Result] variant.
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed [Result] variant.
final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ResultFailure<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
