import 'dart:convert';

import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Supported shopping-list QR payload version.
const int kShoppingListQrVersion = 1;

/// Marker distinguishing FridgeOS shopping QR payloads from arbitrary JSON.
const String kShoppingListQrType = 'fridgeos.shopping_list';

/// A validated, shareable shopping-list line (no internal IDs).
final class ShoppingListQrItem {
  const ShoppingListQrItem({required this.name, this.quantity});

  final String name;
  final double? quantity;

  Map<String, Object?> toJson() => {
    'name': name,
    if (quantity != null) 'quantity': quantity,
  };

  static Result<ShoppingListQrItem> fromJson(Object? raw) {
    if (raw is! Map) {
      return const Result.failure(
        ValidationFailure('Shopping QR item must be an object'),
      );
    }
    final map = Map<String, Object?>.from(raw);
    final nameRaw = map['name'];
    if (nameRaw is! String) {
      return const Result.failure(
        ValidationFailure('Shopping QR item requires a string name'),
      );
    }
    final name = nameRaw.trim();
    if (name.isEmpty || name.length > 200) {
      return const Result.failure(
        ValidationFailure('Shopping QR item name is invalid'),
      );
    }
    // Reject unexpected identity / PII fields.
    for (final forbidden in const [
      'id',
      'productId',
      'userId',
      'email',
      'deviceId',
    ]) {
      if (map.containsKey(forbidden)) {
        return Result.failure(
          ValidationFailure('Shopping QR item must not include $forbidden'),
        );
      }
    }

    double? quantity;
    final quantityRaw = map['quantity'];
    if (quantityRaw != null) {
      if (quantityRaw is! num) {
        return const Result.failure(
          ValidationFailure('Shopping QR quantity must be a number'),
        );
      }
      quantity = quantityRaw.toDouble();
      if (quantity <= 0 || quantity > 100000) {
        return const Result.failure(
          ValidationFailure('Shopping QR quantity is out of range'),
        );
      }
    }

    return Result.success(ShoppingListQrItem(name: name, quantity: quantity));
  }
}

/// Offline shopping-list QR payload (versioned JSON).
final class ShoppingListQrPayload {
  const ShoppingListQrPayload({
    required this.items,
    this.version = kShoppingListQrVersion,
  });

  final int version;
  final List<ShoppingListQrItem> items;

  Map<String, Object?> toJson() => {
    'version': version,
    'type': kShoppingListQrType,
    'items': [for (final item in items) item.toJson()],
  };

  String encode() => jsonEncode(toJson());
}

/// Encodes and decodes shopping-list QR payloads without database identifiers.
final class ShoppingListQrCodec {
  const ShoppingListQrCodec();

  /// Builds a payload from pending shopping rows (name + optional quantity only).
  ShoppingListQrPayload encodePending(List<ShoppingListItem> items) {
    final pending = items.where(
      (i) => !i.isDeleted && i.status == ShoppingItemStatus.pending,
    );
    return ShoppingListQrPayload(
      items: [
        for (final item in pending)
          ShoppingListQrItem(name: item.name, quantity: item.quantity?.amount),
      ],
    );
  }

  /// Parses and validates a QR string. Accepts JSON v1 or human-readable lists.
  Result<ShoppingListQrPayload> decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(ValidationFailure('Shopping QR is empty'));
    }
    if (trimmed.length > 4000) {
      return const Result.failure(
        ValidationFailure('Shopping QR payload is too large'),
      );
    }

    if (trimmed.startsWith('{')) {
      return _decodeJson(trimmed);
    }
    return _decodeHumanReadable(trimmed);
  }

  Result<ShoppingListQrPayload> _decodeHumanReadable(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const Result.failure(ValidationFailure('Shopping QR is empty'));
    }

    final items = <ShoppingListQrItem>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('fridgeos') || lower == 'shopping list') {
        continue;
      }
      var cleaned = line
          .replaceFirst(RegExp(r'^[-•*☐]\s*'), '')
          .replaceFirst(RegExp(r'^\[\s*\]\s*'), '')
          .trim();
      if (cleaned.isEmpty) continue;

      double? quantity;
      final qtyMatch = RegExp(
        r'^(.*?)(?:\s*[x×]\s*(\d+(?:\.\d+)?))\s*$',
        caseSensitive: false,
      ).firstMatch(cleaned);
      if (qtyMatch != null) {
        cleaned = qtyMatch.group(1)!.trim();
        quantity = double.tryParse(qtyMatch.group(2)!);
      }
      if (cleaned.isEmpty || cleaned.length > 200) continue;
      items.add(ShoppingListQrItem(name: cleaned, quantity: quantity));
    }

    if (items.isEmpty) {
      return const Result.failure(
        ValidationFailure('Shopping QR has no items'),
      );
    }
    return Result.success(ShoppingListQrPayload(items: items));
  }

  Result<ShoppingListQrPayload> _decodeJson(String trimmed) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return const Result.failure(
        ValidationFailure('Shopping QR is not valid JSON'),
      );
    }

    if (decoded is! Map) {
      return const Result.failure(
        ValidationFailure('Shopping QR root must be an object'),
      );
    }
    final map = Map<String, Object?>.from(decoded);

    for (final forbidden in const [
      'userId',
      'email',
      'deviceId',
      'inventory',
      'history',
    ]) {
      if (map.containsKey(forbidden)) {
        return Result.failure(
          ValidationFailure('Shopping QR must not include $forbidden'),
        );
      }
    }

    final versionRaw = map['version'];
    if (versionRaw is! int && versionRaw is! num) {
      return const Result.failure(
        ValidationFailure('Shopping QR requires a numeric version'),
      );
    }
    final version = (versionRaw as num).toInt();
    if (version != kShoppingListQrVersion) {
      return Result.failure(
        ValidationFailure('Unsupported shopping QR version: $version'),
      );
    }

    final type = map['type'];
    if (type != null && type != kShoppingListQrType) {
      return const Result.failure(
        ValidationFailure('Shopping QR type is not recognized'),
      );
    }

    final itemsRaw = map['items'];
    if (itemsRaw is! List) {
      return const Result.failure(
        ValidationFailure('Shopping QR requires an items array'),
      );
    }
    if (itemsRaw.isEmpty) {
      return const Result.failure(
        ValidationFailure('Shopping QR has no items'),
      );
    }
    if (itemsRaw.length > 200) {
      return const Result.failure(
        ValidationFailure('Shopping QR has too many items'),
      );
    }

    final items = <ShoppingListQrItem>[];
    for (final entry in itemsRaw) {
      final parsed = ShoppingListQrItem.fromJson(entry);
      if (parsed.isFailure) return Result.failure(parsed.failureOrNull!);
      items.add(parsed.valueOrNull!);
    }

    return Result.success(
      ShoppingListQrPayload(version: version, items: items),
    );
  }
}
