import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/utils/clock.dart';
import 'package:fridgeos/core/utils/id_generator.dart';
import 'package:fridgeos/core/validation/input_sanitizer.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/repositories/location_repository.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';

/// Application-layer use cases for managing storage locations (FR-LOC-1/2/3).
final class LocationActions {
  const LocationActions({
    required this.locations,
    required this.sanitizer,
    required this.clock,
    required this.ids,
  });

  final LocationRepository locations;
  final InputSanitizer sanitizer;
  final Clock clock;
  final IdGenerator ids;

  /// Creates a new location of [type] named [name].
  Future<Result<void>> create({
    required String name,
    required LocationType type,
    int? shelfLifeBonusDays,
  }) async {
    final nameResult = sanitizer.requireText(
      name,
      maxLength: 100,
      fieldName: 'name',
    );
    if (nameResult.isFailure) return Result.failure(nameResult.failureOrNull!);

    final now = clock.nowUtc();
    return locations.upsert(
      Location(
        id: ids.newId(),
        name: nameResult.valueOrNull!,
        type: type,
        shelfLifeBonusDays: shelfLifeBonusDays,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Renames / retypes an existing [location].
  Future<Result<void>> update({
    required Location location,
    required String name,
    required LocationType type,
  }) async {
    final nameResult = sanitizer.requireText(
      name,
      maxLength: 100,
      fieldName: 'name',
    );
    if (nameResult.isFailure) return Result.failure(nameResult.failureOrNull!);

    return locations.upsert(
      location.copyWith(
        name: nameResult.valueOrNull!,
        type: type,
        updatedAt: clock.nowUtc(),
      ),
    );
  }
}

/// Use-case facade for the locations feature.
final locationActionsProvider = Provider<LocationActions>(
  (ref) => LocationActions(
    locations: ref.watch(locationRepositoryProvider),
    sanitizer: ref.watch(inputSanitizerProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
