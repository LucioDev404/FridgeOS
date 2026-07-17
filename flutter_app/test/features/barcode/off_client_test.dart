import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/features/barcode/data/open_food_facts_client.dart';

void main() {
  const parser = OffProductParser(InputSanitizer());
  final barcode = Barcode.parse('4006381333931');

  test('parses a valid OFF product payload', () {
    final result = parser.parse(
      barcode: barcode,
      json: {
        'status': 1,
        'product': {
          'product_name': 'Organic Milk',
          'brands': 'Farm Co',
          'categories_tags': ['en:dairy'],
          'image_front_url': 'https://example.com/milk.jpg',
        },
      },
    );
    expect(result.isSuccess, isTrue);
    final draft = result.valueOrNull!;
    expect(draft.name, 'Organic Milk');
    expect(draft.brand, 'Farm Co');
    expect(draft.category.wire, 'dairy');
  });

  test('status 0 means not found', () {
    final result = parser.parse(barcode: barcode, json: {'status': 0});
    expect(result.valueOrNull, isNull);
  });

  test('hostile empty name is treated as not found', () {
    final result = parser.parse(
      barcode: barcode,
      json: {
        'status': 1,
        'product': {'product_name': '   '},
      },
    );
    expect(result.valueOrNull, isNull);
  });

  test('strips control characters from remote fields', () {
    final result = parser.parse(
      barcode: barcode,
      json: {
        'status': 1,
        'product': {
          'product_name': 'Milk\u0000Drink',
          'brands': 'Brand\u0007X',
        },
      },
    );
    expect(result.valueOrNull!.name, 'MilkDrink');
    expect(result.valueOrNull!.brand, 'BrandX');
  });

  test('HttpOpenFoodFactsClient does not call network when faked', () async {
    var calls = 0;
    final client = HttpOpenFoodFactsClient(
      parser: parser,
      httpGet: (uri, {headers}) async {
        calls++;
        expect(uri.scheme, 'https');
        expect(uri.host, 'world.openfoodfacts.org');
        return (
          statusCode: 200,
          body: jsonEncode({
            'status': 1,
            'product': {'product_name': 'Juice', 'brands': 'X'},
          }),
        );
      },
    );
    final result = await client.fetchByBarcode(barcode);
    expect(calls, 1);
    expect(result.valueOrNull!.name, 'Juice');
  });

  test('HttpOpenFoodFactsClient maps 404 to null', () async {
    final client = HttpOpenFoodFactsClient(
      parser: parser,
      httpGet: (uri, {headers}) async => (statusCode: 404, body: ''),
    );
    final result = await client.fetchByBarcode(barcode);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });
}
