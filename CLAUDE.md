# LiftEats

An iOS calorie tracker, mid-repositioning. Two things a fresh session gets wrong:

- The repo is `GymFuel`, the app ships as `LiftEats`, and it is being renamed again.
- It looks like a lifting app. It is being repositioned **away** from lifting —
  toward home-cooked food that packaged-food databases don't cover. Gym vocabulary
  is being removed on purpose. Do not "restore" it.

## Where things live

| File | Answers |
|---|---|
| `build-order.md` | What we're building now, in order, with progress checkboxes. **Start here.** |
| `project-brief.md` | Scope — especially what is explicitly *out* |
| `meal-contract.md` | The meal payload, persistence and editing rules Steps 5 and 6 share. **Both repos.** Change it in neither step alone |
| `store-copy.md` | Exact App Store strings, with character counts |
| `design.md` | The visual system and its rules. A **spec** — the build does not look like this yet, and where an artboard's copy disagrees with its *Canvas drift* table, the table wins |
| `repositioning-strategy.md` | Why we're doing this. Rarely needed mid-build |
| `product-as-built.md` | What the code does today |

The backend (`gymfuel-ai-service/`) is attached as an additional working directory.
Read it directly — it is not missing, and it is not in this repo.

## How we work

- I name one step from `build-order.md`. Do that step and nothing else.
- Plan first. Show me the plan before writing code.
- **Small steps: under ~200 lines of code each.** Estimate the size while planning.
  If the work will go over, propose dividing it into smaller parts before writing
  anything, and we'll work through them in the session. Don't add them to
  `build-order.md`. If a part grows past the limit midway, stop and ask. App and
  backend code count; tests and docs don't.
- If something outside the step looks necessary, **stop and ask**. Don't widen scope.
- No opportunistic refactors, renames, or reformatting.
- **Comment sparingly.** The Swift app is already over-commented. Comment only what
  the code cannot say — a rule that would otherwise be "fixed" wrongly. Cite a
  contract section rather than restating it.
- No new dependencies.
- I build the Xcode project and run the Debug and Release checks myself — don't build it.
- **Keep the code modular, so extending or editing a feature later stays simple.**
  - One job per type: rules and maths in pure types with no Firebase or UI (like
    `MacroTargetCalculator`), reads and writes in services, screen state in view
    models, and views that only draw.
  - Each rule or number lives in one place (for example the calorie floor or the
    activity multipliers), so changing it later is a one-line edit.
  - Reuse what exists before adding more: `CircaComponents.swift`, the existing
    services and calculators. Extract a new component only when it repeats or
    carries a rule.
  - Pure logic gets unit tests.
  - This applies to the code a step touches. If older code makes a change hard, say
    so and propose the cleanup as its own small step — don't slip it in.

## Finishing a step

Report in this order:

1. Files touched and lines of code changed — so I can check `git diff --stat` matches
2. What behaviour changed, one line each
3. Exactly what I should tap in the app to confirm it
4. Anything you noticed but did **not** change
5. Tick the step's checkbox in `build-order.md`

## Stack

SwiftUI, iOS 17.6+. Firebase Auth, Firestore, Storage. RevenueCat with a **custom
paywall** — every Apple-required disclosure is ours to get right, not the SDK's.
Node service on Cloud Run for OpenAI calls.

Entitlement `ai_scans` · offering `default` · packages `pro_yearly`,
`pro_monthly` · products `lifteats_pro_yearly`, `lifteats_pro_monthly`.

## Never do these

Each one is a real failure mode, not a style preference.

- **Don't rename the `ai_scans` entitlement** — it is what
  `customerInfo.entitlements[...]` looks up, and renaming it breaks entitlement
  checks for every user still on an older build.
- **Don't build a `foods` collection, barcode scanner, or nutrition database** —
  its absence is the product.
- **Don't re-add exercise or workout logging** — removed deliberately in Step 3.
  If an exercise burn figure reappears anywhere, it corrupts the targets and what
  the Weight screen shows. **This includes importing one.** HealthKit active energy,
  workouts and steps are out — as an input *and* as displayed context. HealthKit is
  `bodyMass`, read-only.
- **Don't hardcode a trial length or a price** — read both from StoreKit.
- **Don't let weight be edited anywhere except a weigh-in.** Same failure class as
  the calorie rebate: the trend the Weight screen rests on stops being a measurement
  the moment it can be typed. Settings shows weight; it never edits it. Deleting a
  mistaken *manual* weigh-in is allowed (Step 4e); editing one is not.
- **Don't let the app change targets on its own.** Targets are worked out once and
  saved. They change only when the user edits them, taps Recalculate, or changes
  goal, goal weight or activity — never on a weigh-in, typed or from Apple Health.
  No coaching, suggested changes or rules judging progress: an expenditure engine,
  phases with check-ins, and a weekly page were each tried and dropped between 14
  and 17 September 2026. Store only the current plan and targets, never a history.
  `backup/step4b-abandoned` is a record, not a starting point.
- **Don't let one cuisine's vocabulary become the default.** The app is
  cuisine-agnostic. A fixed unit list in the prompt or schema, plus worked examples
  from a single cuisine, is enough to make the model apply that cuisine's units to
  everything — Step 6 shipped a prompt that answered "chicken chowmein" in
  *katori*. Units come from the person's own words, and otherwise from the shape of
  the food: plate, bowl or cup for loose food, the item itself when countable,
  tbsp for fats, grams for what a recipe would weigh. Keep worked examples spread
  across cuisines.
- **Don't show a measured burn number.** The formula's maintenance estimate may be
  shown — "about 2,420 kcal a day to stay at your weight", rounded, dotted as an
  estimate, never called "burn", never updated from food logs or weigh-ins. A
  number that claims to measure what this person burns needs validation we don't
  have (App Store 1.4.1).

## Relaxed — but only until the first user

**Firestore held no user documents on 7 September 2026.** Two former rules were
protecting data that doesn't exist. They come back the moment someone signs up, so
treat both as *before launch or not at all*.

- **`GoalType` raw values** (`lean_bulk`, `maintain`, `cut`) are safe to change
  in Firestore terms while there are no users. The meal-analysis backend ignores
  the goal field now; the prompt and former meal rating no longer use it. Check
  stored profiles and older app builds before changing the values later.
- **`logEntries` has no history to protect.** `LogEntryType` and its read path were
  deleted in Step 3, and `estimatedItems` with its card in Step 6, rather than
  being kept alive for entries that don't exist.

**Neither relaxation reaches `ai_scans`** — that rule is about builds in the wild,
not stored rows, and an empty `users` collection doesn't prove no old install
exists. It stays in the list above.

## The paywall must always hold

After any change touching subscriptions, all six still true:

1. Every price renders from `package.localizedPriceString` — never a literal
2. Terms of Service and Privacy Policy links present
3. Restore Subscription present and reachable
4. Renewal footer discloses auto-renewal and the 24-hour cancellation rule
5. No copy, link, or button points to a purchase method outside Apple IAP
6. A visible dismiss control remains
