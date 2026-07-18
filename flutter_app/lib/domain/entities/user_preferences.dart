import 'package:fridgeos/domain/value_objects/diet_preference.dart';

/// User preferences (a single-row aggregate). Defaults are chosen so the app is
/// fully functional out of the box (see docs/06-database-design.md §3.10).
final class UserPreferences {
  const UserPreferences({
    this.maxPrepTimeMinutes,
    this.favoriteTags = const <String>[],
    this.blockedTags = const <String>[],
    this.expiringSoonWindowDays = 3,
    this.digestTime = '09:00',
    this.enrichmentEnabled = true,
    this.theme = 'system',
    this.dietPreference = DietPreference.omnivore,
  });

  /// Optional cap used by recipe ranking (see docs/05-domain-model.md §6).
  final int? maxPrepTimeMinutes;
  final List<String> favoriteTags;
  final List<String> blockedTags;

  /// Days before expiry at which an item is flagged as "expiring soon".
  final int expiringSoonWindowDays;

  /// Daily notification digest time as `HH:mm`.
  final String digestTime;

  /// Whether OpenFoodFacts enrichment is enabled (opt-out, still fully offline).
  final bool enrichmentEnabled;

  /// `system`, `light` or `dark`.
  final String theme;

  /// Recipe diet filter (persisted, schema v4+).
  final DietPreference dietPreference;

  UserPreferences copyWith({
    int? maxPrepTimeMinutes,
    List<String>? favoriteTags,
    List<String>? blockedTags,
    int? expiringSoonWindowDays,
    String? digestTime,
    bool? enrichmentEnabled,
    String? theme,
    DietPreference? dietPreference,
  }) {
    return UserPreferences(
      maxPrepTimeMinutes: maxPrepTimeMinutes ?? this.maxPrepTimeMinutes,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      blockedTags: blockedTags ?? this.blockedTags,
      expiringSoonWindowDays:
          expiringSoonWindowDays ?? this.expiringSoonWindowDays,
      digestTime: digestTime ?? this.digestTime,
      enrichmentEnabled: enrichmentEnabled ?? this.enrichmentEnabled,
      theme: theme ?? this.theme,
      dietPreference: dietPreference ?? this.dietPreference,
    );
  }
}
