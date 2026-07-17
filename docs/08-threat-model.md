# 08 — Threat Model

Method: asset-centric + **STRIDE** per data-flow, scoped to the mobile app and its
single external dependency (OpenFoodFacts). Aligned with **OWASP MASVS** and the
**OWASP Mobile Top 10 (2024)**. This model is produced *before* implementation and
is a living document to be revisited each phase.

## 1. System context & trust boundaries

```
        ┌──────────────────────── Android tablet (trusted-ish) ─────────────────────────┐
        │                                                                                │
 user ─▶│  FridgeOS app  ──local IPC/UI──  [Flutter runtime]                             │
        │      │                                                                         │
        │      ├─▶ SQLite DB file (app-private storage)   ← Asset: inventory/history     │
        │      ├─▶ flutter_secure_storage (Keystore)      ← Asset: crypto keys           │
        │      ├─▶ Camera (ML Kit, on-device)             ← barcode frames               │
        │      ├─▶ Local notifications                                                    │
        │      └─▶ Backup file (user-chosen location / SAF) ← Asset: exported data       │
        │                                                                                │
        └───────────────┼──────────────── TLS boundary ─────────────────────────────────┘
                        │ HTTPS (barcode only, opt-in)
                        ▼
             OpenFoodFacts API (untrusted external data source)
```

Trust boundaries: (1) app ↔ OS/other apps, (2) app ↔ network/OFF, (3) app ↔
user-supplied files (restore), (4) app ↔ physical device holder (shared tablet).

## 2. Assets

| # | Asset | Why it matters |
|---|-------|----------------|
| A1 | Inventory & consumption data (incl. immutable history) | Reveals household habits/presence; integrity matters for stats |
| A2 | Backup files | Portable copy of A1; higher exposure (leaves the app sandbox) |
| A3 | Encryption keys (DB key, backup KDF material) | Compromise → decrypt A1/A2 |
| A4 | Product cache (OFF-derived) | Low sensitivity, but an injection vector |
| A5 | App integrity / code | Tampering could exfiltrate data |
| A6 | User trust / privacy posture | The product's core promise |

## 3. Actors & threat agents

| Agent | Capability | Motivation |
|-------|-----------|------------|
| Casual local user | Physical access to unlocked shared tablet | Curiosity, accidental data loss |
| Thief / finder of device | Physical access, possibly to storage | Data theft |
| Malicious app on device | Local, sandboxed | Read world-readable data, intercept intents |
| Network attacker (MITM) | On-path between app and OFF | Inject/alter product data, downgrade TLS |
| Malicious/compromised OFF data | Controls response content | Inject malformed/hostile fields |
| Supply-chain attacker | Compromised dependency | Exfiltrate data, add telemetry |

## 4. Data flows (enumerated)

- DF1 User ↔ UI (touch/camera).
- DF2 App ↔ SQLite (read/write).
- DF3 App ↔ secure storage (key read/write).
- DF4 App ↔ OFF over HTTPS (barcode → JSON).
- DF5 App ↔ backup file (export/import via SAF).
- DF6 App ↔ local notification scheduler.

## 5. STRIDE analysis

### DF4 — App ↔ OpenFoodFacts (primary external boundary)
| STRIDE | Threat | Mitigation |
|--------|--------|------------|
| Spoofing | Fake OFF endpoint / MITM impersonation | HTTPS only, system trust store, correct host; optional certificate/host pinning considered (see Security Design trade-off) |
| Tampering | Response body altered on path | TLS integrity; **treat all fields as untrusted** → strict schema validation, allowlist fields, length/type caps, HTML/script stripping |
| Repudiation | N/A (read-only, anonymous) | — |
| Information disclosure | Barcode reveals a scanned product to OFF/network | Opt-in enrichment; only the barcode is sent; no user identifier; documented single egress; cache prevents repeat leakage (FR-BAR-6) |
| DoS | OFF slow/unavailable | Timeout (≤5s), non-blocking, offline fallback, negative-cache with TTL |
| Elevation | Malicious payload triggers code exec (e.g. via unsafe parsing/HTML render) | No HTML rendering of remote text; parse JSON defensively; never `eval`; images not auto-fetched in v1 |

### DF2/DF3 — App ↔ SQLite & secure storage (data at rest)
| STRIDE | Threat | Mitigation |
|--------|--------|------------|
| Tampering | Attacker with device access edits DB file | App-private storage; **SQLCipher-ready** DB encryption with Keystore-backed key; append-only events enforced in code |
| Information disclosure | Extraction of DB from a lost/rooted device | DB encryption at rest; keys in Android Keystore via secure storage; no secrets in code |
| Repudiation | History altered to hide consumption | Immutable, append-only `inventory_events`; no update/delete paths; integrity reviewed |
| Elevation | SQL injection via user/remote strings | Drift parameterized queries only; never string-concatenated SQL |

### DF5 — Backup files (leaves the sandbox)
| STRIDE | Threat | Mitigation |
|--------|--------|------------|
| Information disclosure | Backup readable by others / cloud sync | **Always encrypted** (AES-GCM) with key derived from user passphrase (Argon2id/scrypt); no plaintext export |
| Tampering | Malicious/modified backup on restore | Authenticated encryption (GCM tag) verified before use; strict schema + validators on every field; `format_version` check |
| DoS/Elevation | Crafted backup causes crash/exhaustion | Size limits, streaming parse, defensive validation, reject unknown/oversized structures |

### DF1 — User ↔ UI (shared, physical device)
| STRIDE | Threat | Mitigation |
|--------|--------|------------|
| Spoofing/Repudiation | No accounts → any user acts as "the household" | Accepted by design (single-household trust). No per-user attribution claimed. Documented. |
| Information disclosure | Shoulder-surfing on a kitchen tablet | Low-sensitivity foreground data; optional app-lock (biometric/PIN) considered as future enhancement, not v1 core |
| Tampering | Barcode payload is attacker-controlled (sticker) | **Never trust barcode data**: validate format+check digit; treat scanned value purely as a lookup key; sanitize any derived metadata |

### DF6 — Notifications
| STRIDE | Threat | Mitigation |
|--------|--------|------------|
| Information disclosure | Lock-screen notification reveals contents | Keep notification text generic (e.g. "3 items expiring soon"); avoid sensitive detail on lock screen |

## 6. OWASP Mobile Top 10 (2024) mapping

| Risk | Applicability | Mitigation summary |
|------|---------------|--------------------|
| M1 Improper Credential Usage | Low (no accounts) | No credentials stored; no auth tokens |
| M2 Inadequate Supply Chain Security | Medium | Minimal, pinned deps; CI dependency + secret scanning; review new deps |
| M3 Insecure Authentication/Authorization | N/A (by design) | No auth; single-household trust documented |
| M4 Insufficient Input/Output Validation | **High** | Central validators; self-validating value objects; sanitize OFF + backup + barcode; parameterized SQL |
| M5 Insecure Communication | Medium | HTTPS only, cleartext disabled, TLS trust store, pinning trade-off documented |
| M6 Inadequate Privacy Controls | **High (differentiator)** | No analytics/telemetry; single documented egress; local-only data; encrypted backups |
| M7 Insufficient Binary Protection | Low | R8/ProGuard shrink+obfuscate release; no secrets in binary; not a primary control |
| M8 Security Misconfiguration | Medium | Minimal permissions; network security config (no cleartext); secure defaults |
| M9 Insecure Data Storage | **High** | App-private + SQLCipher-ready encryption; Keystore-backed keys; encrypted backups; no PII in logs |
| M10 Insufficient Cryptography | Medium | Vetted primitives (AES-GCM, Argon2id/scrypt); platform crypto/Keystore; no home-grown crypto |

## 7. Prioritized risk register

| ID | Risk | Likelihood | Impact | Priority | Primary mitigation |
|----|------|-----------|--------|----------|--------------------|
| R1 | Malicious/malformed OFF data corrupts app or DB | Med | Med | High | Strict validation/sanitization, defensive parsing (M4) |
| R2 | Data exposure from lost/rooted device | Low | High | High | DB encryption at rest + Keystore keys (M9) |
| R3 | Plaintext/leaky backups | Med | High | High | Mandatory authenticated encryption of backups |
| R4 | Supply-chain (dependency adds telemetry/backdoor) | Low | High | High | Minimal deps, audit + secret scan in CI, review gate |
| R5 | MITM injects product data | Low | Med | Med | HTTPS-only + validation; pinning trade-off |
| R6 | Device clock manipulation skews expiration | Low | Low | Low | Documented; expiration is advisory, not security-critical |
| R7 | Barcode sticker spoofing | Med | Low | Low | Barcode used only as lookup key; user confirms product |
| R8 | Accidental data loss on shared device | Med | Med | Med | Soft-delete, confirmations, encrypted backups, restore |

## 8. Security requirements derived (feed into Security Design)

- SR-1 Disable cleartext traffic; HTTPS-only client with sane timeouts.
- SR-2 Validate & sanitize *every* external input (OFF, barcode, backup) via a
  shared validation module; construct domain value objects that cannot be invalid.
- SR-3 Parameterized DB access only (Drift); no dynamic SQL string building.
- SR-4 Encrypt data at rest (SQLCipher-ready) with Keystore-backed keys via
  flutter_secure_storage; no secrets in source.
- SR-5 Encrypt all backups with authenticated encryption + KDF from user passphrase.
- SR-6 Enforce least-privilege permissions (CAMERA; POST_NOTIFICATIONS on 13+).
- SR-7 No analytics/telemetry/tracking libraries; single documented network egress.
- SR-8 Immutable, append-only history enforced structurally and in code.
- SR-9 CI: secret scanning, dependency audit, and a "no new egress/permission"
  review gate.
- SR-10 Release builds: shrink + obfuscate; strip verbose logs; no PII in logs.

## 9. Residual risks (accepted for v1)

- No per-user authentication on the shared tablet (intended single-household trust).
- Optional app-lock (biometric/PIN) and TLS pinning are **considered but deferred**;
  rationale and re-evaluation triggers in [Security Design](09-security-design.md).
- Physical attacker with an *unlocked, unencrypted* device can read foreground data
  — mitigated by enabling DB encryption and OS device lock.
