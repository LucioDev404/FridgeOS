# 01 — Product Vision

## Vision statement

FridgeOS turns the household kitchen tablet into a calm, trustworthy control panel
for food. It makes the state of the home's food inventory obvious at a glance,
removes friction from the daily "we used this / we bought this" gesture, and helps
the household waste less and shop smarter — **without ever asking for an account,
tracking the family, or requiring an internet connection.**

## Problem

Households lose money and food because they lack a shared, accurate, low-effort
view of what they own:

- Food expires unseen at the back of the fridge or freezer.
- The same product is bought twice because nobody remembers the stock.
- "What can we cook tonight with what we have?" is answered by opening every door.
- Existing apps demand accounts, push ads, and monetize personal consumption data.

## Product goal

An **offline-first Android tablet application** that lets any household member
quickly understand:

- **What** food is available and how much.
- **Where** it is stored (refrigerator, freezer, pantry).
- **What expires soon** and what has already expired.
- **What recipes** can be prepared with what is on hand.
- **What needs to be purchased.**

## Target users & context

| User | Context | Primary needs |
|------|---------|---------------|
| Household "kitchen manager" | Cooks, plans meals, does groceries | Fast add/remove, expiration alerts, shopping list |
| Family members / flatmates | Passing by the tablet | Glanceable stock, quick "took one" gesture |
| Occasional user (guest, kid) | Rare interaction | Zero learning curve, no login |

**Primary device:** a wall-mounted or counter-standing Android tablet in the
kitchen, shared by everyone, often used with one hand or slightly wet fingers,
frequently offline or on flaky Wi‑Fi.

## Design pillars

1. **Glanceable.** The home screen answers the four core questions without
   scrolling or tapping.
2. **Two-tap common actions.** Consuming or restocking a known item is 2–3
   interactions, scannable from across the counter.
3. **Trust by omission.** No account, no cloud requirement, no analytics, no ads.
   The absence of these is itself a feature.
4. **Resilient.** Works fully offline; the network only enriches, never blocks.
5. **Quiet.** Notifications are limited, relevant, and actionable (expiration,
   low stock) — never engagement bait.

## Scope

### In scope (v1)
- Inventory CRUD with quantities, categories, storage locations.
- Barcode (EAN/UPC) scanning with local cache + OpenFoodFacts enrichment.
- Expiration tracking, "expiring soon" view, local notifications.
- Recipe suggestions ranked by availability, expiration and preferences.
- Shopping list (manual + auto-generated).
- Immutable inventory event history.
- Consumption & waste statistics.
- Encrypted local backup/restore.

### Out of scope (v1)
- Multi-device real-time sync / cloud accounts (schema is *prepared* for it — see
  [Database Design](06-database-design.md) — but no server is built).
- Phone/other-form-factor optimization (tablet-first; phone is best-effort).
- Meal planning calendar, nutrition/diet tracking, price tracking.
- iOS / web builds.
- Voice assistants, smart-fridge hardware integration.

## Success metrics (privacy-preserving, measured only in dev/QA)

Because there is **no telemetry in production**, these are validated during
development and usability testing, not collected from users.

| Metric | Target |
|--------|--------|
| Time to record a consumption of a known item | ≤ 5 s, ≤ 3 taps |
| Cold start to interactive | < 2 s on mid-range tablet |
| Barcode recognition latency | < 1 s |
| Reported food-waste reduction (usability study) | Qualitative improvement |
| Crash-free sessions (dev/QA instrumentation only) | > 99.5% |

## Non-goals / explicit constraints

- The app must **never** require the internet to add, remove or view inventory.
- The app must **never** transmit personal or consumption data to any server.
- The only outbound network call is an **opt-in, HTTPS** product-metadata lookup
  to OpenFoodFacts, keyed solely by barcode.

## Guiding scenario (north-star flow)

> A family member finishes the milk. They walk to the tablet, tap the milk card
> (or scan the empty carton), tap "−1", and the carton is removed from stock, an
> immutable `REMOVE_PRODUCT` event is recorded, and milk is auto-added to the
> shopping list because it dropped below its threshold. Total time: ~4 seconds,
> no typing, no network.
