import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/settings/application/settings_actions.dart';
import 'package:fridgeos/features/settings/presentation/backup_dialogs.dart';
import 'package:fridgeos/infrastructure/backup/backup_file_store.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Settings: enrichment toggle, expiration window, backup, and factory reset.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _files = BackupFileStore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final actions = ref.read(settingsActionsProvider);

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (prefs) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.settingsExpirationSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsExpiringSoonWindow),
            subtitle: Text(l10n.settingsExpiringSoonWindowBody),
            trailing: SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: prefs.expiringSoonWindowDays <= 0
                        ? null
                        : () => runWithFeedback(
                            context,
                            actions.updateExpiringSoonWindowDays(
                              prefs.expiringSoonWindowDays - 1,
                            ),
                          ),
                  ),
                  Text('${prefs.expiringSoonWindowDays}'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: prefs.expiringSoonWindowDays >= 30
                        ? null
                        : () => runWithFeedback(
                            context,
                            actions.updateExpiringSoonWindowDays(
                              prefs.expiringSoonWindowDays + 1,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            l10n.settingsEnrichmentSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsEnrichmentEnabled),
            subtitle: Text(l10n.settingsEnrichmentBody),
            value: prefs.enrichmentEnabled,
            onChanged: (value) => runWithFeedback(
              context,
              actions.setEnrichmentEnabled(value),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            l10n.settingsBackupSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.settingsExportBackup),
            subtitle: Text(l10n.settingsExportBackupBody),
            onTap: () => _exportBackup(context, actions, l10n),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settingsImportBackup),
            subtitle: Text(l10n.settingsImportBackupBody),
            onTap: () => _importBackup(context, actions, l10n),
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            l10n.settingsDangerSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(l10n.settingsFactoryReset),
            subtitle: Text(l10n.settingsFactoryResetHint),
            onTap: () => _factoryReset(context, actions, l10n),
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            l10n.settingsAboutSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsPrivacyNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsOffAttribution,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsLicenseNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(
    BuildContext context,
    SettingsActions actions,
    AppLocalizations l10n,
  ) async {
    final passphrase = await showPassphraseDialog(
      context,
      title: l10n.settingsExportBackup,
      confirmLabel: l10n.settingsExportBackup,
      confirmPassphrase: true,
    );
    if (passphrase == null || !context.mounted) return;

    final result = await actions.exportBackup(passphrase);
    if (!context.mounted) return;
    if (result.isFailure) {
      showActionFailure(context, l10n.actionFailed);
      return;
    }

    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    try {
      final file = await _files.writeBackup(
        result.valueOrNull!,
        fileName: 'fridgeos-backup-$timestamp.json',
      );
      await _files.shareBackup(file);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsBackupExported)),
      );
    } on Object {
      if (!context.mounted) return;
      showActionFailure(context, l10n.actionFailed);
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    SettingsActions actions,
    AppLocalizations l10n,
  ) async {
    final backups = await _files.listBackups();
    if (!context.mounted) return;
    final picked = await showBackupPickerDialog(context, files: backups);
    if (picked == null || !context.mounted) return;

    final passphrase = await showPassphraseDialog(
      context,
      title: l10n.settingsImportBackup,
      confirmLabel: l10n.settingsImportBackup,
    );
    if (passphrase == null || !context.mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;
      await runWithFeedback(
        context,
        actions.importBackup(Uint8List.fromList(bytes), passphrase),
      );
    } on Object {
      if (!context.mounted) return;
      showActionFailure(context, l10n.actionFailed);
    }
  }

  Future<void> _factoryReset(
    BuildContext context,
    SettingsActions actions,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showFactoryResetDialog(context);
    if (!confirmed || !context.mounted) return;
    await runWithFeedback(context, actions.factoryReset());
  }
}
