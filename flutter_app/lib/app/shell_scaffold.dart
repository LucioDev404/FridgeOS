import 'package:flutter/material.dart';
import 'package:fridgeos/app/navigation.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Adaptive application shell (see docs/10-ui-guidelines.md §2).
///
/// * Compact width (< 600 dp): bottom [NavigationBar] (phone, best-effort).
/// * Medium/expanded (>= 600 dp, the tablet target): persistent
///   [NavigationRail].
///
/// The shell owns the app bar and the primary Scan action; the routed branch is
/// rendered as the body via the [StatefulNavigationShell].
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  /// Compact-width breakpoint below which a bottom navigation bar is used.
  static const double compactBreakpoint = 600;

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= compactBreakpoint;
    final title = kDestinations[navigationShell.currentIndex].label(l10n);

    final scanButton = FloatingActionButton.extended(
      onPressed: () => context.go('/scan'),
      icon: const Icon(Icons.qr_code_scanner),
      label: Text(l10n.scan),
    );

    if (useRail) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: FloatingActionButton(
                  heroTag: 'scan-rail',
                  onPressed: () => context.go('/scan'),
                  tooltip: l10n.scan,
                  child: const Icon(Icons.qr_code_scanner),
                ),
              ),
              destinations: [
                for (final d in kDestinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label(l10n)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: navigationShell,
      floatingActionButton: scanButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in kDestinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label(l10n),
            ),
        ],
      ),
    );
  }
}
