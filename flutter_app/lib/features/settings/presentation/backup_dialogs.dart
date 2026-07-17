import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Collects a backup passphrase (export/import).
Future<String?> showPassphraseDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  bool confirmPassphrase = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PassphraseDialog(
      title: title,
      confirmLabel: confirmLabel,
      confirmPassphrase: confirmPassphrase,
    ),
  );
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({
    required this.title,
    required this.confirmLabel,
    required this.confirmPassphrase,
  });

  final String title;
  final String confirmLabel;
  final bool confirmPassphrase;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_passphraseController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passphraseController,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.settingsBackupPassphrase,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
            if (widget.confirmPassphrase) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l10n.settingsBackupPassphraseConfirm,
                ),
                validator: (value) {
                  if (value != _passphraseController.text) {
                    return l10n.settingsBackupPassphraseMismatch;
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Confirms destructive factory reset.
Future<bool> showFactoryResetDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.settingsFactoryResetTitle),
      content: Text(l10n.settingsFactoryResetBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsFactoryResetConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
