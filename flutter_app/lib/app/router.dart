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
import 'package:fridgeos/features/shopping/presentation/shopping_qr_export_screen.dart';
import 'package:fridgeos/features/shopping/presentation/shopping_qr_import_screen.dart';
import 'package:fridgeos/features/shopping/presentation/shopping_screen.dart';
import 'package:fridgeos/features/statistics/presentation/statistics_detail_pages.dart';
import 'package:fridgeos/features/statistics/presentation/statistics_screen.dart';
import 'package:go_router/go_router.dart';

/// Builds the application's [GoRouter].
///
/// A [StatefulShellRoute.indexedStack] provides a persistent navigation
/// rail/bar with independent navigation state per branch (see
/// docs/07-architecture.md §5). Nested branch routes (recipes detail,
/// statistics detail) share the shell AppBar Back button. The scanner and
/// locations manager are full-screen routes outside the shell.
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingScreen(),
                routes: [
                  GoRoute(
                    path: 'qr-export',
                    builder: (context, state) => const ShoppingQrExportScreen(),
                  ),
                  GoRoute(
                    path: 'qr-import',
                    builder: (context, state) => const ShoppingQrImportScreen(),
                  ),
                ],
              ),
            ],
          ),
          _branch('/history', const HistoryScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
                routes: [
                  GoRoute(
                    path: 'charts',
                    builder: (context, state) => const StatisticsChartsPage(),
                  ),
                  GoRoute(
                    path: 'insights',
                    builder: (context, state) => const StatisticsInsightsPage(),
                  ),
                  GoRoute(
                    path: 'products',
                    builder: (context, state) => const StatisticsProductsPage(),
                  ),
                  GoRoute(
                    path: 'forecast',
                    builder: (context, state) => const StatisticsForecastPage(),
                  ),
                ],
              ),
            ],
          ),
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
