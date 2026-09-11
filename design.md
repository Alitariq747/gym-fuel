# Circa — The Design System

The visual system and the rules behind it. The canvas is the picture; this file is
the part a coding agent can actually read.

Written 10 September 2026.

> **This is a specification, not a description.** Nothing in this file is in the
> build yet. `product-as-built.md` describes what the code does today — dark
> screens, an amber ring, coral accents, emoji in the paywall. Everything below
> replaces that. Do not read this file as documentation of the current app.

**The canvas** — every screen, at
https://claude.ai/code/artifact/5039f517-40d9-4e28-860f-336719ab0cef

Two pages: `Circa` is the design; `Round 1 · not chosen` keeps the two directions
that lost, frozen as they were when the choice was made.

---

## The brief, in one paragraph

**Circa is a journal, not a dashboard.** A dashboard opens with aggregate numbers
and asks you to interpret them. A journal opens with what happened, in order, in
your own words. The name means *approximately*, so the design is **comfortable
being unsure** where every competitor performs false precision. An assumption is
not a caveat to hide in grey 11pt — it is the product, and it looks like it.

**What it is not:** not gym, not neon-on-black, not a fitness dashboard with six
rings, and not Cal AI's white-card-and-three-macro-rings, which is the category
default and which every desi entrant is already copying.

**The tension to watch.** *Minimal* and *calorie tracker* pull against each other.
You open this app to see numbers. Good minimalism here means **one number is
obviously the most important on every screen** — not fewer numbers. If you cannot
find the number in under a second, that is the failure.

---

## Foundations

### Colour — light

| Token | Hex | On paper | Use |
|---|---|---|---|
| `paper` | `#FBFAF6` → `#F4F1E8` | — | Body, vertical gradient top→bottom |
| `ink` | `#1A1917` | **16.8:1** | Primary text, filled buttons, bars |
| `ink2` | `#56534C` | **7.3:1** | Secondary text, body copy |
| `ink3` | `#6E6B64` | **5.1:1** | Mono metadata, captions |
| `accent` | `#8F6420` | **5.0:1** | Assumptions, links, ochre marks |
| `accentLarge` | `#A8762A` | 3.8:1 | **Large numerals and fills only** — never body text |
| `danger` | `#A03A28` | **6.4:1** | Failure text and destructive actions |
| `rule` | `#E3DFD3` | — | Section dividers |
| `ruleSoft` | `#F0ECE0` | — | Dividers inside a card |
| `cardBorder` | `#E9E5D9` | — | Card hairline |
| `card` | `#FFFFFF` | — | Raised surfaces |
| `sunken` | `#EFEBDF` | — | Recessed panels (check-in prompt, notes) |
| `mediaWell` | `#EAE6DA` | — | Photo placeholder ground |
| `dotted` | `#9A9488` | — | The certainty rule |
| `dangerGround` | `#FCF6F3` / border `#E8CFC7` | — | Failure card |

### Colour — dark

Not an inversion. A **designed twin** — warm near-black, never `#000000`, or the
paper character dies.

Same row order as the light table above, so the two can be read side by side.

| Token | Hex | On paper | Use |
|---|---|---|---|
| `paper` | `#171612` → `#100F0C` | — | Body |
| `ink` | `#F2F0E8` | **15.9:1** | Primary text |
| `ink2` | `#ACA79B` | — | Secondary |
| `ink3` | `#8B8679` | **5.0:1** | Mono metadata |
| `accent` | `#D9A94E` | **8.4:1** | Assumptions, links |
| `accentLarge` | `#D9A94E` | 8.4:1 | **Same as `accent`** — dark already clears AA, so there is no second value |
| `danger` | `#E08571` † | **6.7:1** | Failure text and destructive actions |
| `rule` | `#2D2A23` | — | Section dividers |
| `ruleSoft` | `#26231D` † | — | Dividers inside a card |
| `cardBorder` | `#2D2A23` | — | Card hairline — same value as `rule` in dark |
| `card` | `#1F1D18` | — | Raised surfaces |
| `sunken` | `#211F19` | — | Recessed panels |
| `mediaWell` | `#262319` | — | Photo ground |
| `dotted` | `#6B6659` | — | The certainty rule |
| `dangerGround` / border | `#241A16` † / `#3D2721` † | — | Failure card |

† **Derived 10 September**, when the palette was implemented. The artboards never
needed a dark failure state or a dark in-card divider, so these four had no
specified value. They were computed to the same AA standard as the rest, not
eyeballed — but they are the only tokens on this page that a drawn screen has
never confirmed. (`accentLarge` was the fifth gap; it resolved to the existing
`accent` rather than a new value.)

Every value on both tables was computed, not eyeballed. All text pairs clear
WCAG AA.

**These live in `GymFuel/Design/CircaTheme.swift`.** If a value there and a value
here disagree, this file wins and the Swift is the bug.

### Type — two faces, two jobs

**SF Pro** carries what a person wrote. **SF Mono** carries what the machine
added — times, macros, assumptions, section labels, scan quota, dates.

Both are system faces:

```swift
.font(.system(size: 17, weight: .medium))                    // content
.font(.system(size: 11, design: .monospaced))                // metadata
```

**Do not bundle a custom font.** Three reasons, in order of weight:

1. **Arabic.** Step 9's cross-localization wants Arabic, and most geometric sans
   faces have no Arabic coverage at all. SF Arabic is already there.
2. Dynamic Type keeps working without per-face metric tuning.
3. Nothing to add to the bundle.

If a custom face is ever wanted, it is a swap of two constants — but it is a
post-launch decision, not a launch one.

**Section labels** are mono, uppercase, ~10.5px, `letter-spacing: 1.4px`, `ink3`.
They replace bold sans headers everywhere.

### Shape and space

| | Value |
|---|---|
| Screen margin | 20 px (16 px when the content is a full-bleed card row) |
| Card radius | 18–20 px · small cards 16 px · thumbnails 11 px |
| Button radius | 13–15 px · pills 22 px · the dock 34 px |
| Hit target | **44 pt minimum, no exceptions** |
| Status-bar gap | 56 px, left empty — the real bar draws there |
| Home-indicator gap | 34 px |

**Never draw fake chrome.** No painted status bar, no painted keyboard. The real
ones render on top and a painted one looks doubled up.

---

## The rules

These are the design. The palette is just paint.

### 1. Certainty is a texture

The single most important rule, and the one that makes the name mean something.

| State | Rendering |
|---|---|
| Estimated by the AI | Number carries a **1.5px dotted underline** |
| Known — saved meal, or user-corrected | Number carries **no rule** |
| Not yet known — still analysing | **The dotted rule alone, with nothing above it** |

That third row is why this works: the same mark that means "estimated" on a
settled row means "not yet known" on a pending one, and **nothing jumps when the
number lands**. No spinner, no zero, no placeholder digits.

The confidence ring uses the same language — the unfilled arc is drawn dotted.

`confidence` and `assumptions[]` are already on every entry. This rule is what
makes them visible without a word of copy.

### 2. One edit path, one AI call

The entry screen shows assumptions but **does not let them be edited
individually**. Each per-assumption edit would be its own inference call, and the
margin does not survive that.

The single edit path is **rewording the raw sentence** — one call, the whole meal
re-read. The assumption list says so in place: *"Wrong? Reword the sentence above
— Circa re-reads the whole meal in one go."*

This matches `LogEntryDetailSheet`'s existing "Edit with AI" on `rawInput`. Keep it.

### 3. The raw sentence is the title

`rawInput` is displayed verbatim — *"two roti, chicken karahi, half a katori
rice"* — not laundered into "Chicken Karahi". `product-as-built.md` calls the raw
sentence "the primary key of truth"; showing it is what makes this a journal, and
it costs nothing because the data is already stored.

### 4. Weight is never typed

It comes from weigh-ins only. `SettingsTargets` deliberately has no weight row.
If weight can be edited directly, the trend the entire adaptive engine rests on
can be overwritten by hand — the same class of failure as the calorie rebate.

### 5. No traffic lights

No green/amber/red for confidence, scores or macro adherence. Monochrome plus one
ochre. Colour-coding a food log reads as a scolding, and the category is
saturated with it.

The exception is failure, which is `danger` — a warm brick, not a system red.

### 6. Failure keeps everything

`rawInput` survives, the photo survives. So the failure card leads with what is
preserved — *"Your words are saved, nothing to retype"* — and **Try again** costs
the user nothing. A failed photo also offers *"Describe it"*, because a dark
photo is better solved by typing than by re-shooting.

### 7. Dark inverts the primary button

A dark button on a dark ground disappears. In dark mode the primary becomes
`ink` on `paper` — light button, dark label. Everything else keeps its role.

### 8. At AX3, rows go vertical

Right-aligned mono numbers beside left-aligned wrapping text is the classic
Dynamic Type break. At accessibility sizes:

- the entry row goes vertical — the number drops **below** the title
- the macro bars stack instead of sitting in three columns
- the dock **drops its labels** rather than truncating them, keeping four 56 pt targets

This belongs in the SwiftUI from the first line, not as a later fix.

### 9. RTL is one attribute, and it was designed for

Arabic mirrors the whole layout: the number moves left, chevrons reverse, macro
bars fill from the right, the thumbnail moves right. The artboards prove it.
**The Arabic copy on the canvas is placeholder and needs a native speaker.**

### 10. Icons are drawn, never emoji

Inline SVG in the mockups, SF Symbols in the build. The current paywall carries
eight emoji and the summary step four; all twelve go.

---

## Screen inventory

Everything on the canvas, and what is not there yet.

| Screen | Artboard | Notes |
|---|---|---|
| Day | `Day` | Summary at top, `LogActionDock` keeps the bottom |
| Entry detail | `Entry` | Goal fit is the loudest block; confidence returns |
| Composer | `Composer` | Gym vocabulary removed from heading and examples |
| Analysing | `Analysing · text + photo` | Sweep overlay + the existing 3-stage message rotation |
| Failed | `Failed · retry` | Both failure shapes |
| Empty day | `Empty day` | Full target still the headline |
| Saved meals | `Saved meals` | The one path spending no AI call |
| Day picker | `Day picker` | **Day / Week only — no Month** |
| Menu | `Menu` | Absorbed the flame and the gear |
| Week | `Week · after a check-in` | Check-in result leads |
| Week, early | `Week · day 2` | The state most trialists actually see |
| Onboarding ×9 | `Onboarding · …` | Intro, name, formula, weight, movement, goal, how to write, reminders, your numbers |
| Paywall | `Paywall` + `Paywall · dark` | Six invariants marked in source |
| Settings ×3 | `Settings`, `· your targets`, `· delete account` | |
| Constraint proofs | `Dark`, `Arabic RTL`, `Dynamic Type AX3` | **Day view only so far** |

**Deliberately not drawn:** age and height (the weight artboard with a different
label and range). **Not yet drawn:** reminders settings, appearance, saved-meal
editor, nutrition sources, score explainer, the four auth screens — all variants
of patterns already on the canvas.

### Navigation

**Two scales: Day and Week.** No Month. The product's cadence is the weekly
check-in and the weigh-in; a month view would be a dashboard idea with nothing to
put in it. The calendar in the day picker is for jumping to a date, not a third
scale.

The day picker also states out loud the rule the current build only enforces
silently: `LogActionDock` hides outside today−7d, so **older days can be read but
not written to.**

---

## Cheques this design writes against unbuilt work

Three things on the canvas that the code cannot deliver today. Each needs a
decision, not a fix.

| Where | What it assumes | Reality |
|---|---|---|
| `Entry` — items list | Per-item calories **and** macros | `EstimatedItem` is `{name, quantity, estimatedComponents[{name, estimatedAmount}]}`. No macro fields. Needs the Step 6 schema and prompt change. |
| `Paywall`, `Onboarding · reminders` | "Reminders that stay quiet when you've already logged" | That is Step 12's suppression rule, which ships **after approval**. Either soften both lines for launch or accept the gap. |
| `Week`, `Settings · your targets` | A check-in has set a target and a rate | Step 4. The `Week · day 2` artboard is the honest pre-Step-4 state. |

---

## Open

1. **The Arabic copy** on the RTL artboard is placeholder. Needs a native speaker
   before it ships anywhere.
2. **Food photography is unresolved.** Every photo on the canvas is a drawn
   placeholder. How real food sits on warm paper — how much room it gets, whether
   it fights the minimalism — has not been tested and cannot be judged from
   placeholders.
3. **Nothing has been seen on a device.** Artboards are viewed at whatever zoom
   you like on a large screen. The app is a 6-inch phone, one-handed, at 11pm.
   A real-device check comes before the first line of SwiftUI.
4. **The component kit does not exist yet.** `CircaTheme.swift` landed on
   10 September, so the tokens are real Swift constants. The shapes — the card,
   the certainty rule, the four button tiers, the entry row, the dock — are still
   only drawn. Until they are code, every screen re-solves them and they drift.
5. **The app's manual light/dark override is unverified against the palette.**
   Tokens resolve off `UITraitCollection`; `appColorSchemePreference` is applied
   with `.preferredColorScheme`. That *should* propagate, but a theme that
   silently ignores the in-app toggle is exactly the bug that reaches the store.
   Check it with a swatch view before building on top.

---

## References

- Canvas: https://claude.ai/code/artifact/5039f517-40d9-4e28-860f-336719ab0cef
- `build-order.md` — where the design work sits in the sequence
- `store-copy.md` — the copy the onboarding intro and paywall are built from
- `product-as-built.md` — what the code does today, which is not this
