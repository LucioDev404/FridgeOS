import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/domain/value_objects/diet_preference.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/recipes/application/recipe_actions.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: matches.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return _RecipeCard(
                    match: match,
                    actions: ref.read(recipeActionsProvider),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match, required this.actions});

  final RecipeMatch match;
  final RecipeActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recipe = match.recipe;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecipeImage(
                    imageUrl: recipe.imageUrl,
                    cuisine: recipe.cuisine,
                    size: RecipeImageSize.thumbnail,
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: _MatchBadge(
                      percent: match.completionPercent,
                      ready: match.isReadyToCook,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (recipe.cuisine != null)
                        Chip(
                          label: Text(recipe.cuisine!),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text(
                          l10n.recipePrepTime(recipe.prepTimeMinutes),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (recipe.difficulty != null)
                        Chip(
                          label: Text(recipe.difficulty!.label(l10n)),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (match.isReadyToCook)
                        Chip(
                          avatar: const Icon(Icons.check_circle, size: 16),
                          label: Text(l10n.recipeReadyToCook),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: match.completionRatio,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (match.availableIngredientNames.isNotEmpty)
                    Text(
                      l10n.recipeAvailableIngredients(
                        match.availableIngredientNames.join(', '),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (match.missingIngredientNames.isNotEmpty)
                    Text(
                      l10n.recipeMissingIngredients(
                        match.missingIngredientNames.join(', '),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  if (match.optionalIngredientNames.isNotEmpty)
                    Text(
                      l10n.recipeOptionalIngredients(
                        match.optionalIngredientNames.join(', '),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (match.suggestedSubstitutions.isNotEmpty)
                    Text(
                      l10n.recipeSubstitutions(
                        match.suggestedSubstitutions.join(' · '),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/recipes/${recipe.id}'),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l10n.recipeViewDetails),
                      ),
                      if (match.missingIngredientNames.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => runWithFeedback(
                            context,
                            actions.addMissingToShopping(match),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: Text(l10n.recipeAddMissing),
                        ),
                      if (match.isReadyToCook)
                        FilledButton.icon(
                          onPressed: () =>
                              runWithFeedback(context, actions.cooked(recipe)),
                          icon: const Icon(Icons.restaurant_outlined),
                          label: Text(l10n.recipeCookNow),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          : theme.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$percent%',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
