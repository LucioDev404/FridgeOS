import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/repositories/barcode_lookup_repository.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/features/barcode/data/open_food_facts_client.dart';

/// How long a negative (not-found) cache entry remains valid before OFF may be
/// queried again (FR-BAR-6).
const Duration kNegativeLookupTtl = Duration(days: 7);

/// Outcome of resolving a scanned barcode.
sealed class BarcodeResolveResult {
  const BarcodeResolveResult();
}

final class BarcodeResolveFound extends BarcodeResolveResult {
  const BarcodeResolveFound(this.product);
  final Product product;
}

final class BarcodeResolveNotFound extends BarcodeResolveResult {
  const BarcodeResolveNotFound();
}

final class BarcodeResolveNeedsManual extends BarcodeResolveResult {
  const BarcodeResolveNeedsManual(this.barcode);
  final Barcode barcode;
}

/// Resolves a barcode via local product cache → lookup cache → OFF enrichment.
/// Never re-queries OFF for a fresh negative cache entry (AC-BAR-6).
final class BarcodeResolveService {
  const BarcodeResolveService({
    required this.products,
    required this.lookups,
    required this.off,
    required this.clock,
    required this.ids,
    this.enrichmentEnabled = true,
  });

  final ProductRepository products;
  final BarcodeLookupRepository lookups;
  final OpenFoodFactsClient off;
  final Clock clock;
  final IdGenerator ids;
  final bool enrichmentEnabled;

  Future<Result<BarcodeResolveResult>> resolve(String rawBarcode) async {
    final barcode = Barcode.tryParse(rawBarcode);
    if (barcode == null) {
      return const Result.failure(ValidationFailure('Invalid barcode'));
    }

    final local = await products.findByBarcode(barcode.value);
    if (local.isFailure) return Result.failure(local.failureOrNull!);
    final existing = local.valueOrNull;
    if (existing != null) {
      return Result.success(BarcodeResolveFound(existing));
    }

    final cached = await lookups.find(barcode);
    if (cached.isFailure) return Result.failure(cached.failureOrNull!);
    final lookup = cached.valueOrNull;
    final now = clock.nowUtc();
    if (lookup != null && lookup.isFresh(now)) {
      if (lookup.result == BarcodeLookupResult.notFound) {
        return const Result.success(BarcodeResolveNotFound());
      }
      if (lookup.productId != null) {
        final byId = await products.findById(lookup.productId!);
        if (byId.isFailure) return Result.failure(byId.failureOrNull!);
        final product = byId.valueOrNull;
        if (product != null) {
          return Result.success(BarcodeResolveFound(product));
        }
      }
    }

    if (!enrichmentEnabled) {
      return Result.success(BarcodeResolveNeedsManual(barcode));
    }

    final remote = await off.fetchByBarcode(barcode);
    if (remote.isFailure) {
      // Offline / network error → allow manual entry without poisoning cache.
      return Result.success(BarcodeResolveNeedsManual(barcode));
    }
    final draft = remote.valueOrNull;
    if (draft == null) {
      await lookups.upsert(
        BarcodeLookup(
          barcode: barcode,
          result: BarcodeLookupResult.notFound,
          fetchedAt: now,
          ttlUntil: now.add(kNegativeLookupTtl),
        ),
      );
      return const Result.success(BarcodeResolveNotFound());
    }

    final product = draft.toProduct(id: ids.newId(), now: now);
    final upsert = await products.upsert(product);
    if (upsert.isFailure) return Result.failure(upsert.failureOrNull!);

    await lookups.upsert(
      BarcodeLookup(
        barcode: barcode,
        result: BarcodeLookupResult.found,
        productId: product.id,
        fetchedAt: now,
      ),
    );
    return Result.success(BarcodeResolveFound(product));
  }
}
