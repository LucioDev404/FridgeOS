import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/barcode/application/barcode_providers.dart';
import 'package:fridgeos/features/barcode/application/barcode_resolve_service.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Collects quantity + location after a barcode resolves to a [Product].
Future<void> showScanAddSheet(
  BuildContext context, {
  required Product product,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ScanAddSheet(product: product),
    ),
  );
}

class _ScanAddSheet extends ConsumerStatefulWidget {
  const _ScanAddSheet({required this.product});

  final Product product;

  @override
  ConsumerState<_ScanAddSheet> createState() => _ScanAddSheetState();
}

class _ScanAddSheetState extends ConsumerState<_ScanAddSheet> {
  final _qtyController = TextEditingController(text: '1');
  MeasurementUnit? _unit;
  String? _locationId;
  bool _saving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locations = ref.watch(locationsProvider).value ?? const [];
    _unit ??= widget.product.defaultUnit;
    _locationId ??= locations.isEmpty ? null : locations.first.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.product.brand != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(widget.product.brand!),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.fieldQuantity,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<MeasurementUnit>(
              // ignore: deprecated_member_use — value is still the stable API here
              value: _unit,
              decoration: InputDecoration(
                labelText: l10n.fieldUnit,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final unit in MeasurementUnit.values)
                  DropdownMenuItem(value: unit, child: Text(unit.label(l10n))),
              ],
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _locationId,
              decoration: InputDecoration(
                labelText: l10n.fieldLocation,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final loc in locations)
                  DropdownMenuItem(value: loc.id, child: Text(loc.name)),
              ],
              onChanged: (v) => setState(() => _locationId = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_qtyController.text.trim());
    final locationId = _locationId;
    final unit = _unit;
    if (amount == null || amount <= 0 || locationId == null || unit == null) {
      showActionFailure(context, l10n.invalidQuantity);
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(inventoryActionsProvider)
        .addStockForProduct(
          product: widget.product,
          unit: unit,
          amount: amount,
          locationId: locationId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isFailure) {
      showActionFailure(context, l10n.actionFailed);
      return;
    }
    Navigator.of(context).pop();
  }
}

/// Opens the manual add-product sheet with a prefilled barcode when OFF misses.
Future<void> showManualBarcodeFallback(
  BuildContext context, {
  required Barcode barcode,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context).scanNotFoundTitle),
      content: Text(
        AppLocalizations.of(context).scanNotFoundBody(barcode.value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Manual entry continues on Inventory via add sheet; barcode is
            // shown so the user can type the same product name.
          },
          child: Text(AppLocalizations.of(context).addProduct),
        ),
      ],
    ),
  );
}

/// Shared lookup helper used by the scan screen (and tests).
Future<void> handleBarcodeLookup(
  WidgetRef ref,
  BuildContext context,
  String raw,
) async {
  final result = await ref.read(barcodeResolveServiceProvider).resolve(raw);
  if (!context.mounted) return;
  if (result.isFailure) {
    showActionFailure(context, result.failureOrNull!.message);
    return;
  }
  switch (result.valueOrNull!) {
    case BarcodeResolveFound(:final product):
      await showScanAddSheet(context, product: product);
    case BarcodeResolveNotFound():
      final barcode = Barcode.tryParse(raw);
      if (barcode != null) {
        await showManualBarcodeFallback(context, barcode: barcode);
      }
    case BarcodeResolveNeedsManual(:final barcode):
      await showManualBarcodeFallback(context, barcode: barcode);
  }
}
