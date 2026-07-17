# Changelog

All notable changes to FridgeOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- CI format gate: format `settings_screen.dart`.
- App updates: bump to `1.0.1+2` so Android installs over older builds (`versionCode` must increase).

### Added
- **Phase 1 — Documentation & architecture.** Complete `docs/` set (vision, FRs/NFRs,
  SRS, domain, database, architecture, threat model, security design, UI guidelines,
  roadmap).
- **Phase 2 — Project initialization.** Flutter tablet shell, Riverpod/GoRouter,
  Android hardening, CI/CD, scripts, core primitives and smoke tests.
- **Phase 3 — Database & domain.** Drift schema + seeding, domain entities/VOs/services,
  transactional inventory repositories, SQLCipher-ready key management.
- **Phase 4 — Core inventory.** Add/adjust/move/consume/discard/remove flows, Home
  dashboard, Inventory search (name/brand/barcode) + location/category filters,
  Locations management, History screen over the append-only event log.
- **Phase 5 — Barcode integration.** OpenFoodFacts HTTPS client with field
  sanitization, local + negative-TTL lookup cache (no repeat queries), barcode
  resolve service, scan screen with lookup → quantity sheet and manual fallback.
  Core library desugaring enabled for `flutter_local_notifications` release builds.
- **Phase 6 — Expiration.** Expiring/expired grouped views with consume/discard,
  preferences-backed expiring-soon window, enrichment toggle, notification
  scheduler abstraction (in-memory + stub).
- **Phase 7 — Recipe engine.** Built-in recipe seeding, `RecipeRanker`, ranked
  Recipes UI with availability meter, add-missing-to-shopping and cooked→consume.
- **Phase 8 — Shopping list.** Manual + AUTO proposals via `ShoppingListPolicy`
  (threshold/zero, dedupe, dismissal cooldown), check-off and dismiss UX.
- **Phase 9 — Hardening.** `StatisticsCalculator` + Statistics screen; encrypted
  backup/restore (AES-256-GCM + PBKDF2-HMAC-SHA256); factory reset; settings wiring.
- **Phase 10 — Release prep.** MIT `LICENSE`, in-app privacy note and Open Food
  Facts attribution, version ready for signed CI artifacts.

### Fixed
- Android release APK build: enable core library desugaring required by
  `flutter_local_notifications`.
- Android release APK build: raise `compileSdk` to 36 (app + Android library
  plugins) so `file_picker` / `flutter_plugin_android_lifecycle` AAR metadata
  checks pass.
- Android release APK build: remove `file_picker` (compileSdk 34 + lifecycle
  metadata conflict) and use app-private backup files + `share_plus` instead.

[Unreleased]: https://github.com/LucioDev404/FridgeOS
