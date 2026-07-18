import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Formats pending shopping items for human-friendly export (image / Todo apps).
///
/// Never exposes raw JSON to end users.
final class ShoppingListExportFormatter {
  const ShoppingListExportFormatter();

  static const _categoryOrder = [
    'Produce',
    'Dairy',
    'Meat & seafood',
    'Pantry',
    'Bakery',
    'Frozen',
    'Beverages',
    'Other',
  ];

  /// Groups items into grocery-style categories by simple name heuristics.
  Map<String, List<ShoppingListItem>> groupByCategory(
    List<ShoppingListItem> items,
  ) {
    final pending = items
        .where((i) => !i.isDeleted && i.status == ShoppingItemStatus.pending)
        .toList();
    final groups = <String, List<ShoppingListItem>>{
      for (final c in _categoryOrder) c: <ShoppingListItem>[],
    };
    for (final item in pending) {
      groups[_categoryFor(item.name)]!.add(item);
    }
    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }

  /// Plain-text checklist suitable for Android Todo / Notes / messaging apps.
  String toTodoText(List<ShoppingListItem> items) {
    final buffer = StringBuffer('Shopping List\n');
    final groups = groupByCategory(items);
    for (final entry in groups.entries) {
      buffer.writeln();
      buffer.writeln(entry.key);
      for (final item in entry.value) {
        final qty = item.quantity;
        if (qty == null) {
          buffer.writeln('- [ ] ${item.name}');
        } else {
          buffer.writeln('- [ ] ${item.name} x${_trimAmount(qty.amount)}');
        }
      }
    }
    return buffer.toString().trimRight();
  }

  /// Compact human-readable payload for optional QR display (not JSON).
  String toHumanReadableQr(List<ShoppingListItem> items) {
    final lines = <String>['FridgeOS Shopping'];
    for (final item in items.where(
      (i) => !i.isDeleted && i.status == ShoppingItemStatus.pending,
    )) {
      final qty = item.quantity;
      lines.add(
        qty == null
            ? '• ${item.name}'
            : '• ${item.name} x${_trimAmount(qty.amount)}',
      );
    }
    return lines.join('\n');
  }

  String _categoryFor(String name) {
    final n = name.toLowerCase();
    if (_matches(n, const [
      'tomato',
      'lettuce',
      'onion',
      'garlic',
      'mushroom',
      'carrot',
      'pepper',
      'spinach',
      'cucumber',
      'potato',
      'fruit',
      'berry',
      'apple',
      'banana',
      'lemon',
      'lime',
      'herb',
      'basil',
      'cilantro',
      'vegetable',
    ])) {
      return 'Produce';
    }
    if (_matches(n, const [
      'milk',
      'cheese',
      'yogurt',
      'yoghurt',
      'butter',
      'cream',
      'egg',
    ])) {
      return 'Dairy';
    }
    if (_matches(n, const [
      'chicken',
      'beef',
      'pork',
      'fish',
      'salmon',
      'shrimp',
      'bacon',
      'guanciale',
      'pancetta',
      'tofu',
      'meat',
    ])) {
      return 'Meat & seafood';
    }
    if (_matches(n, const ['bread', 'bagel', 'bun', 'baguette', 'tortilla'])) {
      return 'Bakery';
    }
    if (_matches(n, const ['frozen', 'ice cream'])) {
      return 'Frozen';
    }
    if (_matches(n, const [
      'juice',
      'soda',
      'water',
      'coffee',
      'tea',
      'wine',
      'beer',
    ])) {
      return 'Beverages';
    }
    if (_matches(n, const [
      'pasta',
      'rice',
      'oil',
      'salt',
      'pepper',
      'flour',
      'sugar',
      'sauce',
      'bean',
      'lentil',
      'spice',
      'noodle',
      'miso',
      'soy',
      'vinegar',
      'honey',
    ])) {
      return 'Pantry';
    }
    return 'Other';
  }

  bool _matches(String name, List<String> needles) {
    for (final needle in needles) {
      if (name == needle || name.contains(needle)) return true;
    }
    return false;
  }

  String _trimAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toString();
  }
}
