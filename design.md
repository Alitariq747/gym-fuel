# Circa — The Design System

The visual system and the rules behind it. The canvas is the picture; this file is
the part a coding agent can actually read.

Written 10 September 2026. Revised 16 and 17 September: Step 4 no longer builds
check-ins, phases or a weekly page. It builds a plan the user can see — a goal
weight, a line to it, saved targets — and a Weight screen. Several artboards still
carry the old copy — see *Canvas drift* under the cheques.

Revised 19 and 22 September: one meal contains editable items, corrections preserve
unaffected values, and saved meals retain their estimated provenance. The meal score
has been removed. These rules supersede older artboards.

> **This is a specification, not a completion record.** The component kit and
> Steps 0–4 are complete; remaining screens are mid-revamp. `build-order.md` owns
> progress. Older product audits and artboards may describe superseded behavior.

**The canvas** — every screen, at
https://claude.ai/code/artifact/5039f517-40d9-4e28-860f-336719ab0cef

Two pages: `Circa` is the design; `Round 1 · not chosen` keeps the two directions
that lost, frozen as they were when the choice was made.

---

## The brief, in one paragraph

**Circa is a journal, not a dashboard.** A dashboard opens with aggregate numbers
and asks you to interpret them. A journal opens with what happened, in order, in
your own words. The name means *approximately*, so the design is **comfortable
being unsure** and makes its estimation limits visible. An assumption is
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
| `sunken` | `#EFEBDF` | — | Recessed panels (notes) |
| `mediaWell` | `#EAE6DA` | — | Photo placeholder ground |
| `well` ‡ | `#F1EDE2` | — | Icon well behind a text entry's glyph — takes a `cardBorder` hairline |
| `barTrack` ‡ | `#E8E4D8` | — | The unfilled part of a macro bar |
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
| `well` ‡ | `#1F1D18` | — | Icon well — same value as `card` in dark |
| `barTrack` ‡ | `#332F26` | — | The unfilled part of a macro bar |
| `dotted` | `#6B6659` | — | The certainty rule |
| `dangerGround` / border | `#241A16` † / `#3D2721` † | — | Failure card |

‡ **Read off the canvas 11 September**, when the component kit was built. Both
appear on drawn screens in both themes — the bar track on every macro row, the
well behind every text entry's glyph — but neither had been lifted into this table,
so the kit had nowhere to reach for them. They are measurements, not new
decisions. (`well` resolves to the same value as `card` in dark and differs only
on paper; it is still its own token, because the two have different borders.)

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
| Estimated, including a saved or user-adjusted estimate | Number carries a **1.5px dotted underline** |
| Supplied reference value, such as a label | Number carries **no rule**, with its source identified; this is not a claim of exact real-world accuracy |
| Not yet known — still analysing | **The dotted rule alone, with nothing above it** |

That third row is why this works: the same mark that means "estimated" on a
settled row means "not yet known" on a pending one, and **nothing jumps when the
number lands**. No spinner, no zero, no placeholder digits.

Saving does not verify an estimate. A quantity correction may reduce one source
of uncertainty while leaving the recipe uncertain. Keep source and user-adjustment
information, with plain labels where needed. Mixed totals retain the estimate mark
if any contributing nutrition is estimated. Direct manual totals are user-supplied,
not verified; identify them without inventing supporting ingredient detail.

Prefer specific uncertainty copy, such as "Sauce quantity assumed", to an
uncalibrated confidence percentage. Never present model confidence as a measured
accuracy rate.

### 2. One meal, predictable corrections

One submission stays one meal. Show its editable items and material components
with quantities and nutrition, followed by a reconciled meal total. The timeline
surfaces the most consequential assumption and opens the same editor.

Changing the amount of an unchanged ingredient scales its stored nutrition without
AI. Changing preparation or ingredients can reinterpret the affected part. Allow
several edits to be applied together and show the resulting calorie difference;
unaffected ingredients keep their values. Rewording the whole meal remains an
explicit option. Do not silently replace unrelated values during a small edit.

A manual total override must not leave a contradictory breakdown or old explanation
looking current. Follow the contract in `build-order.md` Step 5. Saving a corrected
meal preserves its items, assumptions and provenance for the next time; later
template changes never rewrite previously logged meals.

### 3. The raw sentence is the title

`rawInput` is displayed verbatim — *"two roti, chicken karahi, half a katori
rice"* — not laundered into "Chicken Karahi". `product-as-built.md` calls the raw
sentence "the primary key of truth"; showing it is what makes this a journal, and
it costs nothing because the data is already stored.

For photo entries, identify a generated description as the app's interpretation,
not words the user typed. Preserve the original input while making applied item
corrections visible; the displayed breakdown describes the current saved version.

### 4. Weight is never typed

It comes from weigh-ins only. `SettingsTargets` deliberately has no weight row.
If weight can be edited directly, the trend the Weight screen rests on
can be overwritten by hand — the same class of failure as the calorie rebate.
Deleting a mistaken *manual* weigh-in is allowed (Step 4e); editing one is not.

### 5. No traffic lights

No green/amber/red for confidence or macro adherence. Monochrome plus one
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

### 11. Keep meal explanations factual

Explain the portions, ingredients and preparation used in the estimate. Give the
user a direct way to correct them. Daily totals and saved targets provide the
personal context; the meal itself does not receive a numeric judgment.

---

## Screen inventory

Everything on the canvas, and what is not there yet.

| Screen | Artboard | Notes |
|---|---|---|
| Day | `Day` | Summary at top, `LogActionDock` keeps the bottom |
| Entry detail | `Entry` | Editable breakdown, reconciled total and assumptions; no confidence-as-accuracy ring |
| Composer | `Composer` | Gym vocabulary removed from heading and examples |
| Analysing | `Analysing · text + photo` | Sweep overlay + the existing 3-stage message rotation |
| Failed | `Failed · retry` | Both failure shapes |
| Empty day | `Empty day` | Full target still the headline |
| Saved meals | `Saved meals` | Reuse a corrected version with its breakdown and provenance, without an AI call |
| Day picker | `Day picker` | **Day / Week only — no Month** |
| Menu | `Menu` | Absorbed the flame and the gear. *Last week* becomes **Weight** (Step 7) |
| Week | `Week · after a check-in` | **Out of date** — drawn for the dropped expenditure engine. The Week screen keeps the week's food and the weight card; see *Canvas drift* |
| Week, early | `Week · day 2` | The state most trialists actually see |
| Onboarding ×9 | `Onboarding · …` | Intro, name, formula, weight, movement, goal, how to write, reminders, your numbers. *Your numbers* becomes the plan screen (4f) |
| Paywall | `Paywall` + `Paywall · dark` | Six invariants marked in source |
| Settings ×3 | `Settings`, `· your targets`, `· delete account` | `· your targets` and `· delete account` carry check-in copy; see *Canvas drift* |
| Constraint proofs | `Dark`, `Arabic RTL`, `Dynamic Type AX3` | **Day view only so far** |

**Deliberately not drawn:** age, height and goal weight (the weight artboard with a
different label and range). **Not yet drawn:** reminders settings, appearance,
saved-meal editor, nutrition sources, the four auth screens — all
variants of patterns already on the canvas. **Not yet drawn, and new:** the Weight
screen (4e) — weigh-in dots, the trend line, a dotted plan line and the goal, with
the weigh-in list below.

### Navigation

**Two scales: Day and Week.** No Month. The product's cadence is the day's log
and the weigh-in; a month view would be a dashboard idea with nothing to put in
it. The long view of weight is the Weight screen's chart. The calendar in the day picker is for jumping to a date, not a third
scale.

The day picker also states out loud the rule the current build only enforces
silently: `LogActionDock` hides outside today−7d, so **older days can be read but
not written to.**

---

## Cheques this design writes against unbuilt work

Older artboards carry promises or behavior that differ from the current build
and agreed launch contract. Follow the rules here and the build order.

| Where | What it assumes | Reality |
|---|---|---|
| `Entry` — items list | Per-item calories **and** macros | AI output already has item nutrition, but normalization drops it and the client model lacks it. Steps 5–6 retain it and add structured quantities/components for editing. |
| `Entry` — old rating | Old meal rating and confidence ring | Remove the rating. Show the meal breakdown and assumptions; keep uncertainty separate. |
| `Paywall`, `Onboarding · reminders` | "Reminders that stay quiet when you've already logged" | Step 12's suppression ships **after approval**. Soften both lines for launch; onboarding opt-in alone does not deliver this behavior. |
| `Week`, `Settings · your targets` | A check-in has set a target and a rate | **No longer planned.** Targets are saved and change only when the user acts (Step 4); `Settings · your targets` becomes the targets screen (4d). See *Canvas drift* below. `Week · day 2` is still the honest early state. |

### Canvas drift — 17 and 19 September

Step 4 changed after these artboards were drawn. There is no weekly page, no
check-in, no phase, no suggested change and no measured burn number. The user sets a
goal weight, sees a plan line to it, and gets saved targets that change only when
they act (`build-order.md` Step 4, *The rules*). **Build these screens from this
table, not from the artboard copy.** The layouts still stand; the words do not.
Final wording is settled in each step and must agree with `store-copy.md`.

| Artboard | Still says | Should say, in substance |
|---|---|---|
| `Entry` | Reword the whole meal to correct an assumption; saved/corrected means known | Editable quantities and affected-item reinterpretation, a visible delta, preserved uncertainty and a reconciled total (Steps 5–6). |
| `Entry`, rating area | Generic goal verdict and confidence-adjusted rating | Remove this area; give the breakdown and assumptions room instead. |
| `Saved meals` | Reused totals without their reasoning | The corrected meal version, retaining items, assumptions and provenance (Step 6). |
| `Day`, `Dark` | "Trend weight down 0.4 kg. Your targets moved." | The trend only. Targets never move by themselves, so nothing announces that they did. |
| `Menu` | "Last week · check-in ready" | The row becomes **Weight** (4e), with nothing to flag. *Your targets* opens the targets screen (4d). |
| `Week · after a check-in` | "Check-in · done Sunday" · "your new daily target" · "you are burning about 2,810 a day" | The week's food and the weight card, which opens the Weight screen (4e). No check-in, no new target, **never a burn number**. |
| `Week · day 2` | "First check-in · Sunday" | No check-in date. With few weigh-ins, the weight card shows its early state. |
| `Onboarding · formula` | "from your first check-in it measures the real number anyway" | Nothing measures a burn. The number is a starting estimate: the Weight screen shows whether it is right, and the user can recalculate or edit. |
| `Onboarding · daily movement` | "Within two or three weeks Circa has measured what you actually burn, and stops using it." | **Remove the line.** It claims a measurement that was dropped — an App Store 1.4.1 problem. Four options, each a normal week *including* exercise. |
| `Onboarding · goal` | "From your first check-in onward, Circa moves them…" · "at a rate you set" | No rate to set, and nothing moves on its own. Gain, Lose fat or Maintain, then a goal weight for Gain and Lose fat (4c). |
| `Onboarding · reminders (3a)` | "Your weekly check-in … once your targets have actually moved" | A reminder to weigh in, claiming nothing moved. The built screen already leaves it out until Step 12. |
| `Onboarding · your numbers` | "Circa moves them to match what your body is actually doing" | Becomes the plan screen (4f): a line to the goal date, the targets with one reason each ("about 2,420 kcal a day to stay at your weight"), and "This is a starting estimate. Your weigh-ins will show whether it's right." Targets stay as set until the user changes them. |
| `Paywall`, `Paywall · dark` | "Targets that move with your weight, not a formula that guessed once" · "A weekly check-in that shows its working" | As in `store-copy.md`: a steady plan to a goal weight, targets that show their working and change only when you change them, and weigh-ins against the plan. |
| `Settings · your targets` | "set at Sunday's check-in" · Rate 0.5% a week · "Changing your goal closes the current phase…" | The targets screen (4d): the numbers, "Set at 85 kg on 3 Sep", the stay-at-your-weight estimate, **Edit** and **Recalculate**, and goal weight in place of Rate. Changing the goal restarts the plan line; there are no phases. |
| `Settings · delete account` | "Weigh-ins and check-ins" | Weigh-ins only — check-ins are never stored. |

The day-streak tile on both Week artboards is still undecided. Onboarding promises
"No badges, no streak alarms", but Step 12 still plans streak protection, and the
weekly page that was going to settle it is gone.

---

## Open

1. **The Arabic copy** on the RTL artboard is placeholder. Needs a native speaker
   before it ships anywhere.
2. **Food photography is unresolved.** Every photo on the canvas is a drawn
   placeholder. How real food sits on warm paper — how much room it gets, whether
   it fights the minimalism — has not been tested and cannot be judged from
   placeholders.
3. **Check the changed experience on a device.** Earlier TestFlight users liked
   explicit assumptions. Recheck the revised editor on a small screen,
   including Dynamic Type; do not mistake artboard review for interaction testing.
4. **Reuse the completed component kit.** `CircaTheme.swift` and
   `CircaComponents.swift` exist. Extend only for the rules above and genuinely
   repeated patterns; do not rebuild the kit as part of the meal editor.
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
