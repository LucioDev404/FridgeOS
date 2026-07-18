import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Human-readable diet label inferred from recipe tags for UI chips.
String recipeDietLabel(List<String> tags, AppLocalizations l10n) {
  final normalized = tags.map((t) => t.toLowerCase()).toSet();
  if (normalized.contains('vegan')) return l10n.dietVegan;
  if (normalized.contains('vegetarian')) return l10n.dietVegetarian;
  return l10n.dietOmnivore;
}
