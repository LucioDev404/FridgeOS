# 03 — Non-Functional Requirements

Identifiers `NFR-<attribute>-<n>`. Each NFR has a measurable target and a
verification method. These constrain the whole system and are re-stated as fitness
functions in CI where possible.

---

## 1. Performance (PERF)

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR-PERF-1 | Cold start to interactive home screen | < 2 s on mid-range tablet (e.g. SD 7-gen / 4 GB RAM) | Manual profiling + `flutter run --profile` timeline; DevTools |
| NFR-PERF-2 | Inventory quantity update reflected in UI | < 100 ms (perceived instant) | Widget/integration timing test |
| NFR-PERF-3 | Barcode recognition from stable frame | < 1 s | Manual measurement on device + camera-off unit tests for parsing |
| NFR-PERF-4 | UI frame rate during scroll/animation | ≥ 60 FPS (no frames > 16 ms sustained) | DevTools performance overlay; jank check in profile mode |
| NFR-PERF-5 | Local search over 5,000 inventory items | < 150 ms | Benchmark test against seeded DB |
| NFR-PERF-6 | OpenFoodFacts request timeout | ≤ 5 s, non-blocking to UI | Integration test with fake HTTP client |

## 2. Reliability & availability (REL)

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR-REL-1 | All core features function fully offline | 100% of INV/LOC/EXP/HIST/SHOP/STAT with no network | Integration tests run with network disabled |
| NFR-REL-2 | Crash-free sessions (dev/QA instrumentation only) | > 99.5% | QA runs; no crash reporting in production |
| NFR-REL-3 | No data loss on process kill / power loss | Committed transactions durable | Drift transactional writes; kill-during-write test |
| NFR-REL-4 | Network failure never blocks a user action | Graceful degradation with clear state | Fault-injection integration tests |
| NFR-REL-5 | Database migrations preserve all user data | Verified up→up path for every version | Migration tests from each prior schema version |

## 3. Security (SEC) — see [Security Design](09-security-design.md) for controls

| ID | Requirement | Verification |
|----|-------------|--------------|
| NFR-SEC-1 | External communication uses HTTPS/TLS only; cleartext disabled | Manifest `usesCleartextTraffic=false`; network security config test |
| NFR-SEC-2 | All external input (OpenFoodFacts, barcode payload, backups) is validated and sanitized before use | Unit tests on validators/mappers with malformed input |
| NFR-SEC-3 | No secrets, keys or credentials in source control | Secret-scanning in CI (gitleaks) |
| NFR-SEC-4 | Local sensitive data (encryption keys) stored via `flutter_secure_storage` (Keystore-backed) | Code review + instrumentation test |
| NFR-SEC-5 | Backups are encrypted at rest with authenticated encryption | Unit test: backup file is not plaintext and tamper is detected |
| NFR-SEC-6 | Minimum Android permissions (CAMERA; POST_NOTIFICATIONS on 13+) | Manifest assertion test |
| NFR-SEC-7 | No analytics/tracking/telemetry SDKs present | Dependency audit + manifest/network review in CI |
| NFR-SEC-8 | Database prepared for encryption at rest (SQLCipher-ready) | Design + toggle test |

## 4. Privacy (PRIV)

| ID | Requirement | Verification |
|----|-------------|--------------|
| NFR-PRIV-1 | No account required to use any feature | Functional test with no sign-in path |
| NFR-PRIV-2 | Only outbound data is a barcode string to OpenFoodFacts (opt-in) | Network capture review; single documented egress |
| NFR-PRIV-3 | No personal/consumption data leaves the device | Egress allowlist test |
| NFR-PRIV-4 | Data collection documented and minimal | Privacy note in `09-security-design.md` |

## 5. Usability & accessibility (UX)

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR-UX-1 | Most common action (adjust known item) | ≤ 3 interactions | Task walkthrough |
| NFR-UX-2 | Touch targets | ≥ 48×48 dp | Widget audit |
| NFR-UX-3 | Text contrast | WCAG AA (≥ 4.5:1 body) | Design tokens + audit |
| NFR-UX-4 | Dynamic type / large font support | Layout intact at 130% scale | Widget test at scaled text |
| NFR-UX-5 | Screen-reader labels on all interactive elements | 100% actionable widgets labelled | Semantics test |
| NFR-UX-6 | Tablet landscape & portrait supported | No overflow/clipping | Golden tests at target sizes |

## 6. Compatibility (COMPAT)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-COMPAT-1 | Minimum Android API | 26 (Android 8.0) |
| NFR-COMPAT-2 | Target Android API | Latest stable at build time |
| NFR-COMPAT-3 | Form factor | Tablet-first (7"–13"), phone best-effort |
| NFR-COMPAT-4 | Orientation | Landscape and portrait |
| NFR-COMPAT-5 | Locale | English baseline; i18n-ready (ARB), no hard-coded strings |

## 7. Maintainability (MAINT)

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR-MAINT-1 | Static analysis clean | 0 warnings/errors under `flutter_lints` (or stricter) | `flutter analyze` in CI |
| NFR-MAINT-2 | Consistent formatting | `dart format` produces no diff | CI format check |
| NFR-MAINT-3 | Meaningful test coverage on domain & data layers | ≥ 80% line coverage on `domain/` and `data/`; critical logic ~100% | Coverage report in CI |
| NFR-MAINT-4 | No business logic in widgets | Enforced by review + layering | Architecture review, import lint |
| NFR-MAINT-5 | Dependency count kept minimal & pinned | Every dependency justified; versions pinned | `pubspec` review; `flutter pub outdated`/audit in CI |
| NFR-MAINT-6 | No dead/placeholder code, no `TODO` in main | 0 TODOs on `master` | grep check in CI |

## 8. Portability & data ownership (PORT)

| ID | Requirement |
|----|-------------|
| NFR-PORT-1 | User can export and import all their data (encrypted, documented format). |
| NFR-PORT-2 | Schema and backup format are versioned to allow forward migration. |
| NFR-PORT-3 | No hard lock-in: data model documented for future sync/server. |

## 9. Observability (OBS)

| ID | Requirement |
|----|-------------|
| NFR-OBS-1 | Structured, **local-only** logging with levels; no PII in logs; no remote log sink. |
| NFR-OBS-2 | Debug/profile builds may expose a diagnostics screen; release builds strip verbose logs. |

## 10. Legal & compliance (LEGAL)

| ID | Requirement |
|----|-------------|
| NFR-LEGAL-1 | OpenFoodFacts data usage complies with its (ODbL) license; attribution provided. |
| NFR-LEGAL-2 | Third-party licenses aggregated and shown in-app (Flutter `showLicensePage`). |
| NFR-LEGAL-3 | GDPR posture is trivially satisfied: no personal data processing off-device. |

---

## Performance budget summary

| Budget | Value |
|--------|-------|
| Cold start | < 2 s |
| Interaction latency (local write) | < 100 ms |
| Barcode recognition | < 1 s |
| Frame budget | 16 ms (60 FPS) |
| Remote lookup timeout | 5 s, non-blocking |
| APK/AAB size | Track and keep reasonable; no hard cap in v1 but monitored |
