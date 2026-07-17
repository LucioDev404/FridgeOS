import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/features/barcode/presentation/widgets/scan_add_sheet.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Barcode entry + lookup flow (FR-BAR-*). Camera/ML Kit decoding is optional
/// on-device; manual entry is the always-available, fully tested path that also
/// covers offline and hostile-payload fallbacks.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = TextEditingController();
  bool _lookingUp = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.scanEmptyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.scanEnterBarcodeBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _lookup(),
                decoration: InputDecoration(
                  labelText: l10n.fieldBarcode,
                  border: const OutlineInputBorder(),
                  hintText: '4006381333931',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _lookingUp ? null : _lookup,
                icon: _lookingUp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(l10n.lookupBarcode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _lookup() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() => _lookingUp = true);
    await handleBarcodeLookup(ref, context, raw);
    if (mounted) setState(() => _lookingUp = false);
  }
}
