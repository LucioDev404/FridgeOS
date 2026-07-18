import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

/// Application-layer use cases for the inventory feature. Orchestrates the
/// domain [InventoryMutationService] with the repositories, applying input
/// validation at the boundary (docs/07-architecture.md §1, FR-INV-*).
///
/// Every method returns a [Result]; callers surface failures in the UI without
/// exceptions crossing the layer boundary.
final class InventoryActions {
  const InventoryActions({
    required this.products,
    required this.inventory,
    required this.mutations,
    required this.sanitizer,
    required this.clock,
    required this.ids,
  });

  final ProductRepository products;
  final InventoryRepository inventory;
  final InventoryMutationService mutations;
  final InputSanitizer sanitizer;
  final Clock clock;
  final IdGenerator ids;

  /// Creates a manually-entered product and its initial stock in one step.
  Future<Result<void>> addManualItem({
    required String name,
    required FoodCategory category,
    required MeasurementUnit unit,
    required double amount,
    required String locationId,
    String? brand,
    String? barcode,
    DateOnly? expirationDate,
    double? lowStockThreshold,
    String? note,
  }) async {
    final nameResult = sanitizer.requireText(
      name,
      maxLength: 200,
      fieldName: 'name',
    );
    if (nameResult.isFailure) return _fail(nameResult.failureOrNull!);

    final brandResult = sanitizer.optionalText(brand, maxLength: 120);
    if (brandResult.isFailure) return _fail(brandResult.failureOrNull!);

    final noteResult = sanitizer.optionalText(note, maxLength: 500);
    if (noteResult.isFailure) return _fail(noteResult.failureOrNull!);

    final barcodeResult = _parseOptionalBarcode(barcode);
    if (barcodeResult.isFailure) return _fail(barcodeResult.failureOrNull!);

    if (amount <= 0) {
      return const Result.failure(
        ValidationFailure('Quantity must be greater than zero'),
      );
    }

    final now = clock.nowUtc();
    final product = Product(
      id: ids.newId(),
      name: nameResult.valueOrNull!,
      brand: brandResult.valueOrNull,
      barcode: barcodeResult.valueOrNull,
      category: category,
      defaultUnit: unit,
      source: ProductSource.manual,
      createdAt: now,
      updatedAt: now,
    );

    final upsert = await products.upsert(product);
    if (upsert.isFailure) return upsert;

    final mutation = mutations.createItem(
      productId: product.id,
      locationId: locationId,
      quantity: Quantity(amount, unit),
      expirationDate: expirationDate,
      lowStockThreshold: lowStockThreshold,
      note: noteResult.valueOrNull,
    );
    return inventory.applyMutation(mutation);
  }

  /// Adds stock of an existing [product] into [locationId] (used by the scan
  /// flow in Phase 5 and by "restock" actions).
  Future<Result<void>> addStockForProduct({
    required Product product,
    required MeasurementUnit unit,
    required double amount,
    required String locationId,
    DateOnly? expirationDate,
    double? lowStockThreshold,
    String? note,
  }) async {
    if (amount <= 0) {
      return const Result.failure(
        ValidationFailure('Quantity must be greater than zero'),
      );
    }
    final upsert = await products.upsert(product);
    if (upsert.isFailure) return upsert;

    final mutation = mutations.createItem(
      productId: product.id,
      locationId: locationId,
      quantity: Quantity(amount, unit),
      expirationDate: expirationDate,
      lowStockThreshold: lowStockThreshold,
      note: note,
    );
    return inventory.applyMutation(mutation);
  }

  /// Updates product catalog fields and inventory item metadata. Quantity and
  /// location changes append immutable events; metadata updates only the
  /// current snapshot and never rewrite history.
  Future<Result<void>> updateItemDetails({
    required Product product,
    required InventoryItem item,
    required String name,
    required FoodCategory category,
    required MeasurementUnit unit,
    required double amount,
    required String locationId,
    String? brand,
    String? barcode,
    DateOnly? expirationDate,
    double? lowStockThreshold,
    String? note,
  }) async {
    if (!item.isActive) {
      return const Result.failure(
        ValidationFailure('Cannot modify a removed inventory item'),
      );
    }

    final nameResult = sanitizer.requireText(
      name,
      maxLength: 200,
      fieldName: 'name',
    );
    if (nameResult.isFailure) return _fail(nameResult.failureOrNull!);

    final brandResult = sanitizer.optionalText(brand, maxLength: 120);
    if (brandResult.isFailure) return _fail(brandResult.failureOrNull!);

    final noteResult = sanitizer.optionalText(note, maxLength: 500);
    if (noteResult.isFailure) return _fail(noteResult.failureOrNull!);

    final barcodeResult = _parseOptionalBarcode(barcode);
    if (barcodeResult.isFailure) return _fail(barcodeResult.failureOrNull!);

    if (amount < 0) {
      return const Result.failure(
        ValidationFailure('Quantity cannot be negative'),
      );
    }

    final now = clock.nowUtc();
    final parsedBarcode = barcodeResult.valueOrNull;
    final updatedProduct = product.copyWith(
      name: nameResult.valueOrNull!,
      brand: brandResult.valueOrNull,
      clearBrand: brandResult.valueOrNull == null,
      category: category,
      defaultUnit: unit,
      barcode: parsedBarcode,
      clearBarcode: parsedBarcode == null,
      updatedAt: now,
    );
    final productUpsert = await products.upsert(updatedProduct);
    if (productUpsert.isFailure) return productUpsert;

    var working = item;
    if (locationId != item.locationId) {
      final moved = await move(item: working, toLocationId: locationId);
      if (moved.isFailure) return moved;
      final refreshed = await inventory.findById(item.id);
      if (refreshed.isFailure) return _fail(refreshed.failureOrNull!);
      working = refreshed.valueOrNull ?? working;
    }

    if (amount != working.quantity.amount) {
      final qty = await setQuantity(item: working, targetAmount: amount);
      if (qty.isFailure) return qty;
      final refreshed = await inventory.findById(item.id);
      if (refreshed.isFailure) return _fail(refreshed.failureOrNull!);
      working = refreshed.valueOrNull ?? working;
    }

    final snapshot = working.copyWith(
      expirationDate: expirationDate,
      clearExpirationDate: expirationDate == null,
      lowStockThreshold: lowStockThreshold,
      clearLowStockThreshold: lowStockThreshold == null,
      note: noteResult.valueOrNull,
      clearNote: noteResult.valueOrNull == null,
      quantity: Quantity(working.quantity.amount, unit),
      updatedAt: now,
    );
    return inventory.updateItemSnapshot(snapshot);
  }

  /// Applies a signed [delta] (in the item's unit) to [item].
  ///
  /// Positive deltas are recorded as [InventoryEventType.restock]; negative
  /// deltas remain [InventoryEventType.updateQuantity] unless an explicit
  /// [type] is provided.
  Future<Result<void>> adjust({
    required InventoryItem item,
    required double delta,
    InventoryEventType? type,
  }) {
    final resolvedType =
        type ??
        (delta > 0
            ? InventoryEventType.restock
            : InventoryEventType.updateQuantity);
    final mutation = mutations.applyQuantityDelta(
      item: item,
      deltaAmount: delta,
      type: resolvedType,
    );
    return _applyOrFail(mutation);
  }

  /// Sets the item's quantity to an absolute [targetAmount], recording a
  /// [InventoryEventType.manualCorrection] (or [type] when provided).
  Future<Result<void>> setQuantity({
    required InventoryItem item,
    required double targetAmount,
    InventoryEventType type = InventoryEventType.manualCorrection,
  }) {
    if (targetAmount < 0) {
      return Future.value(
        const Result.failure(ValidationFailure('Quantity cannot be negative')),
      );
    }
    final delta = targetAmount - item.quantity.amount;
    if (delta == 0) return Future.value(const Result.success(null));
    return adjust(item: item, delta: delta, type: type);
  }

  /// Consumes [amount] of [item], recording a CONSUME event.
  Future<Result<void>> consume({
    required InventoryItem item,
    required double amount,
  }) => _applyOrFail(mutations.consume(item: item, amount: amount));

  /// Discards [amount] of [item] as waste, recording a DISCARD event.
  Future<Result<void>> discard({
    required InventoryItem item,
    required double amount,
  }) => _applyOrFail(mutations.discard(item: item, amount: amount));

  /// Removes [item] entirely, recording a REMOVE_PRODUCT event.
  Future<Result<void>> remove({required InventoryItem item}) =>
      _applyOrFail(mutations.removeAll(item: item));

  /// Moves [item] to [toLocationId], recording a CHANGE_LOCATION event.
  Future<Result<void>> move({
    required InventoryItem item,
    required String toLocationId,
  }) => _applyOrFail(
    mutations.changeLocation(item: item, toLocationId: toLocationId),
  );

  Result<Barcode?> _parseOptionalBarcode(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return const Result.success(null);
    final parsed = Barcode.tryParse(trimmed);
    if (parsed == null) {
      return const Result.failure(ValidationFailure('Invalid barcode'));
    }
    return Result.success(parsed);
  }

  Future<Result<void>> _applyOrFail(Result<InventoryMutation> mutation) async {
    if (mutation.isFailure) return _fail(mutation.failureOrNull!);
    return inventory.applyMutation(mutation.valueOrNull!);
  }

  Result<void> _fail(Failure failure) => Result.failure(failure);
}
