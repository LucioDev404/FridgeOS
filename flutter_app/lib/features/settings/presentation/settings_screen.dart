import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Settings: enrichment toggle, notifications, backup/restore, theme, reset.
/// Implemented in Phases 5, 6 and 9.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.settings_outlined,
      title: l10n.settingsEmptyTitle,
      body: l10n.settingsEmptyBody,
    );
  }
}
