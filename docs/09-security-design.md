# 09 — Security Design

This document turns the [Threat Model](08-threat-model.md) security requirements
(SR-1..SR-10) into concrete controls, defaults and verification. It is organized as
**Security by Design**: secure defaults, defense in depth, least privilege, minimal
attack surface.

## 1. Security objectives (recap)

- Keep all personal/consumption data **on the device**.
- Make the **only** network egress an opt-in, HTTPS, barcode-keyed lookup.
- Treat every external input as hostile.
- Protect data at rest and in backups with vetted cryptography.
- Ship no analytics, tracking, or telemetry.

## 2. Data classification

| Class | Examples | Handling |
|-------|----------|----------|
| Sensitive | Inventory, history, statistics, backups | Encrypted at rest / in backups; never leaves device except as encrypted backup the user exports |
| Secret | DB encryption key, backup key material | Android Keystore via `flutter_secure_storage`; never in code/logs/backups-in-clear |
| Low | OFF-derived product cache | Validated & sanitized; treated as untrusted content |
| Public | App code (minus secrets) | Obfuscated in release |

## 3. Network security (SR-1, M5)

- **HTTPS only.** Android `usesCleartextTraffic=false`; a **network security
  config** disables cleartext for all domains.
- Single allowlisted host: `world.openfoodfacts.org`. Any other egress is a defect
  caught in review/CI.
- HTTP client: sane connect/read timeouts (≤5s), no redirects to non-HTTPS, minimal
  descriptive `User-Agent` per OFF policy, no cookies, no auth headers.
- **Certificate pinning — trade-off (documented decision):** *Not enabled in v1.*
  OFF endpoints/CDNs rotate certificates and pinning risks breaking enrichment
  silently; the data is low-sensitivity and only fetched by barcode. We rely on the
  platform trust store + strict input validation. **Re-evaluate** if enrichment ever
  handles higher-sensitivity data. This is an explicit, revisitable choice.

## 4. Input validation & output encoding (SR-2, SR-3, M4)

- **Self-validating value objects** (`Barcode`, `Quantity`, `Unit`, …) cannot be
  constructed invalid — first validation gate.
- A shared `core/validation` module provides:
  - length caps (e.g. name ≤ 200 chars), type/enum checks, numeric range checks;
  - **sanitization**: strip control chars & markup, normalize Unicode (NFC), reject
    non-printable payloads;
  - JSON schema-style validation for OFF responses and backup envelopes (allowlist
    fields; ignore unknown; bound array sizes).
- **Barcode is never trusted:** validated for format + check digit, used only as a
  lookup key; derived metadata is sanitized before storage/display.
- **SQL:** Drift parameterized queries exclusively; no string-built SQL; FK on.
- **No HTML/remote-markup rendering** of OFF text; remote images not auto-fetched in
  v1.

## 5. Data at rest (SR-4, M9)

- App-private storage only (no external/world-readable files for the live DB).
- **SQLCipher-ready:** the DB open path supports full-file encryption via
  `sqlcipher_flutter_libs`, keyed by a 256-bit random key stored in
  `flutter_secure_storage` (Keystore-backed).
- **Default decision:** enable DB encryption by default when the platform provides a
  hardware-backed keystore; key generated on first launch, never leaves the device,
  never logged. `app_meta.db_encrypted` records the state. (If a target device lacks
  secure keystore support, the app still runs; this is surfaced in diagnostics.)
- No secrets in source control (SR-... enforced by gitleaks in CI).

## 6. Backups & export (SR-5)

- Logical, versioned export → gzip → **AES-256-GCM** (authenticated encryption).
- Key derived from a **user passphrase** via **Argon2id** (memory-hard; fallback
  scrypt) with per-backup random salt; parameters stored in the envelope.
- Envelope: `{format_version, created_at, kdf, kdf_params, salt, nonce, ciphertext, tag}`.
- **Restore:** verify `format_version` and **GCM auth tag** before trusting content;
  then run the same validators as live input; bound sizes; atomic replace within a
  transaction with user confirmation.
- No plaintext export path exists.

## 7. Permissions (SR-6, M8)

| Permission | Why | When requested |
|------------|-----|----------------|
| `CAMERA` | Barcode scanning | On first scan (runtime), with rationale; app works without it via manual entry |
| `POST_NOTIFICATIONS` (API 33+) | Expiration/low-stock digest | On enabling notifications |

Explicitly **not** requested: location, contacts, storage-broad, internet-only via
default (INTERNET is normal-level; egress restricted by network config), no
background location, no read of external media. Manifest is asserted by a test.

## 8. Privacy controls (M6)

- No account, no sign-in, ever.
- No analytics/crash-reporting/telemetry SDKs. (Enforced by dependency audit +
  review; a denylist of known SDKs is checked in CI.)
- Single documented egress (OFF), opt-in, barcode-only, no identifiers.
- In-app privacy note explaining exactly what is (and isn't) sent.
- OFF attribution + ODbL compliance surfaced in the licenses screen.

## 9. Logging & observability (NFR-OBS, SR-10)

- Local-only, level-based logging; **no PII** (no product names/quantities at info+
  level; ids only where needed for debugging in debug builds).
- No remote log sink.
- Release builds strip verbose/debug logs; a lint/CI check flags `print`/debug logs.

## 10. Build hardening (M7)

- Release: R8/ProGuard shrinking + obfuscation; resource shrinking.
- No secrets or API keys in the binary (OFF needs none).
- `debuggable=false`, `allowBackup=false` (we provide our own encrypted backup;
  disable Android auto-backup to prevent cleartext cloud copies).
- Reproducible, signed release artifacts via CI with signing keys kept in CI secrets
  (never in repo).

## 11. Cryptography standards (M10)

| Purpose | Primitive |
|---------|-----------|
| DB at rest | SQLCipher (AES-256) with Keystore-backed key |
| Backup confidentiality+integrity | AES-256-GCM |
| Passphrase → key | Argon2id (scrypt fallback), random salt |
| Randomness | Platform CSPRNG |
| Key storage | Android Keystore via flutter_secure_storage |

No custom/home-grown cryptographic constructions. Use maintained, audited libraries.

## 12. Secure SDLC & CI gates (SR-9)

CI (see [Roadmap](11-roadmap.md) & `.github/workflows/`) enforces:

- `dart format` check, `flutter analyze` (zero warnings).
- Unit/widget/integration tests + coverage thresholds.
- **Secret scanning** (gitleaks).
- **Dependency audit** (`flutter pub outdated`, license check, telemetry-SDK
  denylist).
- **Egress/permission review gate:** manifest permission assertion test + a check
  that no new network hosts are introduced.
- No `TODO`/placeholder on `master`.

## 13. OWASP MASVS coverage snapshot

| MASVS group | Posture |
|-------------|---------|
| STORAGE | Encrypted at rest (SQLCipher-ready), Keystore keys, encrypted backups, no PII in logs |
| CRYPTO | Vetted primitives, platform keystore, no hard-coded keys |
| AUTH | N/A by design (no accounts); documented residual risk |
| NETWORK | HTTPS-only, cleartext disabled, single allowlisted host, pinning trade-off documented |
| PLATFORM | Least permissions, no unsafe IPC surface, no WebView for remote content |
| CODE | Input validation everywhere, safe parsing, obfuscation, no debug in release |
| RESILIENCE | Not a primary goal (offline consumer app); basic tamper-resistance via obfuscation |
| PRIVACY | No telemetry, minimal egress, on-device data, transparency note |

## 14. Deferred controls & re-evaluation triggers

| Control | Status | Re-evaluate when |
|---------|--------|------------------|
| TLS certificate pinning | Deferred | Enrichment handles sensitive data, or MITM risk profile rises |
| App-lock (biometric/PIN) | Deferred | Shared device shows real shoulder-surf risk / user demand |
| Sync/server security | Deferred | A sync backend is actually built (schema already sync-ready) |
| Remote image fetch sandboxing | Deferred | Product images are enabled (v1 stores URL only) |

## 15. Verification matrix (selected)

| Control | Test |
|---------|------|
| Cleartext disabled | Instrumentation/manifest assertion; attempt HTTP → blocked |
| OFF input sanitization | Unit tests with hostile payloads (HTML, oversize, wrong types) |
| Parameterized SQL | Code review + injection-attempt unit test |
| Backup encryption/integrity | Unit test: output not plaintext; tampered file fails auth |
| Key storage | Instrumentation: key present in secure storage, absent from DB/logs |
| Permissions minimal | Manifest assertion test |
| No telemetry SDKs | CI dependency denylist check |
| Immutable history | Repository test: no update/delete API; attempt fails/absent |
