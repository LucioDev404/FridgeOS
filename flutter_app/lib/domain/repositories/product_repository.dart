import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/product.dart';

/// Contract for reading and persisting catalog [Product]s. Implemented in the
/// data layer over Drift (see docs/07-architecture.md §1).
abstract interface class ProductRepository {
  /// Returns the product with [id], or `null` when absent/soft-deleted.
  Future<Result<Product?>> findById(String id);

  /// Returns the product cached for [barcode], or `null` when not cached.
  Future<Result<Product?>> findByBarcode(String barcode);

  /// Emits the current set of non-deleted products, updating on change.
  Stream<List<Product>> watchAll();

  /// Inserts or updates [product].
  Future<Result<void>> upsert(Product product);

  /// Soft-deletes the product with [id].
  Future<Result<void>> softDelete(String id, DateTime deletedAt);
}
