# 07 — Architecture

FridgeOS uses **Clean Architecture** with a **feature-first** layout. Dependencies
point inward: presentation → domain ← data ← infrastructure. The **domain** layer is
pure Dart and knows nothing about Flutter, Drift, HTTP or platform APIs.

## 1. Layers

```
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION  (Flutter, Material 3, Riverpod, GoRouter)      │
│   widgets/screens, controllers (Notifier/AsyncNotifier),     │
│   view models, routing. No business rules here.              │
└───────────────▲─────────────────────────────────────────────┘
                │ depends on (calls use cases, reads entities)
┌───────────────┴─────────────────────────────────────────────┐
│ DOMAIN  (pure Dart)                                          │
│   entities, value objects, domain services,                 │
│   use cases (interactors), repository *interfaces*,         │
│   failures/result types. Depends on nothing.                │
└───────────────▲─────────────────────────────────────────────┘
                │ implemented by
┌───────────────┴─────────────────────────────────────────────┐
│ DATA  (repository implementations, DTOs, mappers)           │
│   Drift DAOs, OpenFoodFacts client, cache policy.           │
│   Maps infrastructure ↔ domain entities.                    │
└───────────────▲─────────────────────────────────────────────┘
                │ uses
┌───────────────┴─────────────────────────────────────────────┐
│ INFRASTRUCTURE  (platform & I/O)                            │
│   Drift/SQLite database, secure storage, HTTP client,       │
│   ML Kit barcode, local notifications, file/backup,         │
│   clock, uuid, connectivity. Thin, swappable adapters.      │
└─────────────────────────────────────────────────────────────┘
```

**Dependency rule:** source dependencies only ever point toward the domain. The
domain defines repository *interfaces*; the data layer implements them; DI wires
concrete implementations at the composition root.

## 2. Feature-first module layout

```
flutter_app/lib/
  app/                     # composition root, router, theme, DI overrides
    app.dart
    router.dart
    theme/
  core/                    # cross-cutting, dependency-free-ish shared code
    error/                 # Failure types, Result/Either
    utils/                 # clock, uuid, validators, extensions
    validation/            # shared input validators/sanitizers
    result.dart
  domain/                  # (some teams nest domain per-feature; we keep shared
                           #  value objects here and feature entities per feature)
  features/
    inventory/
      domain/              # entities, value objects, repository interfaces, use cases
      data/                # repo impl, drift DAO wiring, mappers
      presentation/        # screens, widgets, controllers (Riverpod)
    barcode/
      domain/ data/ presentation/
    expiration/
      domain/ data/ presentation/
    recipes/
      domain/ data/ presentation/
    shopping/
      domain/ data/ presentation/
    history/
      domain/ data/ presentation/
    statistics/
      domain/ data/ presentation/
    settings/              # incl. backup/restore, preferences
      domain/ data/ presentation/
  infrastructure/
    database/              # Drift database, tables, DAOs, migrations
    network/               # http client, OpenFoodFacts api
    security/              # secure storage, crypto (backup), keys
    notifications/         # local notifications adapter
    scanner/               # ML Kit barcode adapter
    platform/              # connectivity, file picker, clock
  l10n/                    # ARB localization
  main.dart
```

Rationale: feature-first keeps each vertical slice cohesive and independently
testable; the four layers exist *within* each feature (domain/data/presentation)
plus a shared `infrastructure` for platform adapters and `core` for cross-cutting
primitives. This avoids both god-packages and premature abstraction.

## 3. Dependency Injection (Riverpod)

- Riverpod is the single DI + state mechanism. Providers form the composition root.
- **Infrastructure providers** expose singletons (database, http client, secure
  storage, scanner, notifications, clock, uuid).
- **Data providers** build repositories from infrastructure providers and implement
  domain interfaces.
- **Domain use cases** are plain classes constructed with repository interfaces,
  exposed via providers.
- **Presentation controllers** (`Notifier`/`AsyncNotifier`) depend only on use-case
  / repository providers.
- Tests override providers with fakes/mocks (`ProviderContainer` with overrides),
  giving hermetic unit/widget tests.

```
databaseProvider ─┐
secureStorage ────┼─▶ inventoryRepositoryProvider ─▶ adjustQuantityUseCaseProvider ─▶ InventoryController
clock / uuid ─────┘                                   (AsyncNotifier)  ─▶ widgets
```

No global mutable singletons outside the provider graph; no service locators
hand-rolled; no `GetIt` needed (avoid redundant DI stack).

## 4. State management conventions

- UI state via `AsyncNotifier`/`Notifier`; expose immutable state objects
  (`freezed` or hand-written immutable classes) — **no mutable global state**.
- Data reaches the UI as **streams** from Drift (reactive lists) surfaced through
  `StreamProvider`/`AsyncNotifier`, so writes reflect instantly.
- Controllers orchestrate use cases; they contain **no business rules** — those live
  in domain services/use cases.

## 5. Navigation (GoRouter)

- Declarative routes defined in `app/router.dart`.
- Tablet-oriented shell route with a persistent navigation rail + nested content.
- Deep-linkable routes for main destinations (Home, Scan, Inventory, Expiring,
  Recipes, Shopping, History, Stats, Settings).
- Scanner is a full-screen route returning a result to the caller.

## 6. Error handling

- Domain returns a `Result<Success, Failure>` (functional style) rather than
  throwing for expected errors; unexpected errors are exceptions caught at the
  boundary.
- `Failure` taxonomy: `ValidationFailure`, `NotFoundFailure`, `NetworkFailure`,
  `PersistenceFailure`, `PermissionFailure`, `CryptoFailure`.
- Presentation maps failures to calm, actionable UI states (never raw stack traces).
- Network failures are always non-fatal to core flows (offline-first).

## 7. Key data flows

### 7.1 Scan → add (UC-1)
```
ScanScreen ──result(barcode)──▶ ScanController
   └▶ ScanBarcodeUseCase
        └▶ ProductRepository.findByBarcode(local)         # infra: Drift
             ├─ hit ─────────────────────────────▶ return Product
             └─ miss ─▶ (enrichment enabled & online?)
                          └▶ OpenFoodFactsClient.fetch     # infra: HTTPS
                               └▶ validate+sanitize (core/validation)
                                    └▶ ProductRepository.cache(product)  # Drift + barcode_lookups
   ▶ navigate to QuantityAdjuster ▶ AdjustQuantityUseCase
        └▶ InventoryRepository.apply(mutation)  # single txn: item + event
             └▶ Drift streams push update ▶ UI refresh
```

### 7.2 Reactive inventory
Drift `Stream<List<InventoryItemRow>>` → mapper → `Stream<List<InventoryItem>>` →
`StreamProvider` → screen. A mutation commits a transaction; the stream re-emits;
the list rebuilds. No manual cache invalidation.

## 8. Concurrency & threading

- Drift runs on a background isolate where beneficial; heavy pure computations
  (e.g. large statistics aggregation, recipe ranking over big sets) can run via
  `compute`/isolates if profiling shows main-thread jank.
- ML Kit runs off the UI thread (plugin-managed); camera frames are throttled.

## 9. Testability strategy (maps to Testing Requirements)

| Layer | What we test | How |
|-------|--------------|-----|
| Domain | value-object invariants, services (ranking, expiration, thresholds), use cases | pure unit tests, no mocks needed |
| Data | repository impls, mappers, cache policy (FR-BAR-6), OFF client parsing | fakes + in-memory Drift + fake HTTP |
| Infrastructure | migrations, secure storage, crypto (backup) | Drift migration tests, instrumentation |
| Presentation | controllers, screens, empty/error states, a11y semantics, golden layouts | widget tests with provider overrides |
| End-to-end | UC-1/3/9, offline behavior | integration_test on emulator/device |

## 10. Cross-cutting concerns

- **Clock & UUID** are injected (`Clock`, `IdGenerator`) so time/id-dependent logic
  is deterministic in tests.
- **Logging** is a thin, local-only, level-based facade; no remote sinks; stripped
  in release (see NFR-OBS).
- **Configuration constants** (ranking weights, default window, TTLs) live in typed
  config objects, not scattered magic numbers.
- **Localization** via ARB; no hard-coded user-facing strings.

## 11. Why these choices (brief)

- **Clean + feature-first:** isolates business rules from Flutter/DB churn; each
  feature evolves independently; supports the long-term-maintenance goal.
- **Riverpod for DI+state:** compile-safe, testable overrides, no BuildContext
  coupling, avoids a second DI library.
- **Drift streams:** reactive UI with minimal glue → "instant" updates for free.
- **Result types over exceptions:** makes offline/validation failures explicit and
  testable, aligning with security's "validate everything" stance.
- **Adapters in infrastructure:** ML Kit, HTTP, notifications, crypto are swappable
  behind interfaces, protecting the core from third-party API changes.

## 12. Rejected / deferred alternatives

| Considered | Decision | Reason |
|-----------|----------|--------|
| BLoC | Not used | Riverpod covers state+DI with less boilerplate for this scope |
| GetIt/injectable | Not used | Riverpod already provides DI; avoid redundant dependency |
| REST backend / accounts | Deferred | Offline-first, privacy; schema is sync-ready for later |
| ObjectBox/Isar | Not used | Drift+SQLite is mature, relational, migration-friendly, SQLCipher-ready |
| FTS5 search | Deferred | Add only if indexed LIKE misses the perf budget |
