import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Recipe suggestions ranked by availability, expiration and preferences.
/// Implemented in Phase 7.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.restaurant_menu_outlined,
      title: l10n.recipesEmptyTitle,
      body: l10n.recipesEmptyBody,
    );
  }
}
