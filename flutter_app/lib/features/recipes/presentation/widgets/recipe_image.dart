import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';

/// Lazy-loaded recipe hero/card image with cuisine-colored offline fallback.
class RecipeImage extends StatelessWidget {
  const RecipeImage({
    required this.imageUrl,
    required this.cuisine,
    this.borderRadius,
    this.height,
    super.key,
  });

  final String? imageUrl;
  final String? cuisine;
  final BorderRadius? borderRadius;
  final double? height;

  Color _fallbackColor(ColorScheme scheme) {
    final key = (cuisine ?? '').toLowerCase();
    if (key.contains('italian') || key.contains('mediterranean')) {
      return const Color(0xFF2F5D50);
    }
    if (key.contains('japan') ||
        key.contains('china') ||
        key.contains('korea') ||
        key.contains('thai') ||
        key.contains('vietnam') ||
        key.contains('india') ||
        key.contains('asian')) {
      return const Color(0xFF8B3A3A);
    }
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _fallbackColor(theme.colorScheme),
            theme.colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 48,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
        ),
      ),
    );

    final url = imageUrl;
    final child = url == null || url.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(height: height, width: double.infinity, child: child),
    );
  }
}
