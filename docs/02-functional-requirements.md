# 02 — Functional Requirements

Requirements use identifiers `FR-<area>-<n>`. Priority uses MoSCoW
(**M**ust / **S**hould / **C**ould / **W**on't-this-release). Each requirement is
written to be testable; acceptance criteria are consolidated in the
[SRS](04-srs.md).

Areas: `INV` inventory, `LOC` locations, `BAR` barcode, `EXP` expiration,
`REC` recipes, `SHOP` shopping list, `HIST` history, `STAT` statistics,
`SET` settings/backup, `NOT` notifications.

---

## 1. Inventory (INV)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-INV-1 | M | The user can add a product to inventory, specifying quantity, unit, storage location and (optional) expiration date. |
| FR-INV-2 | M | The user can remove a product / inventory item entirely. |
| FR-INV-3 | M | The user can increase or decrease the quantity of an inventory item in single-tap steps (+1 / −1) and by explicit entry. |
| FR-INV-4 | M | When quantity reaches zero, the item is removed from active stock but its history is retained. |
| FR-INV-5 | M | The user can search inventory by product name and barcode. |
| FR-INV-6 | M | The user can filter inventory by category and by storage location. |
| FR-INV-7 | M | Each product can be assigned exactly one category; categories are from a predefined, extensible set. |
| FR-INV-8 | M | Each inventory item is associated with exactly one storage location. |
| FR-INV-9 | S | The user can move an inventory item to a different storage location. |
| FR-INV-10 | S | The same product can exist in multiple locations as separate inventory items (e.g. milk in fridge and pantry). |
| FR-INV-11 | S | The user can set a per-product low-stock threshold used by the shopping list. |
| FR-INV-12 | C | The user can attach a free-text note to an inventory item. |
| FR-INV-13 | M | Quantities support fractional values with a unit (e.g. 0.5 kg, 2 pcs); units come from a controlled list. |

## 2. Storage locations (LOC)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-LOC-1 | M | The system provides three built-in location types: Refrigerator, Freezer, Pantry. |
| FR-LOC-2 | S | The user can create additional named locations of a given type (e.g. "Garage freezer"). |
| FR-LOC-3 | M | The user can view all inventory grouped by location. |
| FR-LOC-4 | C | A location can define a default expiration extension (e.g. freezer extends shelf life) used as a hint when adding items. |

## 3. Barcode (BAR)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-BAR-1 | M | The user can scan an EAN-8, EAN-13 or UPC-A barcode using the device camera. |
| FR-BAR-2 | M | On scan, the system first looks up the barcode in the local product database. |
| FR-BAR-3 | M | If found locally, cached product data is used with no network call. |
| FR-BAR-4 | M | If not found locally and the network is available and enrichment is enabled, the system queries OpenFoodFacts over HTTPS. |
| FR-BAR-5 | M | A successful OpenFoodFacts result is validated, sanitized and saved locally as a cached product. |
| FR-BAR-6 | M | The system must not query the same barcode remotely more than once unless the previous result was "not found" and a user-initiated retry occurs, or the cache TTL for negative results has expired. |
| FR-BAR-7 | M | If the product is still unknown, the user can create the product manually. |
| FR-BAR-8 | M | Barcode scanning and all fallbacks function offline (local lookup + manual creation). |
| FR-BAR-9 | S | After a successful scan the user is taken directly to the add/adjust-quantity step for that product. |
| FR-BAR-10 | S | The system records the barcode format and source (local / OpenFoodFacts / manual) of each product. |
| FR-BAR-11 | C | The user can re-run enrichment for a manually created product later. |

## 4. Expiration (EXP)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-EXP-1 | M | An inventory item may have an expiration date. |
| FR-EXP-2 | M | The system provides an "Expiring soon" view listing items expiring within a configurable window (default 3 days). |
| FR-EXP-3 | M | The system provides an "Expired" view listing items past their expiration date. |
| FR-EXP-4 | M | The system computes, per item, days-until-expiry and an expiration status (fresh / expiring-soon / expired). |
| FR-EXP-5 | S | The user can mark an expired item as discarded, creating a waste event. |
| FR-EXP-6 | S | The user can mark an expired item as consumed anyway, creating a consumption event. |

## 5. Notifications (NOT)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-NOT-1 | M | The system schedules a local notification when items are entering the "expiring soon" window. |
| FR-NOT-2 | M | Notifications are generated and delivered entirely on-device with no server. |
| FR-NOT-3 | S | Notifications are batched (e.g. one daily digest at a user-configured time) to avoid noise. |
| FR-NOT-4 | S | The user can enable/disable expiration notifications and set the digest time. |
| FR-NOT-5 | C | The user can receive a low-stock notification in the daily digest. |

## 6. Recipes (REC)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-REC-1 | M | The system suggests recipes that can be prepared from currently available ingredients. |
| FR-REC-2 | M | Each suggested recipe shows available vs. missing ingredients. |
| FR-REC-3 | M | Recipe ranking considers: proportion of available ingredients, number of missing ingredients, expiration priority of used ingredients, preparation time, and user preferences. |
| FR-REC-4 | S | The user can view a recipe's full ingredient list and steps. |
| FR-REC-5 | S | The user can add a recipe's missing ingredients to the shopping list in one action. |
| FR-REC-6 | S | The user can mark a recipe as cooked, which optionally decrements the used ingredients from inventory. |
| FR-REC-7 | S | The user can set preferences (e.g. preferred max prep time, favourite/blocked tags, dietary tags). |
| FR-REC-8 | C | The user can add and edit their own recipes locally. |
| FR-REC-9 | M | Recipes and their ingredient mappings are stored locally and work offline. |

## 7. Shopping list (SHOP)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-SHOP-1 | M | The user can add manual items to the shopping list. |
| FR-SHOP-2 | M | The system automatically proposes items whose stock is below their low-stock threshold or is zero. |
| FR-SHOP-3 | M | The user can check off / remove shopping list items. |
| FR-SHOP-4 | S | Checking off an item can optionally add it back to inventory. |
| FR-SHOP-5 | S | Auto-generated items are visually distinguished from manual ones and can be dismissed without re-proposal for a cooldown period. |
| FR-SHOP-6 | C | The shopping list can be shared/exported as plain text. |

## 8. History (HIST)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-HIST-1 | M | Every inventory-changing action creates an **immutable** event record. |
| FR-HIST-2 | M | Supported event types include at least: `ADD_PRODUCT`, `REMOVE_PRODUCT`, `UPDATE_QUANTITY`, `CHANGE_LOCATION`, `CONSUME`, `DISCARD`. |
| FR-HIST-3 | M | Events are never edited or deleted by normal application flows. |
| FR-HIST-4 | M | Each event records: type, timestamp, affected product/item, quantity delta, before/after values where applicable, and location context. |
| FR-HIST-5 | S | The user can browse a chronological history, filterable by product and event type. |
| FR-HIST-6 | S | The user can understand consumption over time for a given product from its history. |

## 9. Statistics (STAT)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-STAT-1 | M | The system shows most-consumed products over a selectable period. |
| FR-STAT-2 | M | The system shows food waste (discarded items/quantity) over a selectable period. |
| FR-STAT-3 | S | The system shows consumption trends over time. |
| FR-STAT-4 | S | Statistics are derived solely from the local immutable event log. |
| FR-STAT-5 | C | The system highlights products frequently discarded to help reduce waste. |

## 10. Settings, data & backup (SET)

| ID | Priority | Requirement |
|----|----------|-------------|
| FR-SET-1 | M | The app works with no account and no sign-in. |
| FR-SET-2 | M | The user can enable/disable OpenFoodFacts enrichment (default: enabled, but fully functional if disabled). |
| FR-SET-3 | M | The user can create an **encrypted** local backup of all data. |
| FR-SET-4 | M | The user can restore from an encrypted backup. |
| FR-SET-5 | S | The user can configure the expiring-soon window and notification digest time. |
| FR-SET-6 | S | The user can export their data in a documented, open format (encrypted). |
| FR-SET-7 | M | The user can wipe all local data ("factory reset") with explicit confirmation. |
| FR-SET-8 | C | The user can choose light/dark/system theme. |

---

## Traceability

Each functional requirement is mapped to acceptance criteria and test cases in the
[SRS](04-srs.md), and to domain concepts in the
[Domain Model](05-domain-model.md). Security-relevant requirements
(FR-BAR-4/5/6, FR-SET-3/4/6/7) are cross-referenced in the
[Threat Model](08-threat-model.md) and [Security Design](09-security-design.md).
