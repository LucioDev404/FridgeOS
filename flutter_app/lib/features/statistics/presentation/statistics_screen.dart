import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Consumption and food-waste statistics. Implemented in Phase 9.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.insights_outlined,
      title: l10n.statisticsEmptyTitle,
      body: l10n.statisticsEmptyBody,
    );
  }
}
