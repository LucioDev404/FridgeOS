import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/app/app.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/barcode/presentation/scan_screen.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:fridgeos/l10n/gen/app_localizations_en.dart';

import '../support/fake_repositories.dart';
import '../support/fakes.dart';

Future<void> _pumpApp(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final now = DateTime.utc(2026, 7, 1);
  final locations = FakeLocationRepository([
    Location(
      id: kDefaultFridgeId,
      name: 'Refrigerator',
      type: LocationType.refrigerator,
      createdAt: now,
      updatedAt: now,
    ),
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(FakeProductRepository()),
        locationRepositoryProvider.overrideWithValue(locations),
        inventoryRepositoryProvider.overrideWithValue(
          FakeInventoryRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          FakePreferencesRepository(),
        ),
        recipeRepositoryProvider.overrideWithValue(FakeRecipeRepository()),
        shoppingRepositoryProvider.overrideWithValue(FakeShoppingRepository()),
        clockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 7, 17, 10)),
        ),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
      child: const FridgeOsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final en = AppLocalizationsEn();

  setUp(() {
    debugDisableCameraPreview = true;
  });

  tearDown(() {
    debugDisableCameraPreview = false;
  });

  group('App shell', () {
    testWidgets('boots to the home dashboard', (tester) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      expect(find.text(en.homeEmptyTitle), findsOneWidget);
      // The primary scan action is reachable from the shell's navigation rail.
      expect(find.byTooltip(en.scan), findsWidgets);
    });

    testWidgets('uses a navigation rail on a tablet-width layout', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('uses a bottom navigation bar on a compact layout', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(420, 900));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('navigates between destinations via the rail', (tester) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      await tester.tap(find.text(en.navInventory).first);
      await tester.pumpAndSettle();

      expect(find.text(en.inventoryEmptyTitle), findsOneWidget);
    });

    testWidgets('opens the full-screen scan route', (tester) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      await tester.tap(find.byTooltip(en.scan).first);
      await tester.pumpAndSettle();

      expect(find.text(en.scanTitle), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      // Camera is disabled in tests; manual entry is the fallback path.
      expect(find.text(en.fieldBarcode), findsOneWidget);
    });

    testWidgets('scan back button returns to the shell', (tester) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      await tester.tap(find.byTooltip(en.scan).first);
      await tester.pumpAndSettle();
      expect(find.text(en.scanTitle), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text(en.scanTitle), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
