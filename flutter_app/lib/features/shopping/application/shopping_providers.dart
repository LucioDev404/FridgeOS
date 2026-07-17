import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/domain/entities/shopping_list_item.dart';
import 'package:fridgeos/features/shopping/application/shopping_actions.dart';

final shoppingActionsProvider = Provider<ShoppingActions>(
  (ref) => ShoppingActions(
    shopping: ref.watch(shoppingRepositoryProvider),
    policy: ref.watch(shoppingListPolicyProvider),
    sanitizer: ref.watch(inputSanitizerProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final pendingShoppingItemsProvider = StreamProvider<List<ShoppingListItem>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchPending(),
);
