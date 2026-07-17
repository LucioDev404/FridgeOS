/// Centralized spacing and radius tokens (see docs/10-ui-guidelines.md §6).
///
/// Widgets reference these instead of hard-coded magic numbers so layout stays
/// consistent and tunable.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Minimum interactive touch target (docs/03 NFR-UX-2).
  static const double minTouchTarget = 48;

  /// Minimum width for adaptive dashboard/list tiles (docs/10 §2).
  static const double minTileWidth = 280;
}

/// Corner-radius tokens.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}
