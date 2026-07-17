# 05 — Domain Model

The domain layer is pure Dart (no Flutter, no Drift, no I/O). It expresses the
ubiquitous language, invariants and business rules. Data and presentation depend on
it; it depends on nothing.

## 1. Bounded context

FridgeOS is a single bounded context: **Household Food Inventory**. Within it we
model a small set of aggregates. The catalog concept (`Product`) is separated from
the stock concept (`InventoryItem`) because a product's identity/metadata is stable
and reusable, while stock is mutable and location-scoped.

## 2. Aggregates & entities

```
Product (aggregate root)            InventoryItem (aggregate root)
  id                                  id
  barcode?                            productId ──────────┐ ref Product
  name                                locationId ─────────┼ ref Location
  brand?                              quantity (Quantity) │
  category (Category)                 expirationDate?     │
  defaultUnit (Unit)                  lowStockThreshold?  │
  source (ProductSource)             note?
  imageUrl?                           createdAt/updatedAt
  createdAt/updatedAt                 deletedAt?
  deletedAt?

Location (aggregate root)          InventoryEvent (immutable)
  id                                  id
  name                                type (EventType)
  type (LocationType)                 occurredAt
  shelfLifeBonusDays?                 productId?
                                      inventoryItemId?
Recipe (aggregate root)              locationId? / fromLocationId? / toLocationId?
  id                                  quantityDelta?
  title                               quantityBefore? / quantityAfter?
  prepTimeMinutes                     reason? (e.g. WASTE)
  steps[]                             metadata (small, structured)
  tags[] (dietary/other)
  ingredients[] (RecipeIngredient)  ShoppingListItem (aggregate root)
                                      id
RecipeIngredient (value/child)       name
  productRef? (by name or productId) productId?
  quantity (Quantity)                quantity (Quantity)?
  optional (bool)                     origin (MANUAL | AUTO)
                                      status (PENDING | DONE | DISMISSED)
UserPreferences (singleton)          createdAt/updatedAt
  maxPrepTimeMinutes?
  favoriteTags[] / blockedTags[]    NotificationSchedule (aggregate root)
  expiringSoonWindowDays (default 3)  id
  digestTime                          kind (EXPIRY_DIGEST | LOW_STOCK)
  enrichmentEnabled                   scheduledFor
  theme                               payloadRef
```

## 3. Value objects

| Value object | Definition & invariants |
|--------------|-------------------------|
| `Barcode` | Normalized digit string; valid EAN-8/EAN-13/UPC-A incl. check digit; immutable. Invalid input is rejected at construction. |
| `Quantity` | `amount: double >= 0` + `Unit`; arithmetic returns new instances; forbids negative results. |
| `Unit` | Controlled enum-like set: `pcs, g, kg, ml, l, pack`. Conversions only within compatible dimensions. |
| `Category` | Controlled set (e.g. Dairy, Produce, Meat, Bakery, Beverages, Frozen, Pantry-staple, Other), extensible via config. |
| `LocationType` | `refrigerator, freezer, pantry`. |
| `ProductSource` | `local, openFoodFacts, manual`. |
| `EventType` | `ADD_PRODUCT, REMOVE_PRODUCT, UPDATE_QUANTITY, CHANGE_LOCATION, CONSUME, DISCARD`. |
| `ExpirationStatus` | Derived: `fresh, expiringSoon, expired` from expiry date + window. |
| `DateOnly` | Calendar date without time, for expiration (avoids TZ ambiguity). |

Value objects are **self-validating**: they cannot be constructed in an invalid
state. This is the first line of input validation (see Security Design).

## 4. Core invariants (business rules)

1. **Quantity is non-negative.** No operation may drive quantity below 0. Reaching
   0 removes the item from *active* stock (soft delete) but not from history.
2. **One product per inventory item; one location per inventory item.** The same
   product in two locations is two `InventoryItem`s (FR-INV-10).
3. **Events are immutable and append-only.** Every mutating operation on inventory
   produces exactly one `InventoryEvent` within the same transaction as the state
   change (atomicity: state and its event succeed or fail together).
4. **Barcode is optional but, if present, valid.** A `Product` may lack a barcode
   (manual), but a stored barcode must pass check-digit validation.
5. **Enrichment is idempotent & non-repeating.** A barcode that has been resolved
   (positively or negatively within TTL) is not re-queried remotely (FR-BAR-6).
6. **Expiration is a date, evaluated against the device date.** Status is a pure
   function `status(expiry, today, windowDays)`.
7. **Auto shopping items derive from stock ≤ threshold**; they never duplicate an
   existing pending item for the same product and respect a dismissal cooldown.
8. **Recipe availability** is computed against current stock; a recipe is
   "cookable" iff all non-optional ingredients are available in sufficient quantity.

## 5. Key domain services (pure logic)

| Service | Responsibility | Signature (conceptual) |
|---------|----------------|------------------------|
| `ExpirationPolicy` | Classify items; compute days-to-expiry | `classify(item, today, window) -> ExpirationStatus` |
| `InventoryMutationService` | Apply add/remove/adjust/move producing (newState, event) pairs enforcing invariants | `adjust(item, delta) -> (InventoryItem, InventoryEvent)` |
| `RecipeRanker` | Rank recipes | see §6 |
| `ShoppingListPolicy` | Decide auto-proposed items | `propose(stock, prefs) -> List<ShoppingListItem>` |
| `StatisticsCalculator` | Aggregate events into stats | `mostConsumed(events, period)`, `waste(events, period)`, `trend(events, period)` |
| `BarcodeValidator` | Validate/normalize barcodes | `parse(String) -> Barcode?` |

These services are the primary unit-test targets (deterministic, no I/O).

## 6. Recipe ranking model

For each candidate recipe `r` against current stock `S` and preferences `P`, compute
a score in [0, 1] (higher = better). All weights are configuration constants,
tunable and unit-tested.

```
availability = availableRequired(r, S) / totalRequired(r)      # 0..1
missingPenalty = missingRequired(r, S) / totalRequired(r)      # 0..1
expirationBoost = maxExpirationUrgency(ingredients used from S) # 0..1
                  # 1.0 if it consumes an item expiring today, →0 as expiry is far
prepScore = clamp( (P.maxPrepTime - r.prepTime) / P.maxPrepTime , 0, 1)  # 0..1
preferenceScore = tagAffinity(r.tags, P.favoriteTags, P.blockedTags)     # -1..1

score = w_a*availability
      - w_m*missingPenalty
      + w_e*expirationBoost
      + w_p*prepScore
      + w_pref*preferenceScore

# Hard filters applied first:
#  - drop recipes containing a blocked tag
#  - drop recipes exceeding P.maxPrepTime (if set) unless availability == 1
```

Default weights (v1): `w_a=0.45, w_m=0.20, w_e=0.20, w_p=0.10, w_pref=0.05`.
Ranking is a pure function of `(recipes, stock, preferences, today)` → fully
testable, deterministic, and adjustable without touching UI or data layers.

## 7. Statistics model

Derived exclusively from the immutable event log (single source of truth):

- **Most consumed:** sum of `|quantityDelta|` for `CONSUME`/`REMOVE_PRODUCT` events
  grouped by product over the period.
- **Food waste:** sum of quantities for `DISCARD` (reason `WASTE`) events, and
  waste ratio = discarded / (consumed + discarded).
- **Trends:** time-bucketed consumption (day/week/month) per product or overall.

Because stats are pure projections of events, they are reproducible and testable
against fixed event fixtures.

## 8. Lifecycle & state transitions

`InventoryItem` states: `active → (quantity 0) → inactive(soft-deleted)`.
Moving location keeps the same item id (records `CHANGE_LOCATION`).
`ShoppingListItem`: `PENDING → DONE` or `PENDING → DISMISSED` (dismiss starts a
cooldown for AUTO items).
`Product`: created (`manual`/`openFoodFacts`/`local`) → may be enriched later
(manual→enriched updates metadata, keeps id).

## 9. Mapping to persistence & UI

- The domain has **no knowledge of Drift or Flutter.** The data layer maps Drift
  rows ↔ domain entities; the presentation layer maps domain entities ↔ view
  models. See [Architecture](07-architecture.md) and
  [Database Design](06-database-design.md).
- IDs are `Uuid` (v4) strings generated in the domain/data boundary, immutable for
  the life of the entity (supports future sync and stable references).
