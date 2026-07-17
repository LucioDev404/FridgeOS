import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/barcode/presentation/scan_screen.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:fridgeos/l10n/gen/app_localizations_en.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_repositories.dart';
import '../../support/fakes.dart';

void main() {
  final en = AppLocalizationsEn();

  setUp(() {
    debugDisableCameraPreview = true;
  });

  tearDown(() {
    debugDisableCameraPreview = false;
  });

  Future<GoRouter> pumpScanStack(WidgetTester tester) async {
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

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/scan'),
                child: Text(en.scan),
              ),
            ),
          ),
        ),
        GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      ],
    );

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
          shoppingRepositoryProvider.overrideWithValue(
            FakeShoppingRepository(),
          ),
          clockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 7, 17, 10)),
          ),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('opens scan screen with back control and manual fallback', (
    tester,
  ) async {
    await pumpScanStack(tester);

    await tester.tap(find.text(en.scan));
    await tester.pumpAndSettle();

    expect(find.text(en.scanTitle), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text(en.back), findsOneWidget);
    expect(find.text(en.enterManually), findsNothing); // already in manual
    expect(find.text(en.fieldBarcode), findsOneWidget);
    expect(find.text(en.lookupBarcode), findsOneWidget);
  });

  testWidgets('back button returns to the previous route', (tester) async {
    await pumpScanStack(tester);

    await tester.tap(find.text(en.scan));
    await tester.pumpAndSettle();
    expect(find.text(en.scanTitle), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text(en.scanTitle), findsNothing);
    expect(find.text(en.scan), findsOneWidget);
  });

  testWidgets('manual lookup field is editable', (tester) async {
    await pumpScanStack(tester);
    await tester.tap(find.text(en.scan));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '96385074');
    expect(find.widgetWithText(TextField, '96385074'), findsOneWidget);
  });
}
