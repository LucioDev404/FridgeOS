import 'package:fridgeos/domain/value_objects/enums.dart';

/// A storage place for inventory (refrigerator, freezer or pantry). Users may
/// create additional named locations of these types (see FR-LOC-2).
final class Location {
  const Location({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.shelfLifeBonusDays,
    this.deletedAt,
  });

  final String id;
  final String name;
  final LocationType type;

  /// Optional hint that this location extends shelf life (e.g. a freezer).
  final int? shelfLifeBonusDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Location copyWith({
    String? name,
    LocationType? type,
    int? shelfLifeBonusDays,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Location(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      shelfLifeBonusDays: shelfLifeBonusDays ?? this.shelfLifeBonusDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Location &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.shelfLifeBonusDays == shelfLifeBonusDays &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    shelfLifeBonusDays,
    createdAt,
    updatedAt,
    deletedAt,
  );
}
