import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/locations/application/location_actions.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../../support/container.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late LocationActions actions;

  setUp(() {
    container = createTestContainer();
    db = container.read(appDatabaseProvider);
    actions = container.read(locationActionsProvider);
  });

  test('create adds a new location', () async {
    final before = (await db.select(db.locations).get()).length;
    final result = await actions.create(
      name: 'Garage shelf',
      type: LocationType.pantry,
    );
    expect(result.isSuccess, isTrue);
    final after = await db.select(db.locations).get();
    expect(after.length, before + 1);
    expect(after.any((l) => l.name == 'Garage shelf'), isTrue);
  });

  test('create rejects an empty name', () async {
    final result = await actions.create(name: '   ', type: LocationType.pantry);
    expect(result.isFailure, isTrue);
  });

  test('update renames and retypes an existing location', () async {
    final seeded = (await (db.select(
      db.locations,
    )..where((t) => t.id.equals(kDefaultPantryId))).getSingle());

    final result = await actions.update(
      location: locationFromRow(seeded),
      name: 'Main pantry',
      type: LocationType.pantry,
    );
    expect(result.isSuccess, isTrue);

    final updated = await (db.select(
      db.locations,
    )..where((t) => t.id.equals(kDefaultPantryId))).getSingle();
    expect(updated.name, 'Main pantry');
  });
}
