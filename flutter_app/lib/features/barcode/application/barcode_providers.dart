import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/providers.dart';
import 'package:fridgeos/data/providers.dart';
import 'package:fridgeos/data/repositories/drift_barcode_lookup_repository.dart';
import 'package:fridgeos/domain/repositories/barcode_lookup_repository.dart';
import 'package:fridgeos/features/barcode/application/barcode_resolve_service.dart';
import 'package:fridgeos/features/barcode/data/open_food_facts_client.dart';
import 'package:fridgeos/features/expiration/application/expiration_providers.dart';
import 'package:http/http.dart' as http;

final barcodeLookupRepositoryProvider = Provider<BarcodeLookupRepository>(
  (ref) => DriftBarcodeLookupRepository(ref.watch(appDatabaseProvider)),
);

final offProductParserProvider = Provider<OffProductParser>(
  (ref) => OffProductParser(ref.watch(inputSanitizerProvider)),
);

/// Whether OpenFoodFacts enrichment is enabled.
final enrichmentEnabledProvider = Provider<bool>((ref) {
  return ref
      .watch(userPreferencesProvider)
      .maybeWhen(data: (prefs) => prefs.enrichmentEnabled, orElse: () => true);
});

final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HttpOpenFoodFactsClient(
    parser: ref.watch(offProductParserProvider),
    httpGet: (uri, {headers}) async {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
      return (statusCode: response.statusCode, body: response.body);
    },
  );
});

final barcodeResolveServiceProvider = Provider<BarcodeResolveService>(
  (ref) => BarcodeResolveService(
    products: ref.watch(productRepositoryProvider),
    lookups: ref.watch(barcodeLookupRepositoryProvider),
    off: ref.watch(openFoodFactsClientProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    enrichmentEnabled: ref.watch(enrichmentEnabledProvider),
  ),
);
