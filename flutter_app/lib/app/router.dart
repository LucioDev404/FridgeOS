import 'package:flutter/material.dart';
import 'package:fridgeos/app/shell_scaffold.dart';
import 'package:fridgeos/features/barcode/presentation/scan_screen.dart';
import 'package:fridgeos/features/expiration/presentation/expiring_screen.dart';
import 'package:fridgeos/features/history/presentation/history_screen.dart';
import 'package:fridgeos/features/inventory/presentation/home_screen.dart';
import 'package:fridgeos/features/inventory/presentation/inventory_screen.dart';
import 'package:fridgeos/features/locations/presentation/locations_screen.dart';
import 'package:fridgeos/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:fridgeos/features/recipes/presentation/recipes_screen.dart';
import 'package:fridgeos/features/settings/presentation/settings_screen.dart';
import 'package:fridgeos/features/shopping/presentation/shopping_screen.dart';
import 'package:fridgeos/features/statistics/presentation/statistics_screen.dart';
import 'package:go_router/go_router.dart';

/// Builds the application's [GoRouter].
///
/// A [StatefulShellRoute.indexedStack] provides a persistent navigation
/// rail/bar with independent navigation state per branch (see
/// docs/07-architecture.md §5). The scanner is a separate full-screen route.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          _branch('/', const HomeScreen()),
          _branch('/inventory', const InventoryScreen()),
          _branch('/expiring', const ExpiringScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recipes',
                builder: (context, state) => const RecipesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => RecipeDetailScreen(
                      recipeId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _branch('/shopping', const ShoppingScreen()),
          _branch('/history', const HistoryScreen()),
          _branch('/statistics', const StatisticsScreen()),
          _branch('/settings', const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/scan',
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: ScanScreen()),
      ),
      GoRoute(
        path: '/locations',
        builder: (context, state) => const LocationsScreen(),
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget child) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => child)],
  );
}
