import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
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

  test('delete soft-deletes an empty location', () async {
    final created = await actions.create(
      name: 'Spare shelf',
      type: LocationType.pantry,
    );
    expect(created.isSuccess, isTrue);
    final location = (await db.select(db.locations).get())
        .map(locationFromRow)
        .firstWhere((l) => l.name == 'Spare shelf');

    final result = await actions.delete(location: location);
    expect(result.isSuccess, isTrue);

    final deleted = await (db.select(
      db.locations,
    )..where((t) => t.id.equals(location.id))).getSingle();
    expect(deleted.deletedAt, isNotNull);
  });

  test('delete is blocked when products remain in the location', () async {
    final inventory = container.read(inventoryActionsProvider);
    final add = await inventory.addManualItem(
      name: 'Milk',
      category: FoodCategory.dairy,
      unit: MeasurementUnit.liters,
      amount: 1,
      locationId: kDefaultFridgeId,
    );
    expect(add.isSuccess, isTrue);

    final fridge = locationFromRow(
      await (db.select(
        db.locations,
      )..where((t) => t.id.equals(kDefaultFridgeId))).getSingle(),
    );
    final result = await actions.delete(location: fridge);
    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, 'LOCATION_HAS_PRODUCTS');
  });
}
