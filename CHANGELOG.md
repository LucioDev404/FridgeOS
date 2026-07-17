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

[Unreleased]: https://example.com/fridgeos/tree/master
