# 11 — Development Roadmap

Ten phases, delivered incrementally. **No phase is skipped.** No implementation code
is written before Phase 1 is complete. Each phase ends only when its quality gate
passes: `dart format` (clean), `flutter analyze` (zero warnings),
`flutter test` (green), and the phase's specific tests are meaningful (no fake
coverage).

## Definition of Done (applies to every phase)

- Requirements traced (FR/NFR referenced) and acceptance criteria met.
- Unit + widget + (where relevant) integration tests added and passing.
- `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` all pass.
- No `TODO`/placeholder/dead code on `master`; docs & CHANGELOG updated.
- Security review of anything touching input, storage, or network.

---

## Phase 1 — Documentation & architecture ✅
**Goal:** Complete, coherent design so implementation is unambiguous.
**Deliverables:** all `docs/` (this set), repository skeleton, README, CHANGELOG.
**Exit criteria:** documents cross-referenced and internally consistent; stack and
schema decided; threat model + security design approved.

## Phase 2 — Project initialization ✅
**Goal:** Bootable Flutter tablet app skeleton with tooling & CI.
**Scope:**
- `flutter create` app under `flutter_app/`; Material 3, min SDK 26.
- Add core deps (Riverpod, GoRouter, Drift, secure storage, ML Kit, http) — pinned.
- Folder structure per [Architecture](07-architecture.md); analysis_options (strict
  lints); `dart format` config; l10n scaffolding.
- App shell: navigation rail + empty routed screens; theming/tokens.
- `.github/workflows/`: format, analyze, test, dependency+secret audit, APK & AAB
  build; `scripts/` helpers.
- Network security config (no cleartext); manifest with minimal permissions.
**Tests:** smoke widget test (app boots), CI runs green, manifest permission
assertion test.
**Exit:** app launches on emulator; CI pipelines pass.

## Phase 3 — Database & domain ✅
**Goal:** Persistence + pure domain foundation.
**Scope:**
- Drift tables/DAOs per [Database Design](06-database-design.md); migration strategy
  + schema export; seed data.
- SQLCipher-ready open path + key via secure storage (encryption toggle).
- Domain: entities, value objects (self-validating), domain services
  (ExpirationPolicy, InventoryMutationService, RecipeRanker, ShoppingListPolicy,
  StatisticsCalculator), repository interfaces, Result/Failure types.
- `core/validation` module.
**Tests (heavy):** value-object invariants, domain services, migration tests
(each version), DAO CRUD on in-memory DB, transaction/event-atomicity test.
**Exit:** domain ~100% covered on critical logic; migrations verified.

## Phase 4 — Core inventory ✅
**Goal:** Add/remove/update/search/categorize/locate + immutable events + reactive UI.
**Scope:** inventory repository impl; use cases (add, adjust, move, remove, search);
Riverpod controllers; Inventory & Home dashboard screens; locations management;
event logging within transactions.
**Requirements:** FR-INV-*, FR-LOC-*, FR-HIST-1..4.
**Tests:** repo tests, use-case tests, widget tests (list, quantity adjuster,
empty/error), integration (add→adjust→remove with events), golden layouts.
**Exit:** UC-2/3/4 fully working offline; instant updates verified.

## Phase 5 — Barcode integration ✅
**Goal:** Scan → local lookup → OFF enrichment → cache → manual fallback.
**Scope:** ML Kit scanner adapter; barcode value object + validator; OFF HTTPS
client with validation/sanitization; cache policy incl. `barcode_lookups`
(no-repeat, negative TTL); scan → quantity flow.
**Requirements:** FR-BAR-*, SR-1/2, M4/M5.
**Tests:** barcode parsing/check-digit, OFF client with fake HTTP (valid/malformed/
not-found/timeout), no-repeat-query test (AC-BAR-6), offline fallback (AC-BAR-8),
sanitization of hostile fields (AC-BAR-5). Camera path validated manually on device.
**Exit:** UC-1 end-to-end; offline & online paths covered.

## Phase 6 — Expiration system ✅
**Goal:** Expiring/expired views + local notifications.
**Scope:** ExpirationPolicy wired to UI; Expiring/Expired screens; discard/consume
actions (waste/consume events); local notification scheduler + daily digest;
settings for window & digest time.
**Requirements:** FR-EXP-*, FR-NOT-*.
**Tests:** expiry classification (boundaries), scheduling logic (injected clock),
widget tests for views, notification-content privacy (generic text).
**Exit:** UC-5 working; notifications generated on-device only.

## Phase 7 — Recipe engine ✅
**Goal:** Ranked suggestions from stock.
**Scope:** recipes/ingredients data + seed built-in recipes; RecipeRanker wired;
Recipes list/detail; "add missing to shopping", "cooked" (optional decrement);
preferences.
**Requirements:** FR-REC-*.
**Tests:** ranking determinism & weight behavior, hard-filter tests, availability
computation, widget tests (availability meter, missing list), cooked→inventory
decrement integration.
**Exit:** UC-6 working; ranking fully unit-tested.

## Phase 8 — Shopping list ✅
**Goal:** Manual + auto-generated items.
**Scope:** shopping repository/use cases; ShoppingListPolicy (threshold/zero →
propose, no duplicates, dismissal cooldown); Shopping screen; check-off + optional
restock; recipe integration.
**Requirements:** FR-SHOP-*.
**Tests:** policy tests (thresholds, dedupe, cooldown — AC-SHOP-2), widget tests,
integration (consume→auto-propose).
**Exit:** UC-7 working end-to-end.

## Phase 9 — Testing & hardening ✅
**Goal:** Raise robustness, security and coverage to release bar.
**Scope:** statistics screens (most-consumed, waste, trends) from event log;
encrypted backup/restore (AES-GCM + Argon2id) + UI; factory reset; app-wide error
states; performance profiling to hit budgets; security verification matrix
(§15 of Security Design); accessibility & golden test sweep; dependency & secret
audit review; obfuscation/build hardening; `allowBackup=false`, cleartext-off
verified.
**Requirements:** FR-STAT-*, FR-SET-3/4/6/7, NFR-* budgets, SR-* controls.
**Tests:** backup crypto round-trip + tamper (AC-SET-3), stats projections against
fixtures, offline integration sweep (AC-REL-1), migration full-path, perf checks.
**Exit:** all NFR budgets met or documented; security controls verified.

## Phase 10 — Release preparation ✅
**Goal:** Shippable artifacts & docs.
**Scope:** finalize license (LICENSE), in-app licenses/privacy note & OFF
attribution; versioning + CHANGELOG; signed release build config (keys in CI
secrets); reproducible APK + AAB via CI; store-listing assets/notes; final security
& a11y sign-off; tag release.
**Exit:** CI produces signed APK & AAB; docs complete; v1.0.0 tagged.

---

## Cross-cutting workstreams (continuous)

- **CI/CD:** kept green from Phase 2; gates tighten as features land.
- **Security:** each PR touching input/storage/network gets a focused review vs.
  [Security Design](09-security-design.md).
- **Docs:** update relevant `docs/` + CHANGELOG within the same PR as the change.
- **Performance:** profile at Phases 4, 6, 9 against the budget table.

## Milestones

| Milestone | After phase | Meaning |
|-----------|-------------|---------|
| M0 Design frozen | 1 | Build can start |
| M1 Walking skeleton | 2 | App boots, CI green |
| M2 Inventory MVP | 4 | Core value usable offline |
| M3 Scan MVP | 5 | North-star flow works |
| M4 Smart kitchen | 7 | Expiry + recipes |
| M5 Feature complete | 8 | All FRs implemented |
| M6 Release candidate | 9 | Hardened & tested |
| M7 v1.0.0 | 10 | Shipped |

## Risk-based sequencing rationale

Database/domain precede UI so business rules are proven before pixels. Barcode
(highest external-input risk) comes right after core inventory so its validation is
built on a solid, tested foundation. Backup/crypto and full security verification are
concentrated in Phase 9 once the data model is stable, avoiding rework.
