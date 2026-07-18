import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/result.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/entities/location.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/features/locations/application/location_actions.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Full-screen locations management (add / edit / delete). Reached from the
/// inventory filter bar and settings.
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locations = ref.watch(locationsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inventory');
            }
          },
        ),
        title: Text(l10n.locationsTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addLocation),
      ),
      body: locations.isEmpty
          ? EmptyState(
              icon: Icons.shelves,
              title: l10n.locationsEmptyTitle,
              body: l10n.locationsEmptyBody,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_iconFor(location.type)),
                    title: Text(location.name),
                    subtitle: Text(location.type.label(l10n)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.editLocation,
                          onPressed: () => _openEditor(context, ref, location),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.deleteLocation,
                          onPressed: () =>
                              _confirmDelete(context, ref, location),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(LocationType type) => switch (type) {
    LocationType.refrigerator => Icons.kitchen_outlined,
    LocationType.freezer => Icons.ac_unit,
    LocationType.pantry => Icons.shelves,
  };

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Location location,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLocationConfirmTitle),
        content: Text(l10n.deleteLocationConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(locationActionsProvider)
        .delete(location: location);
    if (!context.mounted) return;

    if (result.isFailure) {
      final failure = result.failureOrNull;
      final message =
          failure is ValidationFailure &&
              failure.message == 'LOCATION_HAS_PRODUCTS'
          ? l10n.locationHasProducts
          : l10n.actionFailed;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Location? existing,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_LocationDraft>(
      context: context,
      builder: (context) => _LocationEditorDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;

    final actions = ref.read(locationActionsProvider);
    final Result<void> outcome = existing == null
        ? await actions.create(name: result.name, type: result.type)
        : await actions.update(
            location: existing,
            name: result.name,
            type: result.type,
          );

    if (!context.mounted) return;
    if (outcome.isFailure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    }
  }
}

class _LocationDraft {
  const _LocationDraft(this.name, this.type);
  final String name;
  final LocationType type;
}

class _LocationEditorDialog extends StatefulWidget {
  const _LocationEditorDialog({this.existing});

  final Location? existing;

  @override
  State<_LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<_LocationEditorDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late LocationType _type = widget.existing?.type ?? LocationType.refrigerator;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    Navigator.of(context).pop(_LocationDraft(_nameController.text, _type));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.addLocation : l10n.editLocation,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<LocationType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l10n.fieldType),
            items: [
              for (final type in LocationType.values)
                DropdownMenuItem(value: type, child: Text(type.label(l10n))),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
        ],
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
