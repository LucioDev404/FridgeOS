import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/services/shopping_list_qr_codec.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

void main() {
  const codec = ShoppingListQrCodec();
  final now = DateTime.utc(2026, 7, 18);

  group('ShoppingListQrCodec', () {
    test('encodes pending items without internal ids', () {
      final payload = codec.encodePending([
        ShoppingListItem(
          id: 'secret-id',
          name: 'Milk',
          productId: 'product-secret',
          quantity: Quantity(2, MeasurementUnit.pieces),
          origin: ShoppingItemOrigin.manual,
          status: ShoppingItemStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
        ShoppingListItem(
          id: 'done-id',
          name: 'Butter',
          origin: ShoppingItemOrigin.manual,
          status: ShoppingItemStatus.done,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final json = payload.toJson();
      expect(json['version'], 1);
      expect(json['type'], kShoppingListQrType);
      expect(json['items'], [
        {'name': 'Milk', 'quantity': 2.0},
      ]);
      final encoded = payload.encode();
      expect(encoded.contains('secret-id'), isFalse);
      expect(encoded.contains('product-secret'), isFalse);
    });

    test('parses valid QR JSON and round-trips', () {
      const raw =
          '{"version":1,"items":[{"name":"Milk","quantity":2},{"name":"Eggs","quantity":12}]}';
      final result = codec.decode(raw);
      expect(result.isSuccess, isTrue);
      final payload = result.valueOrNull!;
      expect(payload.items, hasLength(2));
      expect(payload.items.first.name, 'Milk');
      expect(payload.items.first.quantity, 2);
      expect(payload.items.last.name, 'Eggs');
      expect(payload.items.last.quantity, 12);

      final again = codec.decode(payload.encode());
      expect(again.isSuccess, isTrue);
      expect(again.valueOrNull!.items.length, 2);
    });

    test('rejects malformed JSON', () {
      final result = codec.decode('{not-json');
      expect(result.isFailure, isTrue);
    });

    test('rejects unsupported versions', () {
      final result = codec.decode(
        '{"version":99,"items":[{"name":"Milk","quantity":1}]}',
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('Unsupported'));
    });

    test('rejects payloads with forbidden identity fields', () {
      final result = codec.decode(
        '{"version":1,"userId":"u1","items":[{"name":"Milk","quantity":1}]}',
      );
      expect(result.isFailure, isTrue);
    });

    test('rejects item objects that include productId', () {
      final result = codec.decode(
        '{"version":1,"items":[{"name":"Milk","quantity":1,"productId":"x"}]}',
      );
      expect(result.isFailure, isTrue);
    });

    test('rejects empty item lists', () {
      final result = codec.decode('{"version":1,"items":[]}');
      expect(result.isFailure, isTrue);
    });
  });
}
