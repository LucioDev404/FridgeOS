import 'package:flutter/material.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Full-screen barcode scanner route. The live camera and ML Kit decoding are
/// wired in Phase 5; this screen currently provides the framing and guidance.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: EmptyState(
        icon: Icons.qr_code_scanner,
        title: l10n.scanEmptyTitle,
        body: l10n.scanEmptyBody,
      ),
    );
  }
}
