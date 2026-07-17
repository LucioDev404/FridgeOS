# 10 — UI Guidelines

Design language for FridgeOS: **Material 3, tablet-first, calm and glanceable.**
Inspired by (not copied from) Apple Home/Reminders, Google Home and Home Assistant:
card-based dashboards, generous spacing, status-at-a-glance, quick actions. The
result should feel original, minimal and confident.

## 1. Design principles

1. **Glanceable first.** The home dashboard answers the four core questions without
   scrolling. Numbers and status colors do the talking.
2. **Two-tap common actions.** Adjusting a known item is reachable from the home
   surface and from scan in ≤ 3 taps (NFR-UX-1).
3. **Calm, not gamified.** No streaks, badges, or dark patterns. Notifications are
   informative, batched, dismissible.
4. **Forgiving.** Destructive actions confirm; deletions are soft; undo where cheap.
5. **Legible from a distance.** Kitchen tablet may be viewed from ~1 m; large type,
   high contrast, big touch targets.

## 2. Layout & responsiveness

- **Breakpoints** (Material 3 window size classes):
  - Compact (< 600 dp): single column, bottom nav (phone best-effort).
  - Medium (600–839 dp): navigation **rail** + content.
  - Expanded (≥ 840 dp, primary target): navigation rail + **two-pane**
    (list/detail) where useful (e.g. Inventory list + item detail; Recipes list +
    recipe).
- **Navigation rail** is the primary tablet navigation: Home, Scan, Inventory,
  Expiring, Recipes, Shopping, History/Stats, Settings.
- **Adaptive grids** for cards (`GridView`/`Wrap` with min tile width ~280 dp) so
  the dashboard reflows across sizes and both orientations.
- Support landscape and portrait with no overflow (golden tests, NFR-UX-6).

## 3. Core screens

| Screen | Purpose | Key elements |
|--------|---------|--------------|
| **Home / Dashboard** | Glance + entry to actions | Summary cards: *In stock*, *Expiring soon* (count + top items), *Shopping list* (count), *Recipes you can cook*; big **Scan** FAB/button |
| **Scan** | Full-screen camera | Live camera, reticle/guide, instant result sheet → quantity adjuster; manual-entry fallback button |
| **Quantity adjuster** (sheet) | The 2-tap action | Product name/image, big − / +, unit, location, expiry (optional), Confirm |
| **Inventory** | Browse/search stock | Search field, filter chips (location, category), item cards; two-pane detail on expanded |
| **Expiring** | Triage | Segments: *Expiring soon* / *Expired*; per item quick actions (consume / discard / move) |
| **Recipes** | Suggestions | Ranked list with availability meter + missing count; detail with steps, "add missing to list", "cooked" |
| **Shopping list** | Buy | Manual add field; auto items visually distinct; check-off; optional restock |
| **History** | Understand consumption | Chronological events, filter by product/type |
| **Statistics** | Insight | Most consumed, waste, trends (simple charts) over selectable period |
| **Settings** | Control | Enrichment toggle, expiring window, digest time, theme, backup/restore, factory reset, licenses/privacy |

## 4. Component patterns

- **Item card:** product name (prominent), quantity + unit, location chip, expiry
  badge (color-coded), quick − / + and overflow. Consistent across screens.
- **Status badge / color coding:**
  - Fresh: neutral/secondary.
  - Expiring soon: warning (amber/tertiary container).
  - Expired: error color.
  - Colors always paired with text/icon (never color-only — a11y).
- **Empty states:** friendly, instructive ("Nothing in the fridge yet — scan a
  barcode to start"), with the primary action.
- **Error/offline states:** calm inline messages ("Offline — product not enriched,
  you can add it manually"), never blocking dialogs for network issues.
- **Loading:** skeletons/placeholders for lists; never a full-screen spinner for
  local reads (they're fast).

## 5. Interaction & motion

- Prefer **optimistic UI** for local writes (instant reflect via Drift streams);
  reconcile on commit.
- Motion is subtle and purposeful (Material 3 standard easing/durations); respect
  "reduce motion" system setting.
- Primary action always thumb/finger-reachable; − / + targets ≥ 48 dp with spacing
  to avoid mis-taps.

## 6. Theming & tokens

- **Material 3 dynamic color** where available; a defined brand seed color as
  fallback. Light, dark, and system themes (FR-SET-8).
- Centralized design tokens: spacing scale (4/8/12/16/24/32), corner radii, elevation,
  typography scale (Material 3 type roles). No ad-hoc magic numbers in widgets.
- Typography: large, legible; body ≥ 16 sp; dashboard numbers use display/headline
  roles.

## 7. Accessibility (NFR-UX-2..5)

- Touch targets ≥ 48×48 dp.
- Contrast ≥ WCAG AA (4.5:1 body).
- All interactive widgets have semantic labels; icons have tooltips/labels.
- Support text scaling to ≥ 130% without breakage.
- Never convey meaning by color alone (pair with icon/text).
- Full keyboard/switch navigation viable (focus order, focus rings).

## 8. Content & tone

- Plain, warm, concise microcopy. Avoid jargon.
- Numbers first on the dashboard; words support them.
- Confirmation copy states consequences ("This permanently erases all local data").

## 9. Internationalization

- All user-facing strings via ARB (`l10n/`); no hard-coded text.
- Layouts tolerate longer translations (avoid fixed-width text containers).
- Locale-aware dates/numbers; expiration shown relative ("in 2 days") and absolute.

## 10. Design QA / definition of done (UI)

- Golden tests at representative tablet sizes (portrait + landscape).
- Semantics test asserting labels on actionable widgets.
- Text-scale test at 130%.
- Manual pass on a real/emulated 10" tablet for the north-star flow (UC-1).

## 11. North-star flow storyboard

```
[Home dashboard]  ──tap Scan──▶  [Scan]  ──decode──▶  [Result/quantity sheet]
   ▲ glance: counts & status                              │  −/+  · location · expiry
   └──────────────── Confirm ◀───────────────────────────┘
                         │
                         ▼
         inventory updated · event logged · (shopping list auto-updates)
```
Target: ≤ 3 interactions, ≤ 5 seconds, works offline.
