import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/user_preferences.dart';
import 'package:fridgeos/domain/repositories/preferences_repository.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/expiration/application/notification_scheduler.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/infrastructure/backup/backup_service.dart';

/// Application-layer use cases for user preferences and notification scheduling.
final class SettingsActions {
  const SettingsActions({
    required this.preferences,
    required this.scheduler,
    required this.backup,
  });

  final PreferencesRepository preferences;
  final NotificationScheduler scheduler;
  final BackupService backup;

  Future<Result<void>> updateExpiringSoonWindowDays(int days) async {
    if (days < 0 || days > 30) {
      return const Result.failure(
        ValidationFailure('Window must be between 0 and 30 days'),
      );
    }
    final current = await _currentPreferences();
    if (current.isFailure) return Result.failure(current.failureOrNull!);
    return preferences.save(
      current.valueOrNull!.copyWith(expiringSoonWindowDays: days),
    );
  }

  Future<Result<void>> setEnrichmentEnabled(bool enabled) async {
    final current = await _currentPreferences();
    if (current.isFailure) return Result.failure(current.failureOrNull!);
    return preferences.save(
      current.valueOrNull!.copyWith(enrichmentEnabled: enabled),
    );
  }

  Future<Result<void>> rescheduleExpirationDigest({
    required List<InventoryLineItem> expiringItems,
  }) async {
    final current = await _currentPreferences();
    if (current.isFailure) return Result.failure(current.failureOrNull!);
    return scheduler.scheduleExpirationDigest(
      items: expiringItems,
      digestTime: current.valueOrNull!.digestTime,
    );
  }

  Future<Result<UserPreferences>> _currentPreferences() => preferences.load();

  Future<Result<Uint8List>> exportBackup(String passphrase) =>
      backup.exportEncrypted(passphrase);

  Future<Result<void>> importBackup(Uint8List bytes, String passphrase) =>
      backup.importEncrypted(bytes, passphrase);

  Future<Result<void>> factoryReset() => backup.factoryReset();
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

final settingsActionsProvider = Provider<SettingsActions>(
  (ref) => SettingsActions(
    preferences: ref.watch(preferencesRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
    backup: ref.watch(backupServiceProvider),
  ),
);
