import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/features/settings/application/settings_actions.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/container.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late SettingsActions settingsActions;

  setUp(() {
    container = createTestContainer();
    db = container.read(appDatabaseProvider);
    settingsActions = container.read(settingsActionsProvider);
  });

  test('updateExpiringSoonWindowDays persists to preferences', () async {
    final result = await settingsActions.updateExpiringSoonWindowDays(7);
    expect(result.isSuccess, isTrue);

    final row = (await db.select(db.preferences).get()).single;
    expect(row.expiringSoonWindowDays, 7);
  });

  test('setEnrichmentEnabled persists toggle', () async {
    final result = await settingsActions.setEnrichmentEnabled(false);
    expect(result.isSuccess, isTrue);

    final row = (await db.select(db.preferences).get()).single;
    expect(row.enrichmentEnabled, isFalse);
  });

  test('rejects invalid expiring window', () async {
    final result = await settingsActions.updateExpiringSoonWindowDays(50);
    expect(result.isFailure, isTrue);
  });
}
