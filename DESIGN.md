# Design

<!-- impeccable:design-schema 1 -->

## World

**灰卡与规格表** — the 18% grey card and the printed specification sheet.

Photographers calibrate on a grey card and read gear off a spec table before they
ever touch it. That is the visual world: a disciplined neutral tonal ramp does
all structural work, and three chromatic signals carry meaning. Nothing is
decorated; everything is measured. Hairlines, aligned numerals, and image
space — the vocabulary of an MTF chart and a manufacturer's data page, not of a
card grid.

This is an **Operate** world rendered at four densities: the buyer's surface has
air, the merchant's has throughput, the admin's has queues. Same ramp, same
signals, different spacing scale.

## Palette

Total commitment to the ramp. The greys are cool-neutral so photographic colour
reads true against them — the same reason editing suites are grey.

Surfaces (zone 9–10):

| Token | Value | Use |
| --- | --- | --- |
| `--paper-0` | `#FFFFFF` | cards, plates, raised surfaces |
| `--paper-1` | `#F6F7F8` | page ground |
| `--paper-2` | `#EDEFF1` | recessed: table headers, wells, skeletons |
| `--paper-3` | `#E2E5E8` | pressed, disabled fill |

Ink ramp (zone 0–6), the structural voice:

| Token | Value | Use |
| --- | --- | --- |
| `--ink-0` | `#0D1114` | display headings, primary buttons |
| `--ink-1` | `#1B2126` | strong body, table values |
| `--ink-2` | `#4B545B` | body copy |
| `--ink-3` | `#767F86` | secondary, labels — 4.6:1 on `--paper-1` |
| `--ink-4` | `#A4ACB2` | placeholder, disabled text |

Hairlines: `--line-1: #E4E7EA` (dividers inside a surface) and
`--line-2: #CFD4D9` (surface edges).

Chromatic signals — exactly three, each with one meaning, never decorative:

| Token | Value | Meaning |
| --- | --- | --- |
| `--signal-amber` | `#B5751A` | price, deposit, rent, rating. Money and value. |
| `--signal-vermilion` | `#C2382B` | destructive, overdue, rejected, out of stock |
| `--signal-teal` | `#0E6E5F` | in stock, paid, approved, shipped |

Each signal has a `-wash` tint (8% over paper) for badges and a `-deep` for hover.
Amber is the only warm hue and never exceeds a third of a screen.

## Typography

Two faces, both self-hosted from `public/fonts/`:

- **Inter** (variable, latin) — everything. The display voice. Tightened to
  `-0.022em` on headings only.
- **JetBrains Mono** (variable, latin) — order numbers, SKUs, and spec values
  where digits must align. Never as a "technical" costume for prose.
- **CJK** falls through to `PingFang SC` / `HarmonyOS Sans SC` /
  `Microsoft YaHei UI`, which the platform supplies; no CJK webfont is shipped.

Scale: `12 / 13 / 14 / 16 / 20 / 26 / 34 / 46`, tracking floor `-0.04em`.
Display never exceeds `46px`; there is no hero-scale type in an Operate surface.
**Every numeral in a table, price, count, or spec is `tabular-nums`.** Weight
steps are `400 / 500 / 600 / 700`; hierarchy comes from size and weight, never
from colour.

## Form

- **Radii:** `2px` for inputs and small controls, `6px` for cards and plates,
  `999px` only for pills and avatars.
- **Elevation:** a surface declares **either** a hairline edge **or** a shadow,
  never both. The default is `1px solid var(--line-2)`. One shadow token exists,
  `--lift`, for overlays and sticky bars only. No coloured halos, no offset
  blocks.
- **Spacing:** an 4px base. Density scales multiply the same rhythm —
  buyer `1.35x`, merchant `1.0x`, admin `0.85x` — through `--dense` custom
  properties, so one component serves all three consoles.
- **Grid:** content caps at `1280px` with `24px` gutters; product grids use
  `repeat(auto-fill, minmax(...))` so a listing never wraps to an orphan column.

## Motion

One authored moment, not scattered effects: content enters with a
`translateY(6px)` + opacity fade on `cubic-bezier(0.16, 1, 0.3, 1)` at `280ms`,
staggered by `24ms` across a grid's first row only. Everything else is a
`140ms` state transition. The one exception is the homepage contact sheet, where
each frame's specification line resolves from blur to sharp — the subject
coming into focus.

Hover on a listing does **not** lift or add a shadow. It reveals the spec line
and de-saturates the ground, the way a contact sheet marks a selected frame.

## Signature

**The spec rail.** Every product carries its identity as an aligned,
tabular specification block — mount, sensor, focal range, aperture, condition —
instead of as marketing prose. It appears in the listing card, on the product
page as a two-column rail, and inside the merchant's product editor as the
form's spine. It is the one component that must exist in all four roles, and the
thing a competitor could copy the layout of but not the discipline.

## Voice

Plain, specific, unhurried. Controls name their action. Errors name the problem
and the recovery, not the exception. No exclamation marks, no "亲", no
confetti. Prices are stated as `¥16,999`, stocks as `剩余 12 件`.
