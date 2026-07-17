import 'package:flutter/material.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Awaits an action [future] and shows a generic error SnackBar on failure.
///
/// Error messages are intentionally generic (no data values) to avoid leaking
/// contents into transient UI (docs/09-security-design.md §7).
Future<void> runWithFeedback(
  BuildContext context,
  Future<Result<void>> future,
) async {
  final result = await future;
  if (!context.mounted) return;
  if (result.isFailure) {
    showActionFailure(context, AppLocalizations.of(context).actionFailed);
  }
}

/// Shows a transient error SnackBar with [message]. Prefer generic copy.
void showActionFailure(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
