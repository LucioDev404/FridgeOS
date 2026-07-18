import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/features/barcode/application/barcode_providers.dart';
import 'package:fridgeos/features/barcode/application/barcode_resolve_service.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/product_form_sheet.dart';

/// Opens the shared product form for an already-resolved catalog [product].
Future<void> showScanAddSheet(
  BuildContext context, {
  required Product product,
}) {
  return showProductFormSheet(context, existingProduct: product);
}

/// Opens the shared product form with [barcode] prefilled when lookup misses.
Future<void> showManualBarcodeFallback(
  BuildContext context, {
  required Barcode barcode,
}) {
  return showProductFormSheet(context, prefillBarcode: barcode.value);
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
