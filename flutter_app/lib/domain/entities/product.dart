import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// A distinct food article (catalog concept), optionally identified by a
/// [Barcode]. Product identity/metadata is stable and reusable; concrete stock
/// is modelled separately by `InventoryItem` (see docs/05-domain-model.md §2).
final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.brand,
    this.imageUrl,
    this.deletedAt,
  });

  final String id;
  final Barcode? barcode;
  final String name;
  final String? brand;
  final FoodCategory category;
  final MeasurementUnit defaultUnit;
  final ProductSource source;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone (see docs/06-database-design.md §1).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? brand,
    bool clearBrand = false,
    FoodCategory? category,
    MeasurementUnit? defaultUnit,
    ProductSource? source,
    Barcode? barcode,
    bool clearBarcode = false,
    String? imageUrl,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: clearBrand ? null : (brand ?? this.brand),
      category: category ?? this.category,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      source: source ?? this.source,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.barcode == barcode &&
      other.name == name &&
      other.brand == brand &&
      other.category == category &&
      other.defaultUnit == defaultUnit &&
      other.source == source &&
      other.imageUrl == imageUrl &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    barcode,
    name,
    brand,
    category,
    defaultUnit,
    source,
    imageUrl,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
