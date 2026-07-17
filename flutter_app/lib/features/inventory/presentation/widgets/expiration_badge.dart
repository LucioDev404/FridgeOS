import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// A compact status pill communicating expiration state with both color and
/// text (never color alone — docs/10-ui-guidelines.md §8 accessibility).
class ExpirationBadge extends StatelessWidget {
  const ExpirationBadge({
    required this.status,
    required this.daysToExpiry,
    super.key,
  });

  final ExpirationStatus status;
  final int? daysToExpiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color bg, Color fg, String text) = switch (status) {
      ExpirationStatus.expired => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        _expiredText(l10n),
      ),
      ExpirationStatus.expiringSoon => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        _soonText(l10n),
      ),
      ExpirationStatus.fresh => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        l10n.statusFresh,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _expiredText(AppLocalizations l10n) {
    final days = daysToExpiry;
    if (days == null || days == 0) return l10n.statusExpired;
    return l10n.expiredDaysAgo(days.abs());
  }

  String _soonText(AppLocalizations l10n) {
    final days = daysToExpiry;
    if (days == null) return l10n.statusExpiringSoon;
    if (days == 0) return l10n.expiresToday;
    return l10n.expiresInDays(days);
  }
}
