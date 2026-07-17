import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/features/inventory/application/inventory_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Prompts the user to choose a target location for a move. Returns the chosen
/// location id, or `null` when cancelled. [currentLocationId] is excluded.
Future<String?> showMoveLocationDialog(
  BuildContext context, {
  required String currentLocationId,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _MoveLocationDialog(currentLocationId: currentLocationId),
  );
}

class _MoveLocationDialog extends ConsumerWidget {
  const _MoveLocationDialog({required this.currentLocationId});

  final String currentLocationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locations = ref
        .watch(locationsProvider)
        .value
        ?.where((location) => location.id != currentLocationId)
        .toList();

    return AlertDialog(
      title: Text(l10n.moveTo),
      content: SizedBox(
        width: 320,
        child: (locations == null || locations.isEmpty)
            ? Text(l10n.locationsEmptyBody)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final location in locations)
                    ListTile(
                      leading: Icon(_iconFor(location.type.name)),
                      title: Text(location.name),
                      subtitle: Text(location.type.label(l10n)),
                      onTap: () => Navigator.of(context).pop(location.id),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  IconData _iconFor(String typeName) => switch (typeName) {
    'refrigerator' => Icons.kitchen_outlined,
    'freezer' => Icons.ac_unit,
    _ => Icons.shelves,
  };
}
