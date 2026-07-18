import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/core/l10n/enum_labels.dart';
import 'package:fridgeos/core/widgets/empty_state.dart';
import 'package:fridgeos/domain/entities/recipe.dart';
import 'package:fridgeos/domain/services/recipe_ranker.dart';
import 'package:fridgeos/features/inventory/presentation/widgets/action_feedback.dart';
import 'package:fridgeos/features/recipes/application/recipe_providers.dart';
import 'package:fridgeos/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Full offline recipe detail with hero image and match breakdown.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matchAsync = ref.watch(recipeMatchProvider(recipeId));
    final actions = ref.read(recipeActionsProvider);

    return matchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.actionFailed)),
      data: (match) {
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
          padding: EdgeInsets.zero,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: RecipeImage(
                imageUrl: recipe.imageUrl,
                cuisine: recipe.cuisine,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: theme.textTheme.headlineSmall),
                  if (recipe.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      recipe.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (recipe.cuisine != null)
                        Chip(label: Text(recipe.cuisine!)),
                      Chip(
                        label: Text(
                          l10n.recipePrepTime(recipe.prepTimeMinutes),
                        ),
                      ),
                      if (recipe.servings != null)
                        Chip(
                          label: Text(l10n.recipeServings(recipe.servings!)),
                        ),
                      if (recipe.difficulty != null)
                        Chip(
                          label: Text(
                            '${l10n.recipeDifficultyLabel}: ${recipe.difficulty!.label(l10n)}',
                          ),
                        ),
                      Chip(
                        label: Text(
                          l10n.recipeCompletionPercent(match.completionPercent),
                        ),
                      ),
                      if (match.isReadyToCook)
                        Chip(
                          avatar: const Icon(Icons.check_circle, size: 16),
                          label: Text(l10n.recipeReadyToCook),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.recipeIngredientsSection,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final detail in match.ingredientDetails)
                    _IngredientRow(detail: detail, recipe: recipe),
                  if (match.suggestedSubstitutions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.recipeSubstitutionsSection,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(match.suggestedSubstitutions.join('\n')),
                  ],
                  const Divider(height: AppSpacing.xl),
                  Text(
                    l10n.recipeStepsSection,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < recipe.steps.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(recipe.steps[i]),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (match.isReadyToCook)
                        FilledButton.icon(
                          onPressed: () =>
                              runWithFeedback(context, actions.cooked(recipe)),
                          icon: const Icon(Icons.restaurant_outlined),
                          label: Text(l10n.recipeCookNow),
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
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.recipeSavedLocally)),
                          );
                        },
                        icon: const Icon(Icons.bookmark_outline),
                        label: Text(l10n.recipeSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.detail, required this.recipe});

  final IngredientMatchDetail detail;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ingredient = recipe.ingredients.firstWhere(
      (i) => i.name == detail.ingredientName,
      orElse: () => RecipeIngredient(
        id: '',
        recipeId: recipe.id,
        name: detail.ingredientName,
        optional: detail.optional,
      ),
    );

    final (icon, color) = switch (detail.kind) {
      IngredientMatchKind.exact => (
        Icons.check_circle,
        theme.colorScheme.primary,
      ),
      IngredientMatchKind.substitution => (
        Icons.swap_horiz,
        theme.colorScheme.tertiary,
      ),
      IngredientMatchKind.partial => (
        Icons.warning_amber_rounded,
        theme.colorScheme.secondary,
      ),
      IngredientMatchKind.missing => (
        Icons.cancel_outlined,
        theme.colorScheme.error,
      ),
    };

    final locationNote = detail.locations.isEmpty
        ? null
        : detail.locations.join(', ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(detail.ingredientName),
      subtitle: Text(
        [
          if (ingredient.quantity != null)
            '${ingredient.quantity!.amount} ${ingredient.quantity!.unit.label(l10n)}',
          if (detail.optional) l10n.optionalSuffix,
          if (detail.substitutionUsed != null)
            l10n.recipeUsingSubstitution(detail.substitutionUsed!),
          if (detail.kind == IngredientMatchKind.partial)
            l10n.recipePartialMatch,
          ?locationNote,
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    );
  }
}
