import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Dashboard / home surface. In later phases this shows glanceable summary
/// cards (in stock, expiring soon, shopping list, cookable recipes). Until the
/// data layer is wired it presents the product's onboarding empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.kitchen_outlined,
      title: l10n.homeEmptyTitle,
      body: l10n.homeEmptyBody,
      action: FilledButton.icon(
        onPressed: () => context.go('/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.scan),
      ),
    );
  }
}
