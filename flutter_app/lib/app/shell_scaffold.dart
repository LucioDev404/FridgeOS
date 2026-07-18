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
///
/// When a nested branch route is active (e.g. `/statistics/charts`,
/// `/recipes/:id`), the app bar shows a Back button so users are never trapped
/// without a visible return path. Android system back still pops the branch
/// navigator via GoRouter.
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

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final root = kDestinations[navigationShell.currentIndex].path;
    context.go(root);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= compactBreakpoint;
    final matchedPath = GoRouterState.of(context).uri.path;
    final atBranchRoot = kDestinations.any((d) => d.path == matchedPath);
    final title = atBranchRoot
        ? kDestinations[navigationShell.currentIndex].label(l10n)
        : _nestedTitle(l10n, matchedPath);

    final scanButton = FloatingActionButton.extended(
      onPressed: () => context.push('/scan'),
      icon: const Icon(Icons.qr_code_scanner),
      label: Text(l10n.scan),
    );

    final appBar = AppBar(
      automaticallyImplyLeading: false,
      leading: atBranchRoot
          ? null
          : BackButton(onPressed: () => _goBack(context)),
      title: Text(title),
    );

    if (useRail) {
      return Scaffold(
        appBar: appBar,
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
                  onPressed: () => context.push('/scan'),
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
      appBar: appBar,
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

  String _nestedTitle(AppLocalizations l10n, String path) {
    if (path.startsWith('/statistics/charts')) {
      return l10n.statisticsChartsSection;
    }
    if (path.startsWith('/statistics/insights')) {
      return l10n.statisticsMetricsSection;
    }
    if (path.startsWith('/statistics/products')) {
      return l10n.statisticsMostConsumedSection;
    }
    if (path.startsWith('/statistics/forecast')) {
      return l10n.forecastSection;
    }
    if (path.startsWith('/recipes/')) {
      return l10n.recipesTitle;
    }
    if (path.startsWith('/shopping/qr-export')) {
      return l10n.shoppingQrExportTitle;
    }
    if (path.startsWith('/shopping/qr-import')) {
      return l10n.shoppingQrImportTitle;
    }
    return kDestinations[navigationShell.currentIndex].label(l10n);
  }
}
