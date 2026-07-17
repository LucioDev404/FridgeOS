import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/location.dart';

/// Contract for reading and persisting storage [Location]s.
abstract interface class LocationRepository {
  /// Emits the current set of non-deleted locations, updating on change.
  Stream<List<Location>> watchAll();

  /// Returns the location with [id], or `null` when absent/soft-deleted.
  Future<Result<Location?>> findById(String id);

  /// Inserts or updates [location].
  Future<Result<void>> upsert(Location location);
}
