import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';

/// Application theming (Material 3, tablet-first) — see docs/10-ui-guidelines.md.
///
/// A fixed brand seed color is used as the baseline. Dynamic color from the
/// platform can be layered on later without changing call sites.
abstract final class AppTheme {
  /// Brand seed color (fresh, calm green). Used when platform dynamic color is
  /// unavailable.
  static const Color _seed = Color(0xFF2E7D5B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
        ),
      ),
    );
  }
}
