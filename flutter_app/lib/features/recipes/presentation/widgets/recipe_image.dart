import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';

/// Display size for recipe images (drives URL resize + decode cache).
enum RecipeImageSize {
  /// List / card thumbnails (~400px wide, lower quality).
  thumbnail,

  /// Detail hero (~900px wide).
  hero,
}

/// Lazy-loaded recipe image with resolution-aware URLs and offline fallback.
class RecipeImage extends StatelessWidget {
  const RecipeImage({
    required this.imageUrl,
    required this.cuisine,
    this.size = RecipeImageSize.thumbnail,
    this.borderRadius,
    this.height,
    super.key,
  });

  final String? imageUrl;
  final String? cuisine;
  final RecipeImageSize size;
  final BorderRadius? borderRadius;
  final double? height;

  int get _targetWidth => switch (size) {
    RecipeImageSize.thumbnail => 480,
    RecipeImageSize.hero => 1080,
  };

  int get _quality => switch (size) {
    RecipeImageSize.thumbnail => 65,
    RecipeImageSize.hero => 75,
  };

  int get _memCacheWidth => switch (size) {
    RecipeImageSize.thumbnail => 480,
    RecipeImageSize.hero => 1080,
  };

  /// Rewrites known CDN URLs to request a compressed, width-capped variant.
  static String? optimizedUrl(
    String? url, {
    required int width,
    required int quality,
  }) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    final host = uri.host.toLowerCase();
    if (host.contains('unsplash') || host.contains('imgix')) {
      final params = Map<String, String>.from(uri.queryParameters);
      params['w'] = '$width';
      params['q'] = '$quality';
      params['auto'] = 'format';
      params['fit'] = 'crop';
      return uri.replace(queryParameters: params).toString();
    }
    return url;
  }

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
          size: size == RecipeImageSize.hero ? 56 : 40,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
        ),
      ),
    );

    final resolved = optimizedUrl(
      imageUrl,
      width: _targetWidth,
      quality: _quality,
    );
    final child = resolved == null
        ? fallback
        : CachedNetworkImage(
            imageUrl: resolved,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 180),
            memCacheWidth: _memCacheWidth,
            maxWidthDiskCache: _memCacheWidth,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(height: height, width: double.infinity, child: child),
    );
  }
}
