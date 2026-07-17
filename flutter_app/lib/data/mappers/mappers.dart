import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fridgeos/domain/entities/inventory_event.dart';
import 'package:fridgeos/domain/entities/inventory_item.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';

/// Pure mapping functions between Drift row types and domain entities.
///
/// The data layer depends on the domain (dependencies point inward); these
/// mappers are the single place that knows both representations. Timestamps are
/// stored as UTC epoch milliseconds.

DateTime _dateTimeFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int _msFromDateTime(DateTime dt) => dt.toUtc().millisecondsSinceEpoch;

// ---------------------------------------------------------------------------
// Product
// ---------------------------------------------------------------------------

Product productFromRow(ProductRow row) => Product(
  id: row.id,
  barcode: row.barcode == null ? null : Barcode.tryParse(row.barcode),
  name: row.name,
  brand: row.brand,
  category: FoodCategory.fromWire(row.category),
  defaultUnit: MeasurementUnit.fromWire(row.defaultUnit),
  source: ProductSource.fromWire(row.source),
  imageUrl: row.imageUrl,
  createdAt: _dateTimeFromMs(row.createdAt),
  updatedAt: _dateTimeFromMs(row.updatedAt),
  deletedAt: row.deletedAt == null ? null : _dateTimeFromMs(row.deletedAt!),
);

ProductsCompanion productToCompanion(Product product) => ProductsCompanion(
  id: Value(product.id),
  barcode: Value(product.barcode?.value),
  name: Value(product.name),
  brand: Value(product.brand),
  category: Value(product.category.wire),
  defaultUnit: Value(product.defaultUnit.wire),
  source: Value(product.source.wire),
  imageUrl: Value(product.imageUrl),
  createdAt: Value(_msFromDateTime(product.createdAt)),
  updatedAt: Value(_msFromDateTime(product.updatedAt)),
  deletedAt: Value(
    product.deletedAt == null ? null : _msFromDateTime(product.deletedAt!),
  ),
);

// ---------------------------------------------------------------------------
// Location
// ---------------------------------------------------------------------------

Location locationFromRow(LocationRow row) => Location(
  id: row.id,
  name: row.name,
  type: LocationType.fromWire(row.type),
  shelfLifeBonusDays: row.shelfLifeBonusDays,
  createdAt: _dateTimeFromMs(row.createdAt),
  updatedAt: _dateTimeFromMs(row.updatedAt),
  deletedAt: row.deletedAt == null ? null : _dateTimeFromMs(row.deletedAt!),
);

LocationsCompanion locationToCompanion(Location location) => LocationsCompanion(
  id: Value(location.id),
  name: Value(location.name),
  type: Value(location.type.wire),
  shelfLifeBonusDays: Value(location.shelfLifeBonusDays),
  createdAt: Value(_msFromDateTime(location.createdAt)),
  updatedAt: Value(_msFromDateTime(location.updatedAt)),
  deletedAt: Value(
    location.deletedAt == null ? null : _msFromDateTime(location.deletedAt!),
  ),
);

// ---------------------------------------------------------------------------
// InventoryItem
// ---------------------------------------------------------------------------

InventoryItem inventoryItemFromRow(InventoryItemRow row) => InventoryItem(
  id: row.id,
  productId: row.productId,
  locationId: row.locationId,
  quantity: Quantity(
    row.quantityAmount,
    MeasurementUnit.fromWire(row.quantityUnit),
  ),
  expirationDate: row.expirationDate == null
      ? null
      : DateOnly.parseIso(row.expirationDate!),
  lowStockThreshold: row.lowStockThreshold,
  note: row.note,
  createdAt: _dateTimeFromMs(row.createdAt),
  updatedAt: _dateTimeFromMs(row.updatedAt),
  deletedAt: row.deletedAt == null ? null : _dateTimeFromMs(row.deletedAt!),
);

InventoryItemsCompanion inventoryItemToCompanion(InventoryItem item) =>
    InventoryItemsCompanion(
      id: Value(item.id),
      productId: Value(item.productId),
      locationId: Value(item.locationId),
      quantityAmount: Value(item.quantity.amount),
      quantityUnit: Value(item.quantity.unit.wire),
      expirationDate: Value(item.expirationDate?.toIso()),
      lowStockThreshold: Value(item.lowStockThreshold),
      note: Value(item.note),
      createdAt: Value(_msFromDateTime(item.createdAt)),
      updatedAt: Value(_msFromDateTime(item.updatedAt)),
      deletedAt: Value(
        item.deletedAt == null ? null : _msFromDateTime(item.deletedAt!),
      ),
    );

// ---------------------------------------------------------------------------
// InventoryEvent
// ---------------------------------------------------------------------------

InventoryEvent inventoryEventFromRow(InventoryEventRow row) => InventoryEvent(
  id: row.id,
  type: InventoryEventType.fromWire(row.type),
  occurredAt: _dateTimeFromMs(row.occurredAt),
  productId: row.productId,
  inventoryItemId: row.inventoryItemId,
  locationId: row.locationId,
  fromLocationId: row.fromLocationId,
  toLocationId: row.toLocationId,
  quantityDelta: row.quantityDelta,
  quantityBefore: row.quantityBefore,
  quantityAfter: row.quantityAfter,
  reason: row.reason,
  metadata: _decodeMetadata(row.metadataJson),
);

InventoryEventsCompanion inventoryEventToCompanion(InventoryEvent event) =>
    InventoryEventsCompanion(
      id: Value(event.id),
      type: Value(event.type.wire),
      occurredAt: Value(_msFromDateTime(event.occurredAt)),
      productId: Value(event.productId),
      inventoryItemId: Value(event.inventoryItemId),
      locationId: Value(event.locationId),
      fromLocationId: Value(event.fromLocationId),
      toLocationId: Value(event.toLocationId),
      quantityDelta: Value(event.quantityDelta),
      quantityBefore: Value(event.quantityBefore),
      quantityAfter: Value(event.quantityAfter),
      reason: Value(event.reason),
      metadataJson: Value(_encodeMetadata(event.metadata)),
    );

Map<String, String> _decodeMetadata(String? json) {
  if (json == null || json.isEmpty) return const <String, String>{};
  final decoded = jsonDecode(json);
  if (decoded is! Map) return const <String, String>{};
  return decoded.map((key, value) => MapEntry('$key', '$value'));
}

String? _encodeMetadata(Map<String, String> metadata) =>
    metadata.isEmpty ? null : jsonEncode(metadata);
