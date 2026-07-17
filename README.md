# FridgeOS

Offline-first Android tablet application for managing household food inventory.

FridgeOS lives on the kitchen tablet and answers four questions at a glance:
**What do we have? Where is it? What expires soon? What can we cook / must we buy?**

> **Status:** Feature-complete through Phase 10 (inventory, barcode, expiration,
> recipes, shopping, statistics, encrypted backup, release docs). Quality gates:
> format / analyze / test. See the [roadmap](docs/11-roadmap.md) and
> [CHANGELOG](CHANGELOG.md).

---

## Principles

- **Offline-first.** Every core feature works with no network. External services
  (OpenFoodFacts) are an optional enrichment, never a dependency.
- **Security & privacy by design.** No account, no analytics, no tracking, no
  telemetry. Minimal Android permissions. Data stays on the device.
- **Fast UX.** The most common action (scan → adjust quantity → done) takes 2–3
  interactions. Target 60 FPS, cold start < 2 s.
- **Maintainability.** Clean Architecture, feature-first, SOLID, small surface of
  well-maintained dependencies.

## Technology

| Concern            | Choice                              |
| ------------------ | ----------------------------------- |
| Framework          | Flutter (latest stable), Material 3 |
| State management   | Riverpod                            |
| Navigation         | GoRouter                            |
| Local database     | Drift + SQLite (SQLCipher-ready)    |
| Secure storage     | flutter_secure_storage              |
| Barcode scanning   | Google ML Kit Barcode Scanning      |
| Product enrichment | OpenFoodFacts (HTTPS, opt-in)       |

## Repository layout

```
docs/                 Product, architecture and security documentation (Phase 1)
flutter_app/          Flutter application (created in Phase 2)
  test/               Unit & widget tests
  integration_test/   End-to-end / integration tests
scripts/              Developer & CI helper scripts
.github/workflows/    CI/CD pipelines (format, analyze, test, audit, build)
README.md
CHANGELOG.md
```

## Documentation index

| # | Document | Purpose |
|---|----------|---------|
| 01 | [Product Vision](docs/01-product-vision.md) | Why the product exists, users, success metrics |
| 02 | [Functional Requirements](docs/02-functional-requirements.md) | What the system must do |
| 03 | [Non-Functional Requirements](docs/03-non-functional-requirements.md) | Quality attributes & budgets |
| 04 | [Software Requirements Specification](docs/04-srs.md) | Consolidated, testable SRS |
| 05 | [Domain Model](docs/05-domain-model.md) | Entities, aggregates, business rules |
| 06 | [Database Design](docs/06-database-design.md) | Normalized schema, migrations, sync |
| 07 | [Architecture](docs/07-architecture.md) | Layers, modules, DI, data flow |
| 08 | [Threat Model](docs/08-threat-model.md) | Assets, threats (STRIDE), mitigations |
| 09 | [Security Design](docs/09-security-design.md) | Controls mapped to OWASP MASVS/Top 10 |
| 10 | [UI Guidelines](docs/10-ui-guidelines.md) | Design language, layouts, accessibility |
| 11 | [Development Roadmap](docs/11-roadmap.md) | Phased delivery plan |

## Development phases

The project is delivered in ten phases. See the
[roadmap](docs/11-roadmap.md) for details.

1. Documentation & architecture ← **current**
2. Project initialization
3. Database & domain
4. Core inventory
5. Barcode integration
6. Expiration system
7. Recipe engine
8. Shopping list
9. Testing & hardening
10. Release preparation

## Getting started

Requires the Flutter SDK (stable, 3.44.x) and, to build/run on device, the
Android SDK (cmdline-tools + platform + NDK).

```bash
# One-time setup: fetch dependencies and generate sources.
./scripts/bootstrap.sh

# Run the quality gate locally (mirrors CI).
./scripts/verify.sh

# Run the app on a connected Android tablet / emulator.
cd flutter_app && flutter run
```

Generated sources (localizations, and later Drift code) are **not** committed;
run `./scripts/gen.sh` (invoked by bootstrap/verify) to (re)create them.

## Quality gates

Before any feature is considered complete (enforced by CI and `scripts/verify.sh`):

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

All must pass with zero warnings. No TODOs, no placeholder implementations.

## License

To be defined before public release (Phase 10). Intended to be a permissive
open-source license.
