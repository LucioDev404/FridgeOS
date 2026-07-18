import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/domain/services/shopping_list_export.dart';
import 'package:fridgeos/features/shopping/application/shopping_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// User-friendly shopping list export: PNG image + plain-text Todo share.
class ShoppingListExportScreen extends ConsumerStatefulWidget {
  const ShoppingListExportScreen({super.key});

  @override
  ConsumerState<ShoppingListExportScreen> createState() =>
      _ShoppingListExportScreenState();
}

class _ShoppingListExportScreenState
    extends ConsumerState<ShoppingListExportScreen> {
  final _listKey = GlobalKey();
  final _formatter = const ShoppingListExportFormatter();
  var _busy = false;

  Future<void> _shareImage(List<ShoppingListItem> items) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _listKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(
          dir.path,
          'fridgeos-shopping-${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'FridgeOS shopping list',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareTasks(List<ShoppingListItem> items) async {
    final text = _formatter.toTodoText(items);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Shopping list'),
    );
  }

  Future<void> _copyTasks(List<ShoppingListItem> items) async {
    final text = _formatter.toTodoText(items);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).shoppingExportCopied),
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
              child: Text(l10n.shoppingQrEmpty, textAlign: TextAlign.center),
            ),
          );
        }

        final groups = _formatter.groupByCategory(items);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  l10n.shoppingExportHint,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: RepaintBoundary(
                          key: _listKey,
                          child: _ShoppingListPoster(
                            title: l10n.shoppingTitle,
                            groups: groups,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _shareImage(items),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l10n.shoppingExportShareImage),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _shareTasks(items),
                      icon: const Icon(Icons.checklist_outlined),
                      label: Text(l10n.shoppingExportShareTasks),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyTasks(items),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.shoppingExportCopy),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShoppingListPoster extends StatelessWidget {
  const _ShoppingListPoster({required this.title, required this.groups});

  final String title;
  final Map<String, List<ShoppingListItem>> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateTime.now().toLocal().toString().split('.').first,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              for (final entry in groups.entries) ...[
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('☐  ', style: TextStyle(fontSize: 18)),
                        Expanded(
                          child: Text(
                            item.quantity == null
                                ? item.name
                                : '${item.name}  ×${formatAmount(item.quantity!.amount)} ${item.quantity!.unit.wire}',
                            style: const TextStyle(fontSize: 16, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
