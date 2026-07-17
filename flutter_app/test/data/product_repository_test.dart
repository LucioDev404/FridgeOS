import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/data/repositories/drift_product_repository.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

void main() {
  late AppDatabase db;
  late DriftProductRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftProductRepository(db);
  });

  tearDown(() => db.close());

  Product sampleProduct({String id = 'p1', String? barcodeValue}) => Product(
    id: id,
    barcode: barcodeValue == null ? null : Barcode.parse(barcodeValue),
    name: 'Whole Milk',
    brand: 'Farm',
    category: FoodCategory.dairy,
    defaultUnit: MeasurementUnit.liters,
    source: ProductSource.manual,
    createdAt: DateTime.utc(2026, 7, 17, 10),
    updatedAt: DateTime.utc(2026, 7, 17, 10),
  );

  test('upsert then findById round-trips the domain entity', () async {
    final product = sampleProduct(barcodeValue: '96385074');
    final upsert = await repo.upsert(product);
    expect(upsert.isSuccess, isTrue);

    final found = await repo.findById('p1');
    expect(found.valueOrNull, product);
  });

  test('findByBarcode returns the cached product', () async {
    await repo.upsert(sampleProduct(barcodeValue: '96385074'));
    final found = await repo.findByBarcode('96385074');
    expect(found.valueOrNull?.barcode?.value, '96385074');
  });

  test('upsert updates an existing product (same id)', () async {
    await repo.upsert(sampleProduct());
    await repo.upsert(sampleProduct().copyWith(name: 'Skim Milk'));
    final found = await repo.findById('p1');
    expect(found.valueOrNull?.name, 'Skim Milk');
  });

  test('watchAll excludes soft-deleted products', () async {
    await repo.upsert(sampleProduct(id: 'p1'));
    await repo.upsert(sampleProduct(id: 'p2'));

    await expectLater(repo.watchAll().map((list) => list.length), emits(2));

    await repo.softDelete('p1', DateTime.utc(2026, 7, 18));
    expect((await repo.findById('p1')).valueOrNull, isNull);
    await expectLater(repo.watchAll().map((list) => list.length), emits(1));
  });
}
