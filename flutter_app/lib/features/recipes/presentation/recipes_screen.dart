import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/recipes/application/recipe_actions.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Recipe suggestions ranked by availability, expiration and preferences.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matchesAsync = ref.watch(rankedRecipesProvider);
    final actions = ref.read(recipeActionsProvider);

    return matchesAsync.when(
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
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final match = matches[index];
            return _RecipeCard(match: match, actions: actions);
          },
        );
      },
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
    final coverage = match.requiredCount == 0
        ? 1.0
        : match.availableCount / match.requiredCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(recipe.title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  l10n.recipeCompletionPercent(match.completionPercent),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (recipe.difficulty != null) ...[
                  Text(
                    recipe.difficulty!.label(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ' · ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                Text(
                  l10n.recipePrepTime(recipe.prepTimeMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (recipe.servings != null) ...[
                  Text(
                    ' · ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.recipeServings(recipe.servings!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: coverage,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.recipeAvailability(
                    match.availableCount,
                    match.requiredCount,
                  ),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            if (match.missingIngredientNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.recipeMissingIngredients(
                  match.missingIngredientNames.join(', '),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
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
                FilledButton.icon(
                  onPressed: () =>
                      runWithFeedback(context, actions.cooked(recipe)),
                  icon: const Icon(Icons.restaurant_outlined),
                  label: Text(l10n.recipeCooked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
