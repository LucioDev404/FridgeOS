import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/user_preferences.dart';

/// Contract for reading and persisting the single-row user preferences.
abstract interface class PreferencesRepository {
  /// Emits the current preferences whenever they change.
  Stream<UserPreferences> watch();

  /// Reads the current preferences once.
  Future<Result<UserPreferences>> load();

  /// Persists [preferences] (upserts the singleton row).
  Future<Result<void>> save(UserPreferences preferences);
}
