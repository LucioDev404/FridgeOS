import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fridgeos/core/utils/number_format.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Prompts for a new absolute quantity. Returns the entered amount, or `null`
/// when cancelled.
Future<double?> showSetQuantityDialog(
  BuildContext context, {
  required double current,
  required MeasurementUnit unit,
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _SetQuantityDialog(current: current, unit: unit),
  );
}

class _SetQuantityDialog extends StatefulWidget {
  const _SetQuantityDialog({required this.current, required this.unit});

  final double current;
  final MeasurementUnit unit;

  @override
  State<_SetQuantityDialog> createState() => _SetQuantityDialogState();
}

class _SetQuantityDialogState extends State<_SetQuantityDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: formatAmount(widget.current),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (value == null || value < 0 || !value.isFinite) {
      setState(() => _error = AppLocalizations.of(context).invalidQuantity);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.setQuantity),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: l10n.fieldQuantity,
          suffixText: widget.unit.wire,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
