import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/repositories/drift_inventory_repository.dart';
import 'package:fridgeos/data/repositories/drift_location_repository.dart';
import 'package:fridgeos/data/repositories/drift_product_repository.dart';
import 'package:fridgeos/domain/repositories/inventory_repository.dart';
import 'package:fridgeos/domain/repositories/location_repository.dart';
import 'package:fridgeos/domain/repositories/product_repository.dart';
import 'package:fridgeos/domain/services/expiration_policy.dart';
import 'package:fridgeos/domain/services/inventory_mutation_service.dart';
import 'package:fridgeos/infrastructure/database/app_database.dart';
import 'package:fridgeos/infrastructure/database/connection.dart';
import 'package:fridgeos/infrastructure/security/database_key_manager.dart';
import 'package:fridgeos/infrastructure/security/secret_store.dart';

/// Data- and infrastructure-layer providers (composition root, see
/// docs/07-architecture.md §3). Tests override [appDatabaseProvider] with an
/// in-memory database and infrastructure providers with fakes.

/// The application database. Overridden in tests with an in-memory instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secretStoreProvider = Provider<SecretStore>(
  (ref) => FlutterSecureSecretStore(),
);

final databaseKeyManagerProvider = Provider<DatabaseKeyManager>(
  (ref) => DatabaseKeyManager(ref.watch(secretStoreProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductRepository(ref.watch(appDatabaseProvider)),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => DriftLocationRepository(ref.watch(appDatabaseProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => DriftInventoryRepository(ref.watch(appDatabaseProvider)),
);

final expirationPolicyProvider = Provider<ExpirationPolicy>(
  (ref) => const ExpirationPolicy(),
);

final inventoryMutationServiceProvider = Provider<InventoryMutationService>(
  (ref) => InventoryMutationService(
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);
