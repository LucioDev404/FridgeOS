# Changelog

All notable changes to FridgeOS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Phase 1 — Documentation & architecture.**
  - Product vision, functional and non-functional requirements.
  - Software Requirements Specification (SRS).
  - Domain model and normalized database design (Drift/SQLite) with migration and
    sync strategy.
  - Clean Architecture proposal (feature-first, four layers, Riverpod DI).
  - Threat model (STRIDE) and security design mapped to OWASP MASVS / Mobile Top 10.
  - UI guidelines (Material 3, tablet-first, accessibility).
  - Ten-phase development roadmap.
  - Repository skeleton (`docs/`, `scripts/`, `.github/workflows/`).
- **Phase 2 — Project initialization.**
  - Flutter Android application scaffolded under `flutter_app/` (Material 3,
    min SDK 26, `com.fridgeos.fridgeos`).
  - Minimal, pinned dependency set (Riverpod, GoRouter, Drift + sqlite3,
    flutter_secure_storage, http, uuid, intl, Google ML Kit barcode,
    flutter_local_notifications); `pubspec.lock` committed.
  - Clean Architecture feature-first folder structure and cross-cutting core
    primitives (`Result`/`Failure`, `Clock`, `IdGenerator`, `InputSanitizer`).
  - Adaptive app shell: navigation rail (tablet) / bottom bar (compact),
    GoRouter `StatefulShellRoute` with eight destinations plus a full-screen
    scan route; Material 3 theme and design tokens; reusable empty-state widget.
  - Internationalization scaffolding (ARB, generated localizations).
  - Android hardening: minimal permissions, cleartext traffic disabled, network
    security config, `allowBackup=false`, data-extraction rules, R8
    shrink+obfuscate release config with conditional signing.
  - Strict static analysis config; unit tests (`Result`, `InputSanitizer`),
    widget tests (app shell/navigation) and a manifest security fitness test.
  - CI/CD workflows (format+analyze+test+coverage, secret+dependency audit,
    APK+AAB build) and developer scripts (`bootstrap`, `gen`, `verify`).
- **Phase 3 — Database & domain.**
  - Pure domain layer (`lib/domain/`): self-validating value objects
    (`Barcode` with GTIN check-digit, `Quantity`, `DateOnly`, controlled enums),
    immutable entities (`Product`, `Location`, `InventoryItem`,
    `InventoryEvent`, `Recipe`, `ShoppingListItem`, `UserPreferences`), domain
    services (`ExpirationPolicy`, `InventoryMutationService` enforcing the
    non-negative-quantity and one-event-per-mutation invariants) and repository
    interfaces.
  - Normalized Drift/SQLite schema (11 tables) with UUID keys, soft-delete +
    `sync_version` audit columns, `CHECK` constraints, foreign keys enforced at
    runtime, migration strategy and first-run seeding (default locations,
    preferences, schema-version marker).
  - Drift-backed repositories (Product, Location, Inventory) with row↔domain
    mappers; inventory mutations persist item state and their immutable event in
    a single transaction (atomicity verified by test).
  - SQLCipher-ready security plumbing: `SecretStore` abstraction over
    Keystore-backed secure storage and `DatabaseKeyManager` (256-bit key
    lifecycle); connection opener with a documented encryption extension point.
  - Riverpod wiring for database, repositories and services.
  - 81 passing tests across value objects, services, repository CRUD,
    event-atomicity/rollback, key management and schema/seed verification.

[Unreleased]: https://example.com/fridgeos/tree/master
