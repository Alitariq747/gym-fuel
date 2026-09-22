# Meal Contract

The shared payload and persistence shape for one meal with editable items.

**Step 5 builds the client against this. Step 6 makes the server produce it.**
Neither step may change it alone — a change here is a change to both repos, and
`build-order.md` Steps 5 and 6 are verified together.

Settled 21 September 2026. Closes `project-brief.md` open question 3.

---

## 1. What this contract is for

One submission is **one meal**: one timeline entry, several editable items, one
meal total. "Two roti, chicken karahi, half a katori
rice" is three items in one entry, not three entries.

Today the model already returns per-item `calories/protein/carbs/fat`
(`gymfuel-ai-service/src/ai/logEntrySchema.js`), and `normalizeEstimatedItems`
throws all four away. What reaches the client is a name, a prose quantity
(`"half a katori"`) and prose components — none of it arithmetic. So an amount
cannot be corrected without re-running the whole meal through the model.

This contract makes amounts numeric and nutrition per-node, so that **changing
an amount is local arithmetic and costs nothing**.

### Decisions this contract closes

| | |
|---|---|
| **Amounts** | `quantity: Double` + free-text `unit: String`. Scaling is a pure ratio. **No unit conversion, no gram equivalents** — that is a food database, and its absence is the product. |
| **Depth** | Exactly two levels: items, and components within an item. Not recursive. |
| **Reinterpretation** | Defined in §9, **not built in Step 5**. Step 5 ships quantity edits only. |

---

## 2. The rule that governs every future change

> **Every field this contract adds is optional, or wrapped so that a malformed
> value decodes as absent. No non-optional field is ever added to
> `LogEntryFeedback`, `LogEntry` or `SavedMeal` again.**

This is not style. `FirebaseLogEntryService.decodeEntry(skippingFailuresFrom:)`
`compactMap`s decode failures away, recording only a Crashlytics non-fatal. A
field the client cannot decode does not show an error — **it silently removes
that meal from the user's timeline.** `FirebaseSavedMealService` does the same
for saved meals.

**The live risk is forward, not backward.** The two repos deploy independently:
Cloud Run ships without an App Store release, so a client in the wild meets
payloads it was never compiled against, permanently. If Step 6's normalizer gets
one field's type wrong, every meal that build analyses disappears — including one
logged ten seconds earlier. An empty `logEntries` collection offers no protection
against this at all, in the same way it offers none for `ai_scans`: the exposure
is builds in the wild, not stored rows.

So a **malformed nested value** throws from inside and takes the whole entry with
it. The client therefore wraps `breakdown` so any decode failure inside the tree
collapses to `nil`, and the entry survives showing its totals. Enum raw values
decode leniently to a named fallback, as `LogEntrySource`, `LogEntryStatus` and
`GoalType` already do.

The backward case is the same rule arriving later. A **non-optional** new field
throws `keyNotFound` on every document written before it existed, and every such
document disappears. Firestore held no user documents on 7 September 2026, so
today that costs nothing — but it becomes true of real data the moment someone
signs up, which is why the invariant is written as permanent rather than as
something to revisit at launch.

**Versioning.** `breakdown.version` is an `Int?`; absent reads as `1`. A client
that meets a version it does not know keeps the totals and ignores the
breakdown. The server bumps it only when an existing field changes meaning —
adding a field does not bump it, because unknown keys already decode fine.

---

## 3. The shape

### `MealAmount`

```swift
struct MealAmount: Codable, Equatable, Hashable, Sendable {
    var quantity: Double           // as first estimated. NEVER overwritten.
    var unit: String               // "tbsp", "roti", "katori", "g", "slice"
    var adjustedQuantity: Double?  // the user's correction. nil until they make one.

    var effectiveQuantity: Double { adjustedQuantity ?? quantity }
    var scale: Double { quantity > 0 ? effectiveQuantity / quantity : 1 }
    var isAdjusted: Bool { adjustedQuantity != nil && adjustedQuantity != quantity }
}
```

**An edit writes `adjustedQuantity` and nothing else.** `quantity` is what was
first estimated and is never rewritten, by the client or the server. That single
choice buys:

- **No compounding.** 2 → 3 → 1.5 always computes from 2. Not 2 × (3/2) × (1.5/3).
- **Exact round trips.** 2 → 1 → 2 restores the original numbers bit for bit.
- **"User-adjusted" is derived**, so it cannot drift out of sync with the number
  it describes.
- **Removing an ingredient is `adjustedQuantity = 0`** — no delete affordance, no
  empty-item state, no re-numbering.

`quantity == 0 ⇒ scale == 1` guards the only division in the contract. **The
server must never emit `quantity == 0`**; it omits `amount` entirely instead.
Zero is a user-only value meaning *removed*.

**The server never emits `adjustedQuantity`.** It is written only by the client,
only from the editor.

### `MealComponent` and `MealItem`

```swift
struct MealComponent: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String            // opaque, unique within the breakdown, stable forever
    var name: String
    var amount: MealAmount?   // nil ⇒ read-only, not quantity-editable
    var nutrition: Macros?    // for amount.quantity. nil ⇒ descriptive only
    var source: MealProvenance?   // absent reads as .estimated
    var sourceNote: String?   // "USDA 05062, chicken breast, roasted"
    var assumption: String?   // "Ghee, not oil"
}

struct MealItem: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var amount: MealAmount?
    var nutrition: Macros?    // nil ⟺ this item is priced by its components
    var components: [MealComponent]
    var source: MealProvenance?
    var sourceNote: String?
    var assumption: String?
}

struct MealBreakdown: Codable, Equatable, Hashable, Sendable {
    var version: Int?         // 1 today; nil reads as 1
    var items: [MealItem]
}
```

`nutrition` is always **the nutrition for `amount.quantity`** — the original
estimate, not the corrected amount. A node's contribution is
`nutrition × amount.scale`, computed at read time. Saving an edit never rewrites
`nutrition`.

**`id` is opaque.** The client never parses it, never derives meaning from it,
and never rewrites one. The server generates ids on first analysis; they must be
unique within a breakdown and must survive every later reinterpretation of an
untouched node (§9).

**`source` is required on the wire and tolerant on the client.** Step 6 sends it
on every node (§10). A node that arrives without one reads as `.estimated` rather
than taking the whole breakdown down with it — the client never claims more
certainty than it has, and a server slip costs a label, not a meal.

Two types rather than one recursive node is deliberate: the depth is capped at
two, the model's schema is already two levels, and the card and editor are two
levels. A recursive type invites a depth-3 response nobody designed for.

### Added to `LogEntryFeedback`

| Field | Type | Meaning |
|---|---|---|
| `breakdown` | `MealBreakdown?`, failure-tolerant | the editable tree. `nil` on older entries and after an override. |
| `macrosProvenance` | `MealProvenance?` | where `macros` came from. `nil` reads as `.estimated`. |

`BackendLogInterpretationService` decodes the response straight into
`LogEntryFeedback`, so **the model is the wire contract** — adding the field to
the client is what makes the server able to send it.

`explanation` and `assumptions` remain non-optional on the response path. Step 6
must keep sending both.

### Older entries are never migrated

An entry written before this contract has `estimatedItems` and no `breakdown`.
It is **left exactly as it is**. Synthesising a breakdown from it would mean
inventing nutrition for `estimatedAmount: "120g"`, and `build-order.md` Step 5 is
explicit that older totals-only meals "never gain invented component detail".

One branch, one place:

| State | Renders |
|---|---|
| `breakdown != nil` | the breakdown card, editable |
| `breakdown == nil`, `estimatedItems != nil` | the existing `EstimatedItemsCard`, read-only, untouched |
| neither | nothing |

`LogEntryEstimatedItemsCard.swift` is not edited in Step 5.

**That branch is temporary, not part of the contract.** It exists only for the gap
between Step 5 and Step 6, when the backend still sends `estimatedItems` and no
`breakdown`. Step 6 deletes the card, the field and its types outright — see
`build-order.md` Step 6. What survives permanently is the *totals-only* state
below it, which a hand-typed saved meal and a superseded total both produce.

---

## 4. Contribution — an ingredient is never counted twice

> **The meal total is the sum of its items. An item contributes its own
> `nutrition` when it has one, and otherwise the sum of its components'
> contributions. A component with `nutrition == nil` is descriptive: it is shown
> without a number and contributes nothing.**

`nutrition != nil` on an item asserts *"my components are prose"*.
`nutrition == nil` asserts *"my components are the arithmetic"*. The two are
mutually exclusive by construction, so there is no configuration in which an
ingredient is counted twice, and no heuristic deciding which number to trust.

The common case for home-cooked food is the second: chicken karahi has no
nutrition of its own and is priced by ghee, chicken and masala — which is
exactly what makes "2 tbsp ghee → 1 tbsp" possible.

**A component-priced item's own amount does not scale its components.** Whichever
level carries the nutrition is the level that carries the handle: an item with its
own nutrition is scaled by its own amount, and an item priced by its parts is
scaled by theirs. Applying both would put the same correction on a number twice —
"2 katori of karahi" *and* "4 tbsp of ghee" would quadruple the ghee. So a
composite item's amount is shown and never edited; its parts are the editable
level. Correcting "one katori" to "two" means doubling the parts.

**Step 6 owns enforcing this.** The normalizer must emit an item with its own
nutrition *or* with priced components, never both. If the model returns both,
the normalizer keeps the item's own nutrition and strips nutrition from the
components, leaving them descriptive.

### Rounding

Stored and computed at full `Double` precision. Rounded **only at display**, to
whole kcal and whole grams. The displayed total is `round(Σ exact)`, never
`Σ round(each)`.

The two can differ, and the contract bounds the difference rather than hiding
it — each row's error is under 0.5, so:

```
| displayed total − Σ displayed rows | ≤ contributingRowCount / 2
```

No largest-remainder apportionment. Nudging rows so a column adds up on screen
is a precision this product does not have.

### Worked example — "two roti, chicken karahi, half a katori rice"

| Node | quantity | unit | kcal | P | C | F |
|---|---|---|---|---|---|---|
| **Roti** — own nutrition | 2 | roti | 239.6 | 7.0 | 44.2 | 5.1 |
| **Chicken karahi** — `nutrition = nil` | 1 | katori | *(from components)* | | | |
| · Chicken thigh, boneless | 150 | g | 250.4 | 25.9 | 0.0 | 16.2 |
| · Ghee | 2 | tbsp | 239.8 | 0.0 | 0.0 | 27.1 |
| · Tomato and onion masala | 100 | g | 59.7 | 1.2 | 7.8 | 3.4 |
| · Whole spices — descriptive | — | — | — | — | — | — |
| **Rice, boiled white** — own nutrition | 0.5 | katori | 129.5 | 2.7 | 28.1 | 0.3 |

- Karahi contributes `250.4 + 239.8 + 59.7 = 549.9` kcal. The spices contribute
  nothing and do not make the item's total `nil`.
- Meal total: `239.6 + 549.9 + 129.5 = 919.0` kcal → **919 kcal · 37 P · 80 C · 52 F**.
- The three displayed item rows read 240, 550 and 130, which sum to 920. The
  difference of 1 is within the bound of 3 ÷ 2 = 1.5. **Both numbers are shown as
  they are.** Neither is adjusted to make the column add up.

---

## 5. Provenance — two axes, because one is not enough

"The user halved a value that came from a label" is both reference-sourced and
user-adjusted. A single enum cannot say that, so the contract keeps them apart.

```swift
enum MealProvenance: String, Codable {   // lenient: unknown ⇒ .estimated
    case estimated   // the model's guess
    case reference   // a label or documented reference; sourceNote names it
    case userTotal   // the user typed the meal total. MEAL-LEVEL ONLY.
}
```

- **Where the number came from** — `node.source` (`.estimated` | `.reference`), or
  `feedback.macrosProvenance` for the meal, which may also be `.userTotal`.
- **Whether the user corrected the amount** — `amount.isAdjusted`, derived.

| source | adjusted | Mark | Label |
|---|---|---|---|
| `.estimated` | no | dotted | "Estimated" |
| `.estimated` | yes | dotted | "You set the amount" |
| `.reference` | no | none | the `sourceNote` |
| `.reference` | yes | none | "⟨sourceNote⟩, your amount" |
| `.userTotal` | — | none | "You set this total" |

**A user-adjusted estimate keeps its dotted rule.** Correcting an amount removes
one source of uncertainty and leaves the rest; it does not verify the estimate.
`design.md` rule 1 and `build-order.md` Step 5 both say so: saving or editing
does not establish accuracy.

**Roll-up:** a total is `.reference` only if every contributing node is
`.reference`. Mixed is `.estimated`. Uncertainty propagates upward; it never
disappears into an average.

---

## 6. Editing

### A quantity edit

Writes `adjustedQuantity` on the edited node. Nothing else in the tree changes —
not another node's `nutrition`, not its `adjustedQuantity`, not an id. The meal
total is recomputed by §4 from the same stored numbers. No network call, no AI
scan, no change to `explanation`, `assumptions` or `confidence`.

Several edits apply together on one save.

**The delta is the difference of the displayed totals**, not the rounded
difference of the exact ones. `displayedDelta = round(new) − round(old)`, so the
three numbers on screen always agree with each other.

Worked example — a chicken sandwich, mayonnaise 2 tbsp → 1 tbsp:

| Component | quantity | kcal stored | scale | contributes |
|---|---|---|---|---|
| Bread, white | 2 slice | 158.0 | 1.0 | 158.0 |
| Chicken breast, roasted | 80 g | 132.0 | 1.0 | 132.0 |
| Mayonnaise | 2 tbsp | 187.0 | **0.5** | **93.5** |
| Lettuce and tomato — descriptive | — | — | — | — |

- Before: `477.0` → **477 kcal**. After: `383.5` → **384 kcal**.
- Footer: `477 → 384 kcal · −93`.
- Stored: `amount.adjustedQuantity = 1` on the mayonnaise. Its `quantity` is
  still `2` and its `nutrition` is still `187.0`. Bread and chicken are
  byte-identical.
- Setting it back to 2 clears the adjustment and restores 477 exactly.

### A manual total override supersedes the breakdown

Typing a meal total asserts a number the breakdown does not produce. The two
cannot both be shown as current.

| Field | After the override | Why |
|---|---|---|
| `macros` | the typed total | — |
| `macrosProvenance` | `.userTotal` | user-supplied, not verified |
| `breakdown` | **nil** | it described a different meal |
| `estimatedItems` | **nil** | same, for the legacy branch |
| `explanation` | `""` | the model's words describe superseded numbers |
| `assumptions` | `[]` | they belong to the discarded breakdown |
| `confidence` | **nil** | confidence in a number no longer shown |

**Supersede means delete, not grey out.** If a superseded breakdown survived in
storage, the card, the timeline assumption line and the saved-meal snapshot
would each have to re-implement *"is this superseded?"*, and
one of them would get it wrong. One rule, one place, zero readers.

The user is told before it happens, and it is confirmable. **A quantity edit is
not an override** — its total is derived and its breakdown stays.

---

## 7. Persistence

`LogEntry` and `SavedMeal` are encoded through `Firestore.Encoder` from a private
mirror document struct, then written with `setData`.

### Clearing a field requires a full write

Synthesized `encode(to:)` uses `encodeIfPresent`, so a `nil` field is **omitted**
from the dictionary, and `setData(merge: true)` leaves the server's old value in
place. Setting `breakdown = nil` under `merge: true` does not delete it — the
superseded breakdown returns on the next snapshot.

| Path | Write | Why |
|---|---|---|
| `updateEntry` | `setData(data)` — **no merge** | the only path that clears |
| `saveEntry`, `saveEntryLocally`, `updateEntryLocally` | `setData(data, merge: true)` | creates and offline writes; never clear |
| `updateMeal` (saved meals) | `setData(data)` — **no merge** | same reason; also survives a missing doc, which `updateData` does not |

Not `FieldValue.delete()` sentinels: those are stringly-typed nested reach-ins
that every future nullable field must remember to join. A full replace is correct
for every nullable field, forever.

**The cost, stated plainly: any Firestore key not mirrored in the document struct
is destroyed by a client edit.** Today that is only `updatedAt`, which nothing
reads. **Step 6 must mirror any server-owned field it adds to `LogEntryDocument`,
or accept that a user edit wipes it.**

---

## 8. Saved meals

A saved meal is a **snapshot of a corrected version**, not a pointer to the entry
it came from.

- **Saving** copies the breakdown as it stands — every `adjustedQuantity`, every
  assumption, every `source` and `sourceNote` — plus the description.
- **Re-logging copies that snapshot into the new entry.** No AI call, no network
  round trip, and `macrosProvenance` carries over, so a re-logged corrected meal
  does not present itself as a fresh estimate.
- **Later edits to the saved meal never rewrite entries already logged from it.**
  This is free: `SavedMeal` is a value type carried by value, and a log entry
  holds its own copy. There is no foreign key in either direction, and there is
  no learning across unrelated meals.
- **Editing a saved meal's totals supersedes its breakdown**, by the same rule as
  §6 and the same function. Entries already logged keep theirs.
- **A saved meal with no breakdown logs exactly as it does today** and gains no
  items.

---

## 9. Reinterpretation — defined here, built in Step 6

Changing *what an ingredient is* or *how it was cooked* cannot be done with
arithmetic. Step 5 does not build it. The shape is settled here so Step 6 drops
in without renegotiating the contract.

```
POST /log-entries/{id}/reinterpret

{ rawInput, goal, scope: { itemId } | { meal: true }, instruction, breakdown }
→ { title, detail, feedback: { …, breakdown } }
```

**A scoped reinterpretation may replace only the named item's subtree.** Every
other item must come back with an identical `id` and identical stored
`nutrition`, `amount.quantity` and `amount.adjustedQuantity`.

**The client rejects a response whose untouched-item id set changed**, or whose
untouched items' stored values moved. That turns "preserve unaffected values"
from a sentence in `build-order.md` into a check that fails loudly instead of
quietly corrupting a meal the user had already corrected.

A whole-meal reinterpretation (`scope: { meal: true }`) replaces everything, and
every adjustment is lost. That is the existing *Edit with AI* behaviour and it
stays an explicit, separate action — never something a quantity edit triggers.

---

## 10. What Step 6's normalizer must guarantee

Validate, do not trust a fluent explanation.

1. Every `id` is unique within the breakdown.
2. An item has its own `nutrition` **or** priced components, never both.
3. Where `amount` is present, `quantity > 0`. Otherwise omit `amount`.
4. `adjustedQuantity` is never emitted.
5. `feedback.macros` equals the total computed by §4, within the §4 rounding
   bound — recomputed server-side, not copied from the model's own `totals`.
6. `explanation` and `assumptions` are always present, and every node carries a
   `source`. The client tolerates a missing one as `.estimated`; the server does
   not rely on that.
7. A `version` is sent on every breakdown. Bump it only when an existing field
   changes meaning — a client that meets a version it does not know keeps the
   totals and does not render the breakdown.
8. Household measures carry their assumptions: serving size, cooked or raw
   basis, and oil allocated to the eaten portion rather than the whole pot.
