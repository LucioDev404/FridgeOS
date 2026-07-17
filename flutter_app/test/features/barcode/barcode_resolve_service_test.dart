import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/repositories/barcode_lookup_repository.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/barcode/application/barcode_resolve_service.dart';
import 'package:fridgeos/features/barcode/data/open_food_facts_client.dart';

import '../../support/fake_repositories.dart';
import '../../support/fakes.dart';

final class _FakeLookups implements BarcodeLookupRepository {
  final Map<String, BarcodeLookup> _store = {};
  int upserts = 0;

  @override
  Future<Result<BarcodeLookup?>> find(Barcode barcode) async =>
      Result.success(_store[barcode.value]);

  @override
  Future<Result<void>> upsert(BarcodeLookup lookup) async {
    upserts++;
    _store[lookup.barcode.value] = lookup;
    return const Result.success(null);
  }
}

final class _FakeOff implements OpenFoodFactsClient {
  int calls = 0;
  OffProductDraft? draft;
  bool fail = false;

  @override
  Future<Result<OffProductDraft?>> fetchByBarcode(Barcode barcode) async {
    calls++;
    if (fail) return const Result.failure(NetworkFailure('offline'));
    return Result.success(draft);
  }
}

void main() {
  late FakeProductRepository products;
  late _FakeLookups lookups;
  late _FakeOff off;
  late FixedClock clock;
  late SequentialIdGenerator ids;

  setUp(() {
    products = FakeProductRepository();
    lookups = _FakeLookups();
    off = _FakeOff();
    clock = FixedClock(DateTime.utc(2026, 7, 17, 10));
    ids = SequentialIdGenerator();
  });

  BarcodeResolveService service({bool enrichment = true}) =>
      BarcodeResolveService(
        products: products,
        lookups: lookups,
        off: off,
        clock: clock,
        ids: ids,
        enrichmentEnabled: enrichment,
      );

  final barcode = Barcode.parse('4006381333931');

  test('returns local product without calling OFF', () async {
    await products.upsert(
      Product(
        id: 'p1',
        barcode: barcode,
        name: 'Milk',
        category: FoodCategory.dairy,
        defaultUnit: MeasurementUnit.liters,
        source: ProductSource.manual,
        createdAt: clock.nowUtc(),
        updatedAt: clock.nowUtc(),
      ),
    );
    final result = await service().resolve(barcode.value);
    expect(result.valueOrNull, isA<BarcodeResolveFound>());
    expect(off.calls, 0);
  });

  test(
    'does not re-query OFF for a fresh negative cache entry (AC-BAR-6)',
    () async {
      await lookups.upsert(
        BarcodeLookup(
          barcode: barcode,
          result: BarcodeLookupResult.notFound,
          fetchedAt: clock.nowUtc(),
          ttlUntil: clock.nowUtc().add(const Duration(days: 7)),
        ),
      );
      final result = await service().resolve(barcode.value);
      expect(result.valueOrNull, isA<BarcodeResolveNotFound>());
      expect(off.calls, 0);
    },
  );

  test('caches a negative OFF miss with TTL', () async {
    off.draft = null;
    final result = await service().resolve(barcode.value);
    expect(result.valueOrNull, isA<BarcodeResolveNotFound>());
    expect(lookups.upserts, 1);
    expect(off.calls, 1);
  });

  test('persists an OFF hit as a local product', () async {
    off.draft = OffProductDraft(
      barcode: barcode,
      name: 'Juice',
      brand: 'Brand',
    );
    final result = await service().resolve(barcode.value);
    final found = result.valueOrNull! as BarcodeResolveFound;
    expect(found.product.name, 'Juice');
    expect(found.product.source, ProductSource.openFoodFacts);
    expect(
      (await products.findByBarcode(barcode.value)).valueOrNull,
      isNotNull,
    );
  });

  test(
    'offline OFF failure falls back to manual without poisoning cache',
    () async {
      off.fail = true;
      final result = await service().resolve(barcode.value);
      expect(result.valueOrNull, isA<BarcodeResolveNeedsManual>());
      expect(lookups.upserts, 0);
    },
  );

  test('enrichment disabled skips OFF', () async {
    final result = await service(enrichment: false).resolve(barcode.value);
    expect(result.valueOrNull, isA<BarcodeResolveNeedsManual>());
    expect(off.calls, 0);
  });

  test('rejects invalid barcodes', () async {
    final result = await service().resolve('not-a-barcode');
    expect(result.isFailure, isTrue);
  });
}
