import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/services/shopping_list_export.dart';
import 'package:fridgeos/domain/services/shopping_list_qr_codec.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/domain/value_objects/quantity.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18);
  const formatter = ShoppingListExportFormatter();
  const codec = ShoppingListQrCodec();

  List<ShoppingListItem> sample() => [
    ShoppingListItem(
      id: '1',
      name: 'Tomatoes',
      quantity: Quantity(5, MeasurementUnit.pieces),
      origin: ShoppingItemOrigin.manual,
      status: ShoppingItemStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
    ShoppingListItem(
      id: '2',
      name: 'Milk',
      quantity: Quantity(2, MeasurementUnit.pieces),
      origin: ShoppingItemOrigin.manual,
      status: ShoppingItemStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  test('groups shopping items into grocery categories', () {
    final groups = formatter.groupByCategory(sample());
    expect(groups.keys, containsAll(['Produce', 'Dairy']));
    expect(groups['Produce']!.single.name, 'Tomatoes');
    expect(groups['Dairy']!.single.name, 'Milk');
  });

  test('todo text export never contains JSON braces', () {
    final text = formatter.toTodoText(sample());
    expect(text.contains('{'), isFalse);
    expect(text.contains('version'), isFalse);
    expect(text, contains('Shopping List'));
    expect(text, contains('- [ ] Tomatoes'));
    expect(text, contains('- [ ] Milk'));
  });

  test('human-readable QR payload is not JSON', () {
    final qr = formatter.toHumanReadableQr(sample());
    expect(qr.startsWith('{'), isFalse);
    expect(qr, contains('FridgeOS Shopping'));
    expect(qr, contains('Tomatoes'));
  });

  test('codec parses human-readable QR lists', () {
    final result = codec.decode('''
FridgeOS Shopping
• Milk x2
• Eggs
''');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.items.map((i) => i.name), ['Milk', 'Eggs']);
    expect(result.valueOrNull!.items.first.quantity, 2);
  });

  test('codec still accepts structured JSON for device import', () {
    final result = codec.decode(
      '{"version":1,"items":[{"name":"Milk","quantity":2}]}',
    );
    expect(result.isSuccess, isTrue);
  });

  test('codec rejects unsupported JSON versions', () {
    final result = codec.decode(
      '{"version":99,"items":[{"name":"Milk","quantity":1}]}',
    );
    expect(result.isFailure, isTrue);
  });
}
