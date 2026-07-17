import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Immutable event history. Implemented alongside inventory (Phase 4+).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.history_outlined,
      title: l10n.historyEmptyTitle,
      body: l10n.historyEmptyBody,
    );
  }
}
