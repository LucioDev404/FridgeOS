import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import 'fakes.dart';

/// Builds a [ProviderContainer] backed by a fresh in-memory database and
/// deterministic clock/id/today overrides, with teardown registered.
ProviderContainer createTestContainer({DateOnly? today}) {
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(
        FixedClock(DateTime.utc(2026, 7, 17, 10)),
      ),
      idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      if (today != null) todayProvider.overrideWithValue(today),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(db.close);
  return container;
}
