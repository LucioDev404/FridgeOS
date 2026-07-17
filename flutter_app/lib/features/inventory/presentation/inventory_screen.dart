import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Inventory list. Browsing, search and filtering land in Phase 4.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: l10n.inventoryEmptyTitle,
      body: l10n.inventoryEmptyBody,
    );
  }
}
