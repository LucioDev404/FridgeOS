import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';

/// Outcome of a previous barcode lookup, used to avoid repeat remote queries
/// (FR-BAR-6).
enum BarcodeLookupResult { found, notFound }

final class BarcodeLookup {
  const BarcodeLookup({
    required this.barcode,
    required this.result,
    required this.fetchedAt,
    this.productId,
    this.ttlUntil,
  });

  final Barcode barcode;
  final BarcodeLookupResult result;
  final String? productId;
  final DateTime fetchedAt;
  final DateTime? ttlUntil;

  bool isFresh(DateTime now) {
    final ttl = ttlUntil;
    if (ttl == null) return true;
    return !now.isAfter(ttl);
  }
}

abstract interface class BarcodeLookupRepository {
  Future<Result<BarcodeLookup?>> find(Barcode barcode);
  Future<Result<void>> upsert(BarcodeLookup lookup);
}
