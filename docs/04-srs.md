# 04 — Software Requirements Specification (SRS)

Consolidated, testable specification following the spirit of IEEE 830. It ties
together the [functional](02-functional-requirements.md) and
[non-functional](03-non-functional-requirements.md) requirements with actors, use
cases, external interfaces and acceptance criteria.

## 1. Introduction

### 1.1 Purpose
Define the complete requirements for **FridgeOS v1**, an offline-first Android
tablet application for household food inventory management, so that implementation
(Phases 2–10) and testing can proceed unambiguously.

### 1.2 Scope
See [Product Vision §Scope](01-product-vision.md). In short: local inventory,
barcode scanning with optional OpenFoodFacts enrichment, expiration management with
local notifications, recipe suggestions, shopping list, immutable history and
statistics, with encrypted backup — all offline-first, no account, no telemetry.

### 1.3 Definitions
| Term | Meaning |
|------|---------|
| Product | A distinct food article, optionally identified by an EAN/UPC barcode (catalog concept). |
| Inventory item | A concrete stock of a product in a location, with quantity and optional expiration. |
| Location | A storage place: refrigerator, freezer, pantry (or user-defined of those types). |
| Event | An immutable record of an inventory change. |
| Enrichment | Fetching product metadata from OpenFoodFacts by barcode. |
| Expiring-soon window | Configurable number of days before expiry when an item is flagged. |

### 1.4 References
Functional Requirements (02), Non-Functional Requirements (03), Domain Model (05),
Database Design (06), Architecture (07), Threat Model (08), Security Design (09).

## 2. Overall description

### 2.1 Product perspective
Standalone mobile application. Single external dependency: OpenFoodFacts REST API
over HTTPS, used only for barcode-keyed metadata and only when enabled and online.
No backend is built for v1; the data model is designed to allow a future sync
server (see [Database Design §Sync](06-database-design.md)).

### 2.2 Actors
| Actor | Description |
|-------|-------------|
| Household user | Any person using the shared tablet. No authentication; all users are equivalent. |
| System scheduler | On-device component that triggers expiration/digest notifications. |
| OpenFoodFacts (external system) | Read-only source of product metadata by barcode. |

### 2.3 Operating environment
Android 8.0+ (API 26+), tablet-first, touch input, camera required for scanning,
network optional.

### 2.4 Constraints
Offline-first; HTTPS-only egress; minimal permissions (CAMERA, POST_NOTIFICATIONS);
no analytics; Flutter + Material 3; Riverpod, GoRouter, Drift/SQLite,
flutter_secure_storage, Google ML Kit.

### 2.5 Assumptions & dependencies
- The tablet has a functioning rear (or front) camera.
- The device clock is roughly correct (used for expiration; see risk in Threat Model).
- OpenFoodFacts availability is best-effort; the app must tolerate its absence.

## 3. External interface requirements

### 3.1 User interfaces
Material 3 tablet UI. Primary surfaces: Home (dashboard), Scan, Inventory,
Expiring, Recipes, Shopping list, History/Stats, Settings. See
[UI Guidelines](10-ui-guidelines.md).

### 3.2 Hardware interfaces
Camera (barcode scanning via ML Kit). No other hardware.

### 3.3 Software interfaces — OpenFoodFacts

| Item | Specification |
|------|---------------|
| Endpoint | `GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json` (fields limited via query) |
| Auth | None |
| Request | Barcode string only; descriptive User-Agent per OFF policy |
| Success | JSON with product fields; map only allowlisted fields |
| Not found | `status: 0` → treat as negative result, cache with TTL |
| Failure/timeout | Network/HTTP error → degrade gracefully, do not cache as negative |
| Fields consumed | product_name, brands, quantity, categories_tags, image_small_url (metadata only; not auto-downloaded in v1 unless enabled) |
| Validation | Length caps, type checks, HTML/script stripping, encoding normalization before persistence |

### 3.4 Communications
TLS 1.2+ only. Cleartext traffic disabled at the platform level. Single documented
egress host.

## 4. Use cases (primary)

Each use case lists precondition → main flow → alternates → postcondition, and the
FRs it satisfies.

### UC-1 Scan and adjust a known product (north-star)
- **Satisfies:** FR-BAR-1..3,9; FR-INV-1,3; FR-HIST-1,2.
- **Pre:** App open, camera permission granted.
- **Main:** User taps Scan → points at barcode → system decodes (< 1 s) → looks up
  locally → product found → shows quantity adjuster prefilled → user taps +1/−1 or
  confirms add → system writes inventory change in a transaction and appends an
  immutable event → confirmation.
- **Alt A (not found locally, online, enrichment on):** query OpenFoodFacts →
  validate → cache product → continue at quantity step.
- **Alt B (not found, offline or disabled or OFF miss):** offer manual creation
  (UC-2) → continue.
- **Post:** Inventory reflects change; event recorded; shopping list updated if a
  threshold crossed.

### UC-2 Create product manually
- **Satisfies:** FR-BAR-7; FR-INV-1,7,13; FR-LOC-1.
- **Main:** User enters name, category, unit, (optional) barcode, location →
  validate → save product + inventory item → event recorded.

### UC-3 Consume / remove stock
- **Satisfies:** FR-INV-2,3,4; FR-HIST-1,2; FR-SHOP-2.
- **Main:** From an item card, user decrements or removes → transaction updates
  quantity (removes when zero) → `UPDATE_QUANTITY`/`REMOVE_PRODUCT`/`CONSUME`
  event → if below threshold, propose in shopping list.

### UC-4 Move item between locations
- **Satisfies:** FR-INV-9; FR-LOC-3; FR-HIST-2.
- **Main:** User selects item → choose new location → `CHANGE_LOCATION` event.

### UC-5 Review expiring & expired
- **Satisfies:** FR-EXP-2,3,4,5,6; FR-STAT-2.
- **Main:** User opens Expiring view → sees sorted list → for expired item, mark
  discarded (→ `DISCARD` waste event) or consumed (→ `CONSUME`).

### UC-6 Get recipe suggestions
- **Satisfies:** FR-REC-1..6.
- **Main:** User opens Recipes → system ranks recipes by availability, missing
  count, expiration priority, prep time, preferences → user views one → adds
  missing to shopping list or marks cooked (optionally decrement inventory).

### UC-7 Manage shopping list
- **Satisfies:** FR-SHOP-1..5.
- **Main:** User adds manual items; system auto-proposes low/zero stock; user checks
  off items (optionally restock inventory).

### UC-8 Review history & statistics
- **Satisfies:** FR-HIST-5,6; FR-STAT-1,2,3.
- **Main:** User opens History → filter by product/type; opens Statistics → period
  selection → most-consumed, waste, trends (all from local event log).

### UC-9 Backup & restore
- **Satisfies:** FR-SET-3,4,6; NFR-SEC-5.
- **Main:** User creates encrypted backup (passphrase) → file saved via system
  picker → later restore validates and decrypts → data replaced/merged with
  confirmation.

### UC-10 Configure & reset
- **Satisfies:** FR-SET-2,5,7,8; FR-NOT-4.
- **Main:** User toggles enrichment, sets expiring window & digest time, theme;
  performs confirmed factory reset.

## 5. Acceptance criteria (representative, testable)

Written Given/When/Then. The full set is realized as automated tests during each
implementation phase.

| Ref | Given | When | Then |
|-----|-------|------|------|
| AC-INV-3 | An item with quantity 3 | user taps −1 | quantity becomes 2, UI updates < 100 ms, `UPDATE_QUANTITY` event with delta −1 exists |
| AC-INV-4 | An item with quantity 1 | user taps −1 | item leaves active stock, `REMOVE_PRODUCT`/`CONSUME` event exists, history retained |
| AC-BAR-6 | A barcode previously enriched and cached | user scans it again | no network request is made; cached data is used |
| AC-BAR-8 | Device offline, barcode unknown locally | user scans | user is offered manual creation and can complete it |
| AC-BAR-5 | OFF returns a product with an oversized/HTML-laden name | enrichment runs | stored name is length-capped and sanitized (no markup) |
| AC-EXP-2 | Items with expiry in 2 and 10 days, window = 3 | user opens Expiring | only the 2-day item is listed as expiring-soon |
| AC-HIST-3 | Any existing event | app runs normally | no code path updates or deletes it (append-only) |
| AC-REC-3 | Two recipes, one using a soon-to-expire ingredient | suggestions computed | the expiration-prioritized recipe ranks higher, ceteris paribus |
| AC-SHOP-2 | An item drops below its threshold | quantity is decremented | it appears as an auto-proposed shopping item, visually distinct |
| AC-SET-3 | Populated database | user creates a backup with passphrase | resulting file is encrypted (not plaintext) and restorable only with the passphrase |
| AC-SEC-1 | Any build | app attempts external call | only HTTPS to the OFF host occurs; cleartext is rejected |
| AC-REL-1 | Airplane mode | user performs INV/EXP/HIST/SHOP actions | all succeed with no error dialogs |

## 6. Data requirements
See [Domain Model](05-domain-model.md) and [Database Design](06-database-design.md).
Key rules: immutable event log (append-only), UUID primary keys, soft-delete +
`updatedAt`/`deletedAt` for sync readiness, referential integrity via foreign keys,
normalized schema.

## 7. Non-functional requirements
Incorporated by reference from [03](03-non-functional-requirements.md); each NFR is
a binding acceptance criterion with the stated verification method.

## 8. Verification & validation
- **Unit tests:** business rules (ranking, expiration, thresholds), validators,
  mappers, repositories (with fakes).
- **Widget tests:** key screens, quantity adjuster, empty/error states, a11y semantics.
- **Integration tests:** end-to-end flows (UC-1, UC-3, UC-9) incl. offline and
  DB migration.
- **CI gates:** format, analyze, test+coverage, dependency & secret audit, APK/AAB
  build.

## 9. Traceability matrix (summary)

| Use case | Functional refs | Key NFRs | Tests (planned) |
|----------|-----------------|----------|-----------------|
| UC-1 | FR-BAR-1..3,9; FR-INV-1,3; FR-HIST-1,2 | PERF-3, REL-1 | unit(parse), widget(adjuster), integration(scan-add) |
| UC-3 | FR-INV-2,3,4; FR-HIST; FR-SHOP-2 | PERF-2 | unit(threshold), integration(consume) |
| UC-5 | FR-EXP-2..6 | — | unit(expiry calc), widget(expiring view) |
| UC-6 | FR-REC-1..6 | PERF-5 | unit(ranking), widget(recipe list) |
| UC-9 | FR-SET-3,4,6 | SEC-5 | unit(crypto), integration(backup/restore) |
| all offline | FR-*, | REL-1, PRIV-2 | integration(no-network) |
