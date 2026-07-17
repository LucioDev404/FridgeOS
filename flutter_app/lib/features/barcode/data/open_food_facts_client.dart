import 'dart:convert';

import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Product data returned by OpenFoodFacts enrichment (before persistence).
final class OffProductDraft {
  const OffProductDraft({
    required this.barcode,
    required this.name,
    this.brand,
    this.category = FoodCategory.other,
    this.defaultUnit = MeasurementUnit.pieces,
    this.imageUrl,
  });

  final Barcode barcode;
  final String name;
  final String? brand;
  final FoodCategory category;
  final MeasurementUnit defaultUnit;
  final String? imageUrl;

  Product toProduct({required String id, required DateTime now}) => Product(
    id: id,
    barcode: barcode,
    name: name,
    brand: brand,
    category: category,
    defaultUnit: defaultUnit,
    source: ProductSource.openFoodFacts,
    imageUrl: imageUrl,
    createdAt: now,
    updatedAt: now,
  );
}

/// HTTPS client for OpenFoodFacts product lookup (docs/09-security-design.md).
abstract interface class OpenFoodFactsClient {
  Future<Result<OffProductDraft?>> fetchByBarcode(Barcode barcode);
}

/// Parses and sanitizes an OFF v2 product payload into a draft, or null when
/// the product is missing / unusable (AC-BAR-5).
final class OffProductParser {
  const OffProductParser(this._sanitizer);

  final InputSanitizer _sanitizer;

  Result<OffProductDraft?> parse({
    required Barcode barcode,
    required Map<String, Object?> json,
  }) {
    final status = json['status'];
    if (status is num && status.toInt() == 0) {
      return const Result.success(null);
    }
    final product = json['product'];
    if (product is! Map) {
      return const Result.success(null);
    }
    final map = product.cast<String, Object?>();

    final rawName =
        (map['product_name'] as String?) ??
        (map['generic_name'] as String?) ??
        '';
    final nameResult = _sanitizer.requireText(
      rawName,
      maxLength: 200,
      fieldName: 'product_name',
    );
    if (nameResult.isFailure) {
      return const Result.success(null);
    }

    final brandResult = _sanitizer.optionalText(
      map['brands'] as String?,
      maxLength: 120,
      fieldName: 'brands',
    );
    if (brandResult.isFailure) {
      return Result.failure(brandResult.failureOrNull!);
    }

    final imageResult = _sanitizer.optionalText(
      map['image_front_url'] as String? ?? map['image_url'] as String?,
      maxLength: 500,
      fieldName: 'image_url',
    );
    if (imageResult.isFailure) {
      return Result.failure(imageResult.failureOrNull!);
    }

    final imageUrl = imageResult.valueOrNull;
    if (imageUrl != null &&
        !(imageUrl.startsWith('https://') || imageUrl.startsWith('http://'))) {
      return const Result.failure(
        ValidationFailure('Remote image URL must be http(s)'),
      );
    }

    return Result.success(
      OffProductDraft(
        barcode: barcode,
        name: nameResult.valueOrNull!,
        brand: brandResult.valueOrNull,
        category: _guessCategory(map),
        imageUrl: imageUrl,
      ),
    );
  }

  FoodCategory _guessCategory(Map<String, Object?> product) {
    final tags = <String>[];
    final categories = product['categories_tags'];
    if (categories is List) {
      for (final tag in categories) {
        if (tag is String) tags.add(tag.toLowerCase());
      }
    }
    final blob = tags.join(' ');
    if (blob.contains('dairy') || blob.contains('milk')) {
      return FoodCategory.dairy;
    }
    if (blob.contains('meat') || blob.contains('fish')) {
      return FoodCategory.meat;
    }
    if (blob.contains('beverage') || blob.contains('drink')) {
      return FoodCategory.beverages;
    }
    if (blob.contains('bread') || blob.contains('bakery')) {
      return FoodCategory.bakery;
    }
    if (blob.contains('frozen')) return FoodCategory.frozen;
    if (blob.contains('fruit') || blob.contains('vegetable')) {
      return FoodCategory.produce;
    }
    return FoodCategory.other;
  }
}

/// Live OpenFoodFacts HTTPS client. Single egress host.
final class HttpOpenFoodFactsClient implements OpenFoodFactsClient {
  HttpOpenFoodFactsClient({
    required this.httpGet,
    required this.parser,
    this.baseUrl = 'https://world.openfoodfacts.org',
    this.userAgent = 'FridgeOS/1.0 (https://github.com/LucioDev404/FridgeOS)',
  });

  /// Injected GET so tests never hit the network.
  final Future<({int statusCode, String body})> Function(
    Uri uri, {
    Map<String, String>? headers,
  })
  httpGet;

  final OffProductParser parser;
  final String baseUrl;
  final String userAgent;

  @override
  Future<Result<OffProductDraft?>> fetchByBarcode(Barcode barcode) async {
    final uri = Uri.parse(
      '$baseUrl/api/v2/product/${barcode.value}.json'
      '?fields=product_name,generic_name,brands,categories_tags,'
      'image_front_url,image_url',
    );
    try {
      final response = await httpGet(
        uri,
        headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
      );
      if (response.statusCode == 404) {
        return const Result.success(null);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Result.failure(
          NetworkFailure('OpenFoodFacts HTTP ${response.statusCode}'),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const Result.failure(
          NetworkFailure('OpenFoodFacts returned invalid JSON'),
        );
      }
      return parser.parse(
        barcode: barcode,
        json: decoded.cast<String, Object?>(),
      );
    } on Object catch (e) {
      return Result.failure(NetworkFailure('OpenFoodFacts request failed: $e'));
    }
  }
}
