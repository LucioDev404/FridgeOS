import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/domain/services/shopping_list_qr_codec.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/shopping/application/shopping_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// When true, skips the live camera preview (widget tests / headless CI).
@visibleForTesting
bool debugDisableShoppingQrCamera = false;

/// Offline QR import for shopping lists: scan → review → confirm.
class ShoppingQrImportScreen extends ConsumerStatefulWidget {
  const ShoppingQrImportScreen({super.key});

  @override
  ConsumerState<ShoppingQrImportScreen> createState() =>
      _ShoppingQrImportScreenState();
}

class _ShoppingQrImportScreenState
    extends ConsumerState<ShoppingQrImportScreen> {
  final _codec = const ShoppingListQrCodec();
  final _manualController = TextEditingController();
  late final MobileScannerController _scanner;

  ShoppingListQrPayload? _preview;
  String? _error;
  var _busy = false;
  var _handled = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      autoStart: !debugDisableShoppingQrCamera,
      facing: CameraFacing.back,
      returnImage: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _preview != null || _handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      await _parse(value);
      return;
    }
  }

  Future<void> _parse(String raw) async {
    final result = _codec.decode(raw);
    if (result.isFailure) {
      setState(() {
        _error = result.failureOrNull!.message;
        _preview = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _preview = result.valueOrNull;
      _handled = true;
    });
    if (!debugDisableShoppingQrCamera) {
      await _scanner.stop();
    }
  }

  Future<void> _confirmImport() async {
    final payload = _preview;
    if (payload == null || _busy) return;
    setState(() => _busy = true);
    final actions = ref.read(shoppingActionsProvider);
    final result = await actions.importFromQr(payload);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isFailure) {
      showActionFailure(context, AppLocalizations.of(context).actionFailed);
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.shoppingQrImportSuccess(result.valueOrNull!)),
      ),
    );
    context.pop();
  }

  void _resetScan() {
    setState(() {
      _preview = null;
      _error = null;
      _handled = false;
    });
    if (!debugDisableShoppingQrCamera) {
      _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;

    return preview == null
        ? Column(
            children: [
              Expanded(
                child: debugDisableShoppingQrCamera
                    ? Center(child: Text(l10n.shoppingQrImportHint))
                    : MobileScanner(controller: _scanner, onDetect: _onDetect),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.shoppingQrImportHint,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _manualController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.shoppingQrPasteHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => _parse(_manualController.text),
                      child: Text(l10n.shoppingQrParsePaste),
                    ),
                  ],
                ),
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                l10n.shoppingQrReviewTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.shoppingQrItemCount(preview.items.length)),
              const SizedBox(height: AppSpacing.md),
              for (final item in preview.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(item.name),
                  subtitle: item.quantity == null
                      ? null
                      : Text(item.quantity!.toString()),
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _busy ? null : _confirmImport,
                icon: const Icon(Icons.check),
                label: Text(l10n.shoppingQrConfirmImport),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _busy ? null : _resetScan,
                child: Text(l10n.shoppingQrScanAgain),
              ),
            ],
          );
  }
}
