# LiftEats — Repositioning Brief

Working contract for the repositioning. The *argument* for it lives in the strategy
doc and copy deck (see References); this file is the implementation scope only.

Written 6 September 2026, revised 7, 14, 16, 17, 19 and 22 September. Steps 0–5 in
`build-order.md` are complete, including the paywall trial fix. That file owns
progress and the detailed meal contract; this brief summarizes scope.

---

## The decision, in one paragraph

Circa helps people understand and log their actual meals: describe or photograph
food, inspect its estimated ingredients and portions, correct the version, and
save it for next time. Goal-driven users get a plan and user-controlled targets.
Lifting comes off the surface; lifters
remain one subset of the audience. The `ai_scans` entitlement stays unchanged.

---

## Positioning

**Thesis.** A useful estimate explains the user's version of a meal and makes
corrections dependable. A food name alone does not specify its recipe or portion.

**Audience.** Step 0 closed the brand as cuisine-agnostic. Launch examples can
emphasize Pakistani/home-cooked food the founder and TestFlight users know, plus
everyday meals across cuisines. Diaspora is a promising acquisition segment;
regional willingness to pay and costs remain measurements, not settled facts.

**Evidence and retention.** Ahmad reports that TestFlight users liked explicit
ingredient and quantity assumptions. That supports finishing the interaction; it
does not establish measured accuracy or paid retention. Corrected saved meals
and the existing plan/weight screen are the repeat-use
experience to evaluate after launch.

**Why this positioning, given four apps say something similar.** Not because it is
unownable by others — in a market where an AI-coded competitor ships a matching
feature in a week, defensibility is not on the menu at our size. It is chosen
because it is the angle that **distributes**: filmable, searchable, and adjacent
to creator communities that exist. calog.cc shares the pitch but is web-first —
not in App Store search, not in the listicles, no iOS push. Calorify is the real
benchmark for product experience, distribution and free-tier expectations.
We stop optimising for a moat and start optimising for a channel.

**Explicitly not.** We are not a workout tracker. Hevy owns that at $2.99 with a
free tier and 15M users. We do not compete there.

### Cuisine reach — what localisation can and cannot do

App Store metadata is served by **device language, not by storefront**, and the
only English variants App Store Connect offers are U.S., U.K., Australia and
Canada. There is no English (Pakistan), English (India), English (UAE) or English
(Singapore). A Pakistani-British user in London sees the **English (U.K.)**
listing — the same one every other British person sees.

We therefore cannot segment cuisines by country in English. Instead:

- **Name and subtitle stay cuisine-agnostic.** "Calorie counter for home food"
  covers kunna, jollof, adobo and tagine equally. The thesis is about *databases*,
  not about desi — that is what makes it scale past one cuisine.
- **Keywords carry the cuisines.** Invisible to users, so pack several. Diluting
  costs some ranking strength per term, but the long tail is near-uncontested.
- **Screenshots carry the specificity.** One desi shot proves the claim without
  narrowing it.

**Arabic is the best second localisation** and a post-launch item: Gulf storefronts
have high ARPU, large South Asian expat populations, *and* their own uncovered
cuisine (machboos, kabsa, mandi). Two underserved audiences, one localisation.

**Urdu and Hindi localisations remain outside this launch.** Future expansion
depends on observed regional demand, proceeds and inference cost. A language or
country alone does not establish whether a subscriber can be served profitably.

---

## What changes in the product

### 1. Naming and labels

| Surface | Now | After |
|---|---|---|
| App name | LiftEats | **`Circa: Food & Calorie Journal`** — decided 8 September |
| Subtitle | *(none)* | **`AI macro tracker, no weighing`** — decided 8 September |
| `GoalType.leanBulk.displayName` | "Lean Bulk" | "Gain" |
| `GoalType.cut.displayName` | "Cut" | "Lose fat" |
| `GoalType.maintain.displayName` | "Maintain" | "Maintain" |
| Entitlement id | `ai_scans` | **unchanged — decided 7 September, closed** |

`GoalType.detail` copy also drops the lifting register while keeping the meaning,
and `GoalType.symbolName` still returns `figure.strengthtraining.traditional` for
`.leanBulk` — a barbell glyph sitting on the goal picker.

**The raw values are no longer protected, but still not worth renaming alone.**
Firestore held no user documents as of 7 September, so `lean_bulk` / `maintain` /
`cut` are safe to change until the first real user. What makes it interesting is
not the persistence: `goal.rawValue` is what reaches the AI service
(`BackendLogInterpretationService.swift:121`), and the prompt hard-codes the tokens
and frames `lean_bulk` as *"carbs that support training and recovery"*
(`logEntryPrompt.js:55,76`). The lifting register is in the model's reasoning on
every estimate, where display strings cannot reach it. **The fix is the prompt
language, not the token** — rename only while already editing those lines. See
`build-order.md` Step 2.

**`ai_scans` does not relax with it.** Entitlement lookup is client-side against
RevenueCat, so the risk is builds in the wild rather than stored rows, and an empty
`users` collection does not prove no such install exists.

### 2. The food experience — Steps 5–6, share card in 7

The detailed contract lives in `build-order.md` Steps 5–6. Agree on the schema
before editing code, then implement in the existing small-step workflow.

- **One meal with editable items.** One submission retains its context, with
  structured quantities, item/component nutrition and reconciled totals.
- **Visible assumptions.** Show the most consequential assumption on the timeline
  and the full editable breakdown in detail.
- **Predictable corrections.** Quantity changes scale stored nutrition without AI;
  ingredient/preparation changes can reinterpret the affected part. Apply edits
  together, show the delta and preserve unrelated values. Manual total overrides
  cannot silently coexist with an incompatible breakdown or explanation.
- **Preserved provenance.** Estimates remain estimates after editing or saving.
  Carry uncertainty through photo recognition and nutrition analysis; distinguish
  generated descriptions from user text.
- **Saved versions.** Keep the corrected items, quantities, assumptions, source
  information and description. Reuse without inference, copy into each log, and
  do not rewrite old entries when the reusable version changes. Support older
  totals-only meals without inventing a breakdown.
- **Documented references.** Start with roughly 30–50 meal/recipe cases and
  preparation variants, then expand after launch. Household measures need explicit
  serving and preparation assumptions. No searchable food database.
- **Share card.** Finalize in Step 7 after editing. Show the meal, nutrition, key
  assumption and explanation without exposing private target or weight data.

### 3. Exercise — removed in completed Step 3

Decided 7 September, replacing the earlier "demote to context". Once lifting is
off the surface, exercise logging has no remaining job:

- Adherence context would be decoration on the Weight screen, not an input to it.
- Explaining weight variance was overstated — variance is dominated by water,
  sodium, carbs, glycogen and cycle, and the log cannot distinguish "trained
  harder" from "ate more salt".
- The calorie rebate at `DailyMacroDetailSheet.swift:12`
  (`target - consumed + burned`, with a "Burned" tile at `:31`) actively
  **defeats the plan**: it hands calories back on active days, so the user eats
  their target plus the rebate, the weigh-ins fall behind the plan line, and the
  target they trusted was never the one they ate. The rebate and a plan built on
  weigh-ins are mutually exclusive.

Deleting it removes a cost centre with zero revenue attached — every exercise log
burns an AI call for a number nothing will read.

**Completed in Step 3.** The rebate, workout input and exercise branches were
removed before the plan work. The earlier proposal to defer the sweep is
superseded. `ActivityLevel` now includes normal weekly exercise in the four
options established by Step 4. Do not restore an exercise log, burn import or
calorie rebate while implementing meal editing.

### 4. The plan and saved targets — completed Step 4

**Re-scoped three times.** An expenditure engine — estimate what the user burns from
logged intake and trend weight, then set targets from that number — was dropped on
14 September: a health measurement we cannot validate under App Store 1.4.1, and
only as good as a complete food log. A pace check with `phases` and `checkIns`
collections was built and reverted on 16 September: storing every decision made it
thousands of lines. A weekly page with a one-tap target change was dropped on
17 September before it was built: its stall and too-fast rules were subjective, and
each needed a citation.

**What replaces it.** A plan the user can see. Onboarding asks for a goal weight and
shows a line to it — 0.5 % of body weight a week when losing, 0.25 % when gaining —
with the daily targets and one plain reason for each. A Weight screen plots every
weigh-in against that line. **Nothing coaches, suggests or judges.** Targets are
worked out once and saved; they change only when the user edits them, taps
Recalculate, or changes goal, goal weight or activity. Weigh-ins never move them.

**The rules are owned by `build-order.md` Step 4, *The rules*; change them there
first.** In outline:

```
users/{uid}/weighIns/{yyyy-MM-dd}                    // shipped in 4a
  weightKg, loggedAt, source: manual | healthKit

users/{uid}                                          // new fields, in 4c
  goalWeightKg, planStartedOn, planStartWeightKg
  targetCalories, targetProteinG, targetCarbsG, targetFatG
  maintenanceCalories, targetsSetOn, targetsSetAtWeightKg

maintenance = Mifflin–St Jeor × activity (1.35 · 1.5 · 1.7 · 1.9)
offset      = weight kg × pace × 7,700 ÷ 7    // pace −0.5 % lose, +0.25 % gain, 0 maintain
calories    = maintenance + offset, rounded to 10; never below 1,200 (women) or
              1,500 (men, prefer not to say), nor below protein + fat calories
basis       = the lower of goal weight and the BMI 25 weight
              (Maintain: the lower of current weight and the BMI 25 weight)
protein     = 1.6 g per kg of basis
fat         = 0.8 g per kg of basis (0.9 when gaining)
carbs       = what is left
```

**Saved, not computed on read.** Saving the numbers is what stops weigh-ins, Apple
Health syncs and future formula changes from moving a target the user did not touch.
Only the current plan and targets are stored — no history, which is what made the
pace check huge. Past days show against the current targets; accepted.

**The maintenance estimate may be shown, as an estimate.** "About 2,420 kcal a day
to stay at your weight": rounded, dotted, never called "burn", never updated from
food logs or weigh-ins. A number that claims to measure what this person burns is
still out.

**Safety limits.** Age 18 or over. No goal weight below BMI 18.5, and no *Lose fat*
for anyone already below it.

**Citations owed under 1.4.1**, on the Sources screen in Step 4b: the pace (NHS
0.5–1 kg and CDC 1–2 lb a week for losing; Iraki 2019 for gaining), the activity
table (FAO/WHO/UNU 2004), protein (Morton 2018, Leidy 2015), the calorie floor and
the BMI limits. Self-weighing is already cited from 4a.

`weightKg` stays on `UserProfile` as the current value, for display; `weighIns` is
the history. `EditWeightSheet` writes both.

### 5. Meal explanations and daily progress

The meal detail explains estimated ingredients, quantities and preparation so the
user can correct their version. Daily totals show progress against saved targets.
The numeric meal rating and its explanatory UI were removed on 22 September; they
do not serve a clear decision in this launch experience.

### 6. Monetisation

| | Now | Proposed |
|---|---|---|
| Monthly | $5.99 | $7.99 |
| Yearly | $49.99 | $54.99 |
| Trial | 3 days | **14 days** |
| Entitlement | `ai_scans` | `ai_scans` — unchanged, closed |

> **Decided 11 September: launch ships the "Now" column.** $5.99 / $49.99, 3-day
> trial. The "Proposed" column is **deferred, not rejected** — the reasoning below
> still stands, the timing does not. Revisit after approval, when there are
> conversion numbers to argue with instead of benchmarks. `build-order.md` Step 0
> is where this is locked; Step 9's items 2 and 3 are struck through accordingly.

The original case for 14 days was that the weekly page needed two weeks of
weigh-ins before it could show anything. That case is gone (17 September): the plan
shows its value in onboarding, before the paywall. What remains is the benchmark —
sub-4-day trials convert at a median of ~25.5 % against ~42.5 % for 17–32 days (see
the strategy doc) — a conversion argument to test after approval, not a product
constraint.

**Step 1 is complete:** trial copy comes from StoreKit. Verify it against the
configured offer before submission; the launch trial remains three days.

Pricing is lower than the $9.99 in the strategy doc because dropping the lifting
surface means anchoring against Cal AI ($2.49) and Yazio rather than MacroFactor
($11.99). Costs ~20–30 % ARPU; bought back in reach, which is the binding
constraint while the listing shows "insufficient ratings to display".

Grandfather existing subscribers.

**Cost action:** use existing telemetry to measure text, photo, correction and
failure costs per completed meal. Compare cheaper image models on documented
examples before switching. At $49.99/yr and a 15% commission, the monthly equivalent
is about $3.54 before other costs; the quota alone does not prove the actual margin.

### 7. Additional retention surfaces — after approval

State-aware reminders and widgets remain after approval. Onboarding opt-in and
HealthKit body mass are complete and ship with the revamp. The core meal reuse
experience remains required for launch. `build-order.md` owns timing.

**Reminders that read the app's state.** The `ReminderService` note under *Noted,
not scheduled* is now scheduled. Two halves, split across the launch boundary:

- **Step 3a, complete.** Onboarding offers notification opt-in. This enables
  reminders; it does not implement Step 12's state-aware suppression. Launch copy
  must not promise suppression before that behavior ships.
- **Step 12, after approval.** Local notification content is fixed at *schedule*
  time and a Notification Service Extension only intercepts push — so intelligence
  means rescheduling on every state change, not deciding late. Ranked: a weekly
  weigh-in nudge, streak protection, and suppressing a nudge when the window
  already has an entry.

**HealthKit, body mass only — `Step 13`, done early as Step 4a2.** Read
`HKQuantityTypeIdentifier.bodyMass` into `weighIns`, whose `source` field already
anticipates it. This feeds the Weight screen directly: a user with a smart scale
can contribute weigh-ins without typing them. Measure weight engagement alongside
food reuse. **Read only — no write
back**, so `NSHealthShareUsageDescription` is the only usage string. Request the
one type, with a purpose string naming the actual use.

**Widgets — `Step 14`.** The passive half of the loop. The app writes a small
`TodaySnapshot` to an App Group container on every timeline change; the widget
reads that and nothing else. **No Firebase in the extension** — a widget process
reaching Firestore means its own auth, a cold start and a read per refresh. Tap is
a `widgetURL` deep link. Read-only, so no App Intents are required.

---

## Distribution

Free channels only. No paid acquisition until a funnel converts — paid is the
amplifier Cal AI reached *after* creators got them to ~$2M/month, never the engine.

| Channel | Cost | Needs |
|---|---|---|
| Share cards | $0 | Step 7, after meal editing |
| Nano-creator seeding, gifted codes | ~$0 | 20–50 creators, 1k–10k followers |
| Own account — failure demos | $0 | Nothing; the demos exist today |
| Long-tail ASO | $0 | Listing rewrite |
| Comparison-site listings | $0 | Outreach |

**Demonstrate the user's meal and its correction.** Screenshot 1 follows the
revised copy deck: "Understand the food you actually eat." Do not use unverified
competitor result counts or blanket claims that other apps cannot explain food.
Creator conversations can begin before the share card is built.

Sequencing matters more than any single channel: each engine only starts once the
previous one has proven the funnel converts.

---

## Sequence

`build-order.md` is the source of truth. Its step numbers replace the older phase
sequence; one public release still permits focused TestFlight checks beforehand.

| Steps | Scope | Gate |
|---|---|---|
| **0–4** | Decisions, trial copy, design kit, exercise removal, notifications, HealthKit body mass, targets and weight plan | Complete |
| **5** | Meal contract, editable client, visible assumptions | Agree schema before implementation |
| **6** | Backend, documented references, saved-version round trip | Shared contract with Step 5 |
| **7** | Remaining visual sweep and final share card | Final meal presentation |
| **8–10** | Rename, metadata, launch checks, screenshots, submission | Promises agree with working behavior |
| **11–14** | CPPs/outreach, state-aware reminders, widgets | After approval; Step 13 already completed as 4a2 |

### Earlier exercise/dead-code audit — reference only

The following list came from `product-as-built.md` before completed Step 3.
Do not treat it as new work or remove code without checking its current callers:

- `MainTabGradientBackground` (`Extras/MainTabGradient.swift:3`) — no call site.
- `SavedMeal.lastUsedAt` — declared, encoded, decoded, never written.
- `SavedMealsViewModel.isSavedMeal(name:description:macros:)` and
  `fingerprint(for:)` — no caller; duplicate detection is not wired to any UI.
- `LogEntryDetailSheet.onSaveMeal` (`:16`) — never passed, never invoked.
- `MealImageInterpretationError.unsupported` — unreachable protocol default.
- `POST /api/log-entry/analyze` (`src/routes/logEntryRoute.js:263`) — fully
  implemented, auth-guarded, quota-metered, called by nothing. **Decide: delete,
  or wire up.** It is the only route returning `analysisMeta`.
- `analysisMeta` — built for every analysis, then discarded by both live routes.
  `model` and `promptVersion` are logged to stdout and never persisted, so no
  stored entry can be traced to the prompt version that produced it. Worth
  persisting before the prompt starts changing every week.

---

## Explicitly out of scope

- A `foods` collection, barcode scanning, or a searchable nutrition database.
  Documented portion/ingredient references for estimates remain in scope.
- Sets, reps, load, progression, or anything resembling a training log.
- Social, feed, friends, coach marketplace.
- Urdu or Hindi App Store localisations.
- **Renaming the `ai_scans` entitlement.** The one migration-shaped constraint that
  survives the empty Firestore — it is about builds in the wild, not stored rows.
- ~~Renaming `GoalType` raw values~~ — no longer prohibited, just not worth doing
  on its own. See §1.
- ~~Migrating historical `logEntries` values~~ — there is no
  history to migrate. See §3.
- **HealthKit active energy, workouts, or steps** — as an input *and* as displayed
  context. Decided 7 September, reasoning revised 14 September. The Weight screen
  reads the scale, and the scale **already reflects every calorie the user
  burned** — measured, not estimated. An imported burn figure has only one way in:
  raising the target on active days. That is the calorie rebate of §3 arriving
  through a door marked "more accurate", on a worse number — Apple Watch active
  energy runs ±20–30 %. HealthKit is `bodyMass`, read-only, and nothing else.
- **Coaching, suggested target changes, or rules judging progress.** An expenditure
  engine, phases with check-ins, and a weekly page were each tried and dropped by
  17 September (§4). Targets change only when the user acts.
- **App Intents, Siri, Shortcuts, and Control Center controls.** Decided
  7 September — too much lift for this stack. Widgets do not need them: a
  read-only widget uses a `widgetURL` deep link, and only in-widget buttons would
  require an intent. Revisit if Apple Intelligence surfaces start mattering for
  discovery.
- **Push notifications and APNs.** Parked, not rejected — there is no push
  entitlement today and Step 12 does not need one.

---

## Noted, not scheduled

- ~~**Reminders are timeline-blind.**~~ **Now scheduled** — §7 above, and
  `build-order.md` Steps 3a and 12. The diagnosis held: `ReminderService` fires
  fixed wall-clock times from a three-mode enum and never reads the timeline. The
  thing it missed is that the mode defaults to `.quiet`, so the reminders were not
  merely dumb, they were off.
- **`SavedMealsPickerSheet` is unreachable on older days.** It hangs off the
  `LogActionDock` bookmark button, which hides outside the today−7d…today window.
- **Saved meals losing their explanation is now scheduled.** Steps 5–6 preserve
  corrected meal snapshots and their assumptions/provenance. This does not require
  a foreign-key relationship or automatic learning across unrelated meals.

---

## Open decisions

1. ~~**The app name.**~~ **Closed 8 September — `Circa: Food & Calorie Journal`,
   subtitle `AI macro tracker, no weighing`.** Full reasoning and the competitive
   check are in `store-copy.md`. Two follow-ups it created:
   - **Trademark, unresolved.** Circa Lighting, Circa Resort & Casino and Circa
     Sports are real companies. The App Store name is clear — a registered mark is
     a separate question. **Run a USPTO search on classes 9 and 42 before
     submitting.** Owner: Ahmad.
   - **Keywords are stale.** The agnostic name means `desi` now appears nowhere in
     the listing, and `macros` duplicates the subtitle's *macro*. Proposed fix is in
     `store-copy.md` under Keywords, awaiting sign-off.
2. **Cuisine scope is closed.** Broad brand, specific launch examples; see Step 0
   and Step 6 in `build-order.md`. No rename or single-cuisine restriction.
3. ~~**Meal schema details.**~~ **Closed 21 September — `meal-contract.md`.** The
   payload, persistence, contribution, provenance and correction rules Steps 5 and
   6 share. Changing it is a two-repo edit; neither step may change it alone.
4. **`/api/log-entry/analyze`** — inspect compatibility/callers during Step 6 before
   deciding whether this older audit item still needs action.

---

## Risks carried

- **Distribution is the binding constraint and this brief barely touches it.**
  Free channels only, as above.
- **Regional economics need measurement.** Diaspora is promising, while local
  free competitors create price pressure. Measure proceeds and inference use per
  cohort instead of declaring the home market unprofitable in advance.
- **The niche is not empty — and it is filling faster than this brief assumed.**
  Measured against the App Store on 8 September, the desi calorie set is now at
  least six apps: MasalaFit (8 ratings, May 2026), Kalorist (4), Calorify (2,
  July 2026), Khana AI (0, July 2026), RotiCal (0), MyFitFoods (1, September 2026).
  Three launched in the last four months. HealthifyMe (40M users, 12-year database)
  remains a genuine moat: another reason to aim diaspora, not India.

  **But nobody has won it.** Every entrant is under ten ratings, and on searches
  like "roti calories" and "biryani calories" a **zero-rating app currently ranks
  first**. The window is open and closing at the same time — whoever reaches ~50
  ratings first takes those terms. This argues for shipping sooner, not for
  abandoning the angle.
- **Founder knowledge is useful but bounded.** Ahmad's Pakistani food experience
  and TestFlight feedback support the launch examples. Broader cuisine accuracy,
  paid retention still needs evidence.

---

## Success criteria

Directional, not forecasts. The install→paid figure is benchmark-derived, not
measured — there is no funnel to measure yet.

- **Before submission:** text/photo → inspect → correct → save → re-log works,
  totals reconcile, and the assumptions match the editable breakdown.
  Existing TestFlight users can confirm the changed interaction; no new broad
  discovery study blocks launch.
- **After launch:** measure first successful meal, correction completion, repeat
  logging, saved-meal reuse, trial-to-paid and cost per completed meal. Reuse
  existing telemetry and add only the events needed for gaps. A creator post and
  a share-card export are distribution activity, not proof of retention.
- **Weight engagement:** track second weigh-ins alongside food reuse rather than
  treating them as the sole measure of value.
- **12–18 months:** ~2,000 active subscribers ≈ $10k MRR at ~$4.80 blended net.
  At ~9 % install→paid that is ~30k downloads cumulative, and ~1,400/month
  sustained to hold against churn.

---

## References

- Strategy: https://claude.ai/code/artifact/c0da5757-5f1f-47f4-9d75-78672c32f2f3
- Store copy: https://claude.ai/code/artifact/a9621d21-e776-4ce9-b8a6-8c3c91803065
- `product-as-built.md` — schema-derived product description
