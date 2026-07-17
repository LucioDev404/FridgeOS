import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/app/app.dart';
import 'package:fridgeos/l10n/gen/app_localizations_en.dart';

Future<void> _pumpApp(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ProviderScope(child: FridgeOsApp()));
  await tester.pumpAndSettle();
}

void main() {
  final en = AppLocalizationsEn();

  group('App shell', () {
    testWidgets('boots to the home dashboard', (tester) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      expect(find.text(en.homeEmptyTitle), findsOneWidget);
      // The primary scan action is reachable from the home surface.
      expect(find.text(en.scan), findsWidgets);
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

      await tester.tap(find.widgetWithText(FilledButton, en.scan));
      await tester.pumpAndSettle();

      expect(find.text(en.scanTitle), findsOneWidget);
      expect(find.text(en.scanEmptyTitle), findsOneWidget);
    });
  });
}
