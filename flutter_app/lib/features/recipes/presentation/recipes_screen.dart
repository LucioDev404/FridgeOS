import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/diet_preference.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
import 'package:fridgeos/features/recipes/presentation/widgets/recipe_diet_label.dart';
import 'package:fridgeos/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:fridgeos/features/settings/application/settings_actions.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Recipe suggestions ranked by availability, expiration and preferences.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matchesAsync = ref.watch(rankedRecipesProvider);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final diet = prefsAsync.value?.dietPreference ?? DietPreference.omnivore;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recipeDietLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<DietPreference>(
                segments: [
                  ButtonSegment(
                    value: DietPreference.omnivore,
                    label: Text(l10n.dietOmnivore),
                    icon: const Icon(Icons.restaurant),
                  ),
                  ButtonSegment(
                    value: DietPreference.vegetarian,
                    label: Text(l10n.dietVegetarian),
                    icon: const Icon(Icons.eco_outlined),
                  ),
                  ButtonSegment(
                    value: DietPreference.vegan,
                    label: Text(l10n.dietVegan),
                    icon: const Icon(Icons.spa_outlined),
                  ),
                ],
                selected: {diet},
                onSelectionChanged: (next) async {
                  final value = next.first;
                  final result = await ref
                      .read(settingsActionsProvider)
                      .setDietPreference(value);
                  if (!context.mounted) return;
                  if (result.isFailure) {
                    showActionFailure(context, l10n.actionFailed);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.actionFailed)),
            data: (matches) {
              if (matches.isEmpty) {
                return EmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  title: l10n.recipesEmptyTitle,
                  body: l10n.recipesEmptyBody,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: matches.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return _RecipeCard(match: match);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal card: thumbnail ~35% of visual weight, scannable meta.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match});

  final RecipeMatch match;

  static const double _imageWidth = 118;
  static const double _cardHeight = 118;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recipe = match.recipe;
    final diet = recipeDietLabel(recipe.tags, l10n);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: SizedBox(
          height: _cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _imageWidth,
                child: RecipeImage(
                  imageUrl: recipe.imageUrl,
                  cuisine: recipe.cuisine,
                  size: RecipeImageSize.thumbnail,
                  borderRadius: BorderRadius.zero,
                  height: _cardHeight,
                  width: _imageWidth,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _MatchBadge(
                            percent: match.completionPercent,
                            ready: match.isReadyToCook,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (recipe.cuisine != null) recipe.cuisine!,
                          l10n.recipePrepTime(recipe.prepTimeMinutes),
                          if (recipe.difficulty != null)
                            recipe.difficulty!.label(l10n),
                          diet,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: match.completionRatio,
                          minHeight: 4,
                        ),
                      ),
                      if (match.isReadyToCook) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.recipeReadyToCook,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.percent, required this.ready});

  final int percent;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: ready
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          '$percent%',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
