import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/mappers/mappers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/infrastructure/backup/backup_service.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

import '../support/container.dart';

void main() {
  group('BackupService', () {
    test('export and import round-trip preserves products', () async {
      final container = createTestContainer();
      final db = container.read(appDatabaseProvider);
      final service = BackupService(db);

      final now = DateTime.utc(2026, 7, 17);
      await db
          .into(db.products)
          .insert(
            productToCompanion(
              Product(
                id: 'p-backup',
                name: 'Backup Milk',
                category: FoodCategory.dairy,
                defaultUnit: MeasurementUnit.liters,
                source: ProductSource.manual,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );

      const passphrase = 'phase-nine';
      final exported = await service.exportEncrypted(passphrase);
      expect(exported.isSuccess, isTrue);

      await db.delete(db.products).go();
      expect(await db.select(db.products).get(), isEmpty);

      final imported = await service.importEncrypted(
        exported.valueOrNull!,
        passphrase,
      );
      expect(imported.isSuccess, isTrue);

      final rows = await db.select(db.products).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Backup Milk');
    });

    test('import fails with wrong passphrase', () async {
      final container = createTestContainer();
      final db = container.read(appDatabaseProvider);
      final service = BackupService(db);

      final exported = await service.exportEncrypted('right-key');
      expect(exported.isSuccess, isTrue);

      final imported = await service.importEncrypted(
        exported.valueOrNull!,
        'wrong-key',
      );
      expect(imported.isFailure, isTrue);
    });

    test(
      'factory reset clears inventory data and keeps default locations',
      () async {
        final container = createTestContainer();
        final db = container.read(appDatabaseProvider);
        final service = BackupService(db);

        final now = DateTime.utc(2026, 7, 17);
        await db
            .into(db.products)
            .insert(
              productToCompanion(
                Product(
                  id: 'p-reset',
                  name: 'Reset Me',
                  category: FoodCategory.other,
                  defaultUnit: MeasurementUnit.pieces,
                  source: ProductSource.manual,
                  createdAt: now,
                  updatedAt: now,
                ),
              ),
            );

        final reset = await service.factoryReset();
        expect(reset.isSuccess, isTrue);

        expect(await db.select(db.products).get(), isEmpty);
        expect(await db.select(db.inventoryItems).get(), isEmpty);
        expect(await db.select(db.inventoryEvents).get(), isEmpty);
        expect(await db.select(db.shoppingListItems).get(), isEmpty);

        final locations = await db.select(db.locations).get();
        expect(
          locations.map((row) => row.id),
          containsAll(<String>[
            kDefaultFridgeId,
            kDefaultFreezerId,
            kDefaultPantryId,
          ]),
        );
      },
    );
  });
}
