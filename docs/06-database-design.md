# 06 — Database Design

Local persistence uses **Drift** over **SQLite**. The schema is normalized,
migration-driven, uses immutable UUID keys, and includes the columns required to
support a **future synchronization** layer without a breaking migration.

## 1. Principles

- **Normalization (3NF).** Products (catalog) are separated from inventory (stock).
  Recipes and ingredients are separate tables joined by a mapping table.
- **Immutable IDs.** All primary keys are `TEXT` UUID v4, generated in code, never
  reused, stable across the entity's life.
- **Append-only events.** `inventory_events` is never updated or deleted by
  application code (enforced in the repository layer and by review).
- **Soft delete + audit columns.** `created_at`, `updated_at`, `deleted_at` on
  mutable entities to enable sync (tombstones) and safe restore.
- **Sync-readiness.** Every syncable row carries `updated_at` (logical clock-ready),
  `deleted_at` (tombstone) and a `dirty`/`sync_version` marker reserved for a future
  sync engine. No server exists in v1; these columns are inert but present.
- **Referential integrity.** Foreign keys enabled (`PRAGMA foreign_keys = ON`);
  appropriate `ON DELETE` behavior (mostly `RESTRICT`/soft-delete, never cascade on
  events).
- **Determinism.** Timestamps stored as UTC epoch milliseconds (`INTEGER`);
  expiration stored as `DATE` (ISO `YYYY-MM-DD`) to avoid timezone drift.

## 2. Entity–relationship overview

```
locations 1───∞ inventory_items ∞───1 products
                     │                    │
                     │                    └──∞ (barcode index, unique when present)
                     │
inventory_events ∞───┘ (references product_id / inventory_item_id, append-only)

recipes 1───∞ recipe_ingredients ∞───0..1 products (optional link by product_id)
                                    else free-text ingredient name

shopping_list_items ∞───0..1 products
notification_schedules (standalone)
user_preferences (single row)
app_meta (schema version, flags)
```

## 3. Tables (logical schema)

Types are SQLite affinities. `PK` = primary key, `FK` = foreign key, `UQ` = unique,
`IX` = indexed.

### 3.1 `products` (catalog)
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v4 |
| barcode | TEXT UQ (nullable) | normalized EAN/UPC; unique when not null |
| name | TEXT NOT NULL | length-capped, sanitized |
| brand | TEXT | nullable |
| category | TEXT NOT NULL | value from controlled set |
| default_unit | TEXT NOT NULL | controlled unit |
| source | TEXT NOT NULL | local / openFoodFacts / manual |
| image_url | TEXT | metadata only; not auto-fetched in v1 |
| created_at | INTEGER NOT NULL | epoch ms UTC |
| updated_at | INTEGER NOT NULL | epoch ms UTC |
| deleted_at | INTEGER | tombstone |
| sync_version | INTEGER NOT NULL DEFAULT 0 | reserved for sync |

Indexes: `IX products(category)`, `UQ products(barcode)` (partial: where barcode not null).

### 3.2 `locations`
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | e.g. "Kitchen fridge" |
| type | TEXT NOT NULL | refrigerator / freezer / pantry |
| shelf_life_bonus_days | INTEGER | optional hint |
| created_at / updated_at / deleted_at | INTEGER | audit/tombstone |
| sync_version | INTEGER DEFAULT 0 | reserved |

Seeded with three default locations on first run.

### 3.3 `inventory_items` (stock)
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| product_id | TEXT FK→products.id NOT NULL | RESTRICT |
| location_id | TEXT FK→locations.id NOT NULL | RESTRICT |
| quantity_amount | REAL NOT NULL | ≥ 0 (CHECK) |
| quantity_unit | TEXT NOT NULL | controlled unit |
| expiration_date | TEXT | ISO date, nullable |
| low_stock_threshold | REAL | nullable |
| note | TEXT | nullable, sanitized |
| created_at / updated_at | INTEGER NOT NULL | |
| deleted_at | INTEGER | soft delete when depleted/removed |
| sync_version | INTEGER DEFAULT 0 | |

Constraints: `CHECK(quantity_amount >= 0)`.
Indexes: `IX(location_id)`, `IX(product_id)`, `IX(expiration_date)`,
`IX(deleted_at)` (for active-stock queries).

### 3.4 `inventory_events` (immutable log)
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| type | TEXT NOT NULL | EventType |
| occurred_at | INTEGER NOT NULL | epoch ms UTC |
| product_id | TEXT FK→products.id | nullable, RESTRICT |
| inventory_item_id | TEXT | id snapshot (not FK: item may be soft-deleted) |
| location_id | TEXT | context |
| from_location_id | TEXT | for CHANGE_LOCATION |
| to_location_id | TEXT | for CHANGE_LOCATION |
| quantity_delta | REAL | signed |
| quantity_before | REAL | |
| quantity_after | REAL | |
| reason | TEXT | e.g. WASTE |
| metadata_json | TEXT | small, validated JSON (e.g. source of change) |

No `updated_at`/`deleted_at`: this table is append-only by contract.
Indexes: `IX(occurred_at)`, `IX(product_id, occurred_at)`, `IX(type)`.

### 3.5 `recipes`
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| title | TEXT NOT NULL | |
| prep_time_minutes | INTEGER NOT NULL | ≥ 0 |
| steps_json | TEXT NOT NULL | ordered list of step strings (validated) |
| tags_json | TEXT NOT NULL DEFAULT '[]' | dietary/other tags |
| source | TEXT NOT NULL | builtin / user |
| created_at / updated_at / deleted_at | INTEGER | |
| sync_version | INTEGER DEFAULT 0 | |

### 3.6 `recipe_ingredients`
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| recipe_id | TEXT FK→recipes.id NOT NULL | ON DELETE CASCADE (child of recipe) |
| product_id | TEXT FK→products.id | nullable link |
| ingredient_name | TEXT NOT NULL | fallback/label |
| quantity_amount | REAL | nullable (e.g. "to taste") |
| quantity_unit | TEXT | nullable |
| optional | INTEGER NOT NULL DEFAULT 0 | boolean |

Index: `IX(recipe_id)`, `IX(product_id)`.

### 3.7 `shopping_list_items`
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | |
| product_id | TEXT FK→products.id | nullable |
| quantity_amount | REAL | nullable |
| quantity_unit | TEXT | nullable |
| origin | TEXT NOT NULL | MANUAL / AUTO |
| status | TEXT NOT NULL | PENDING / DONE / DISMISSED |
| dismissed_until | INTEGER | cooldown for AUTO re-proposal |
| created_at / updated_at / deleted_at | INTEGER | |
| sync_version | INTEGER DEFAULT 0 | |

Index: `IX(status)`, `IX(product_id)`.

### 3.8 `notification_schedules`
| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| kind | TEXT NOT NULL | EXPIRY_DIGEST / LOW_STOCK |
| scheduled_for | INTEGER NOT NULL | epoch ms |
| payload_json | TEXT | small, validated |
| created_at | INTEGER NOT NULL | |

### 3.9 `barcode_lookups` (negative/positive cache control)
Supports FR-BAR-6 ("never repeatedly query the same barcode").
| Column | Type | Notes |
|--------|------|-------|
| barcode | TEXT PK | normalized |
| result | TEXT NOT NULL | FOUND / NOT_FOUND |
| product_id | TEXT FK→products.id | set when FOUND |
| fetched_at | INTEGER NOT NULL | epoch ms |
| ttl_until | INTEGER | for NOT_FOUND expiry-based retry |

### 3.10 `user_preferences` (single row)
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK CHECK(id=1) | singleton |
| max_prep_time_minutes | INTEGER | nullable |
| favorite_tags_json / blocked_tags_json | TEXT | |
| expiring_soon_window_days | INTEGER NOT NULL DEFAULT 3 | |
| digest_time | TEXT NOT NULL DEFAULT '09:00' | HH:mm |
| enrichment_enabled | INTEGER NOT NULL DEFAULT 1 | |
| theme | TEXT NOT NULL DEFAULT 'system' | |

### 3.11 `app_meta`
| Column | Type | Notes |
|--------|------|-------|
| key | TEXT PK | e.g. `schema_version`, `db_encrypted` |
| value | TEXT NOT NULL | |

## 4. Referential-integrity & deletion policy

- Foreign keys **ON** at connection open.
- `inventory_items` → products/locations: `RESTRICT` (never orphan stock; use soft
  delete on the item instead).
- `recipe_ingredients` → recipes: `CASCADE` (ingredients are children of a recipe).
- `inventory_events`: no cascading deletes ever; `product_id` is `RESTRICT`. The
  `inventory_item_id` is stored as a plain snapshot (not FK) so history survives
  item soft-deletion.
- User-facing "delete" = soft delete (`deleted_at`) everywhere except events.

## 5. Migrations

- Managed by Drift's `MigrationStrategy` with an explicit integer `schemaVersion`.
- **Every** schema change ships a migration step and a migration test that seeds the
  previous version and asserts data survives (NFR-REL-5).
- Drift schema is exported per version (`drift_dev` schema dump) to
  `flutter_app/drift_schemas/` so migrations are diffable and testable across
  versions.
- `onCreate` seeds: default locations, built-in recipes, preferences singleton,
  `app_meta.schema_version`.
- Backward-only concerns: no destructive column drops without a data-preserving copy
  step.

## 6. Encryption at rest (SQLCipher-ready)

- The schema and DAO layer are written to be **cipher-agnostic**. v1 ships with the
  option to enable **SQLCipher** (via `sqlcipher_flutter_libs`) so the entire DB
  file is encrypted with a key held in `flutter_secure_storage` (Android Keystore).
- Whether encryption is on by default vs. opt-in is finalized in
  [Security Design](09-security-design.md); the DB open path reads the key from
  secure storage and passes `PRAGMA key`. `app_meta.db_encrypted` records state.
- Backups are always encrypted regardless of DB encryption (see §7).

## 7. Backup & restore format

- Logical export (not a raw DB copy) to a versioned, documented JSON structure,
  then compressed and **encrypted** with authenticated encryption (AES-GCM) using a
  key derived from a user passphrase (Argon2id/scrypt KDF) — details in Security
  Design.
- Envelope: `{ format_version, created_at, kdf_params, nonce, ciphertext, tag }`.
- Restore validates `format_version`, verifies the auth tag before decrypting logic,
  then runs the same validators used for live input before inserting.
- Round-trip export→import is covered by integration tests (UC-9).

## 8. Query patterns & performance

| Screen/feature | Primary query | Supporting index |
|----------------|---------------|------------------|
| Home dashboard counts | aggregate active items, expiring, low-stock | `IX(deleted_at)`, `IX(expiration_date)` |
| Inventory list/search | active items filtered by location/category, name LIKE | `IX(location_id)`, `IX(product_id)`, FTS optional (see below) |
| Expiring soon | active items where expiration within window | `IX(expiration_date)` |
| History | events by product/type ordered by time | `IX(product_id, occurred_at)`, `IX(type)` |
| Statistics | aggregate events over period | `IX(occurred_at)` |
| Barcode scan | lookup product by barcode + cache | `UQ(barcode)`, `barcode_lookups.PK` |

- **Search:** start with indexed `LIKE`/normalized-name column; if the 5,000-item
  search budget (NFR-PERF-5) is threatened, add SQLite **FTS5** virtual table over
  product name/brand as a follow-up (kept out of v1 unless needed — avoid
  unnecessary complexity).
- All list queries are exposed as Drift **streams** so the UI updates reactively
  after writes (supports "instant" perceived updates, NFR-PERF-2).

## 9. Transactions & the event invariant

Every inventory mutation executes in a single Drift transaction that (a) updates the
`inventory_items` row and (b) inserts the corresponding `inventory_events` row. If
either fails, both roll back — guaranteeing the immutable log and state never
diverge (Domain invariant 3, FR-HIST-1).

## 10. Sync forward-compatibility (design only, not built in v1)

- UUID PKs → globally unique, no id collisions on merge.
- `updated_at` + `sync_version` → last-writer-wins or vector-clock upgrade path.
- `deleted_at` tombstones → deletions propagate without losing history.
- Append-only `inventory_events` → naturally CRDT-friendly (events merge by union).
- A future `sync_state` table can be added via migration without touching existing
  data.
