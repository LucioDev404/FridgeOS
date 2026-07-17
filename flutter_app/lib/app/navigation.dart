import 'package:flutter/material.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// A top-level navigation destination in the app shell.
class AppDestination {
  const AppDestination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Route path (also the branch's initial location).
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// Resolves the localized label for this destination.
  final String Function(AppLocalizations l10n) label;
}

/// The ordered set of primary destinations shown in the navigation rail/bar.
/// Order here defines the order of the router's shell branches.
const List<AppDestination> kDestinations = <AppDestination>[
  AppDestination(
    path: '/',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: _homeLabel,
  ),
  AppDestination(
    path: '/inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: _inventoryLabel,
  ),
  AppDestination(
    path: '/expiring',
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule,
    label: _expiringLabel,
  ),
  AppDestination(
    path: '/recipes',
    icon: Icons.restaurant_menu_outlined,
    selectedIcon: Icons.restaurant_menu,
    label: _recipesLabel,
  ),
  AppDestination(
    path: '/shopping',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    label: _shoppingLabel,
  ),
  AppDestination(
    path: '/history',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
    label: _historyLabel,
  ),
  AppDestination(
    path: '/statistics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: _statisticsLabel,
  ),
  AppDestination(
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: _settingsLabel,
  ),
];

String _homeLabel(AppLocalizations l10n) => l10n.navHome;
String _inventoryLabel(AppLocalizations l10n) => l10n.navInventory;
String _expiringLabel(AppLocalizations l10n) => l10n.navExpiring;
String _recipesLabel(AppLocalizations l10n) => l10n.navRecipes;
String _shoppingLabel(AppLocalizations l10n) => l10n.navShopping;
String _historyLabel(AppLocalizations l10n) => l10n.navHistory;
String _statisticsLabel(AppLocalizations l10n) => l10n.navStatistics;
String _settingsLabel(AppLocalizations l10n) => l10n.navSettings;
