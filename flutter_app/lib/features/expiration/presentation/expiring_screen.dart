import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Expiring-soon and expired items. Implemented in Phase 6.
class ExpiringScreen extends StatelessWidget {
  const ExpiringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.schedule_outlined,
      title: l10n.expiringEmptyTitle,
      body: l10n.expiringEmptyBody,
    );
  }
}
