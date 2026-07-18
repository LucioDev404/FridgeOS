import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Full offline recipe detail: ingredients, steps, time, difficulty, servings.
///
/// AppBar / Back are owned by [ShellScaffold] so nested navigation never traps
/// the user without a visible return control.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matchesAsync = ref.watch(rankedRecipesProvider);
    final actions = ref.read(recipeActionsProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (matches) {
        RecipeMatch? match;
        for (final m in matches) {
          if (m.recipe.id == recipeId) {
            match = m;
            break;
          }
        }
        if (match == null) {
          return EmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: l10n.recipesEmptyTitle,
            body: l10n.recipesEmptyBody,
          );
        }

        final recipe = match.recipe;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(recipe.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: Text(l10n.recipePrepTime(recipe.prepTimeMinutes))),
                if (recipe.servings != null)
                  Chip(label: Text(l10n.recipeServings(recipe.servings!))),
                if (recipe.difficulty != null)
                  Chip(
                    label: Text(
                      '${l10n.recipeDifficultyLabel}: ${recipe.difficulty!.label(l10n)}',
                    ),
                  ),
                Chip(
                  label: Text(
                    l10n.recipeAvailability(
                      match.availableCount,
                      match.requiredCount,
                    ),
                  ),
                ),
              ],
            ),
            if (match.availableIngredientNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.recipeAvailableIngredients(
                  match.availableIngredientNames.join(', '),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (match.missingIngredientNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.recipeMissingIngredients(
                  match.missingIngredientNames.join(', '),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.recipeIngredientsSection,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final ingredient in recipe.ingredients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  ingredient.optional
                      ? Icons.radio_button_unchecked
                      : Icons.check_circle_outline,
                ),
                title: Text(ingredient.name),
                subtitle: ingredient.quantity == null
                    ? null
                    : Text(
                        '${ingredient.quantity!.amount} ${ingredient.quantity!.unit.label(l10n)}',
                      ),
                trailing: ingredient.optional
                    ? Text(
                        l10n.optionalSuffix,
                        style: theme.textTheme.labelSmall,
                      )
                    : null,
              ),
            const Divider(height: AppSpacing.xl),
            Text(l10n.recipeStepsSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < recipe.steps.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                title: Text(recipe.steps[i]),
              ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (match.missingIngredientNames.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => runWithFeedback(
                      context,
                      actions.addMissingToShopping(match!),
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
        );
      },
    );
  }
}
