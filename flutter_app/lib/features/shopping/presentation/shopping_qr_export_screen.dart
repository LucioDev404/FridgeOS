import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/domain/services/shopping_list_export.dart';
import 'package:fridgeos/features/shopping/application/shopping_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Fullscreen offline QR for the pending shopping list.
class ShoppingQrExportScreen extends ConsumerStatefulWidget {
  const ShoppingQrExportScreen({super.key});

  @override
  ConsumerState<ShoppingQrExportScreen> createState() =>
      _ShoppingQrExportScreenState();
}

class _ShoppingQrExportScreenState
    extends ConsumerState<ShoppingQrExportScreen> {
  final _qrKey = GlobalKey();
  final _formatter = const ShoppingListExportFormatter();
  var _sharing = false;

  Future<void> _sharePng(String payload) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await _shareBytes(bytes, payload: payload);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareBytes(Uint8List bytes, {required String payload}) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'fridgeos-shopping-qr-${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: payload,
        subject: 'FridgeOS shopping list',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(pendingShoppingItemsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.shoppingQrEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }

        final payload = _formatter.toHumanReadableQr(items);
        final itemCount = items.length;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  l10n.shoppingQrExportHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: RepaintBoundary(
                              key: _qrKey,
                              child: QrImageView(
                                data: payload,
                                version: QrVersions.auto,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.shoppingQrItemCount(itemCount),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _sharing ? null : () => _sharePng(payload),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined),
                  label: Text(l10n.shoppingQrSharePng),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
