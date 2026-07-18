import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/entities/product.dart';
import 'package:fridgeos/domain/value_objects/barcode.dart';
import 'package:fridgeos/domain/value_objects/date_only.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_line_item.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Opens the edit-product sheet for [line]. Updates the product snapshot and
/// item metadata without rewriting historical inventory events.
Future<void> showEditProductSheet(
  BuildContext context, {
  required InventoryLineItem line,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _EditProductForm(line: line),
  );
}

class _EditProductForm extends ConsumerStatefulWidget {
  const _EditProductForm({required this.line});

  final InventoryLineItem line;

  @override
  ConsumerState<_EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends ConsumerState<_EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _noteController;

  late FoodCategory _category;
  late MeasurementUnit _unit;
  late String? _locationId;
  late DateOnly? _expiration;
  bool _submitting = false;

  Product get _product => widget.line.product;

  @override
  void initState() {
    super.initState();
    final item = widget.line.item;
    _nameController = TextEditingController(text: _product.name);
    _brandController = TextEditingController(text: _product.brand ?? '');
    _barcodeController = TextEditingController(
      text: _product.barcode?.value ?? '',
    );
    _quantityController = TextEditingController(
      text: item.quantity.amount.toString(),
    );
    _thresholdController = TextEditingController(
      text: item.lowStockThreshold?.toString() ?? '',
    );
    _noteController = TextEditingController(text: item.note ?? '');
    _category = _product.category;
    _unit = item.quantity.unit;
    _locationId = item.locationId;
    _expiration = item.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locations = ref.watch(locationsProvider).value ?? const [];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.editProductTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.fieldName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '${l10n.fieldBarcode} (${l10n.optionalSuffix})',
                  border: const OutlineInputBorder(),
                ),
                validator: _validateBarcode,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _brandController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '${l10n.fieldBrand} (${l10n.optionalSuffix})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<FoodCategory>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.fieldCategory,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in FoodCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Text(c.label(l10n)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<MeasurementUnit>(
                      initialValue: _unit,
                      decoration: InputDecoration(
                        labelText: l10n.fieldUnit,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final u in MeasurementUnit.values)
                          DropdownMenuItem(
                            value: u,
                            child: Text(u.label(l10n)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _unit = v ?? _unit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.fieldQuantity,
                        border: const OutlineInputBorder(),
                      ),
                      validator: _validateQuantity,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildLocationField(l10n, locations)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildExpirationField(l10n),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: '${l10n.fieldLowStock} (${l10n.optionalSuffix})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '${l10n.fieldNote} (${l10n.optionalSuffix})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _submitting ? null : () => _submit(l10n),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(AppLocalizations l10n, List<Location> locations) {
    return DropdownButtonFormField<String>(
      initialValue: _locationId,
      decoration: InputDecoration(
        labelText: l10n.fieldLocation,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final location in locations)
          DropdownMenuItem(value: location.id, child: Text(location.name)),
      ],
      onChanged: (v) => setState(() => _locationId = v),
      validator: (v) => v == null ? l10n.fieldRequired : null,
    );
  }

  Widget _buildExpirationField(AppLocalizations l10n) {
    final expiration = _expiration;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '${l10n.fieldExpiration} (${l10n.optionalSuffix})',
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(expiration == null ? l10n.noDate : expiration.toIso()),
          ),
          if (expiration != null)
            TextButton(
              onPressed: () => setState(() => _expiration = null),
              child: Text(l10n.clear),
            ),
          TextButton(onPressed: _pickDate, child: Text(l10n.chooseDate)),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiration == null
          ? now
          : DateTime(_expiration!.year, _expiration!.month, _expiration!.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => _expiration = DateOnly.fromDateTime(picked));
  }

  String? _validateQuantity(String? value) {
    final l10n = AppLocalizations.of(context);
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || !parsed.isFinite) {
      return l10n.invalidQuantity;
    }
    return null;
  }

  String? _validateBarcode(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (Barcode.tryParse(trimmed) == null) {
      return AppLocalizations.of(context).invalidBarcode;
    }
    return null;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final locationId = _locationId;
    if (locationId == null) return;

    setState(() => _submitting = true);
    final actions = ref.read(inventoryActionsProvider);
    final amount = double.parse(_quantityController.text.replaceAll(',', '.'));
    final thresholdText = _thresholdController.text.trim();
    final threshold = thresholdText.isEmpty
        ? null
        : double.tryParse(thresholdText.replaceAll(',', '.'));

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await actions.updateItemDetails(
      product: _product,
      item: widget.line.item,
      name: _nameController.text,
      brand: _brandController.text,
      barcode: _barcodeController.text,
      category: _category,
      unit: _unit,
      amount: amount,
      locationId: locationId,
      expirationDate: _expiration,
      lowStockThreshold: threshold,
      note: _noteController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.isSuccess) {
      navigator.pop();
    } else {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    }
  }
}
