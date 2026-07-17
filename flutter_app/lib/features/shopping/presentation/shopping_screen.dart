import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Shopping list (manual + auto-generated). Implemented in Phase 8.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: l10n.shoppingEmptyTitle,
      body: l10n.shoppingEmptyBody,
    );
  }
}
