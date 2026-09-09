# LiftEats — Repositioning Brief

Working contract for the repositioning. The *argument* for it lives in the strategy
doc and copy deck (see References); this file is the implementation scope only.

Written 6 September 2026, revised 7 September. Supersedes any earlier paywall-pass scope; the
remaining subscription work is Step 1 of `build-order.md`.

---

## The decision, in one paragraph

LiftEats currently positions as an AI calorie tracker and monetises inference —
the entitlement is literally `ai_scans`. That is Cal AI's business at Cal AI's
price, without Cal AI's distribution. We reposition onto the one thing our
architecture is structurally better at than any competitor: **we have no food
database, so we can estimate food that isn't in anyone's database.** Home-cooked,
regional, mixed, unmeasured food. Goal-driven users stay the paying audience —
adaptive targets, phases, goal-fit scoring all remain — but **lifting comes off
the surface**: out of the name, out of the subtitle, out of the primary copy.
Lifters become one subset of the audience rather than the whole of it.

---

## Positioning

**Thesis.** Every calorie app is a database of packaged food. Most of what people
actually eat isn't in one.

**Beachhead.** South Asian / desi home cooking, targeted at the **diaspora**
(US, UK, Canada, Gulf App Store accounts) — not the home market. Inference cost is
dollar-denominated and local-market App Store revenue is not; see Risks.

**Retention.** Adaptive targets that move with the user's real weight trend. This
is why they stay past week six and why they pay more than $2.49.

**Why this positioning, given four apps say something similar.** Not because it is
unownable by others — in a market where an AI-coded competitor ships a matching
feature in a week, defensibility is not on the menu at our size. It is chosen
because it is the angle that **distributes**: filmable, searchable, and adjacent
to creator communities that exist. calog.cc shares the pitch but is web-first —
not in App Store search, not in the listicles, no iOS push. Calorify is the real
benchmark, and the lesson there is distribution and a free tier, not the pitch.
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

**Do not add Urdu or Hindi localisations.** That acquires precisely the users who
cannot cover our inference cost. Custom per-storefront pricing exists, but a
100 PKR/month subscription (Calorify's price) cannot fund a `gpt-5.4` vision call
at any volume — price segmentation does not rescue the home market.

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

### 2. The food wedge — `Phase 1`

- **Share card.** Render an entry — image, title, macros, goal-fit score, the
  one-line explanation — as a shareable image. The app currently has no sharing,
  no export, no invite, no referral. This is the only viral surface we have and it
  does not exist.
- **Surface `assumptions[]` on the timeline card**, not one tap deep in
  `LogEntryDetailSheet`. "Assumed 2 tbsp ghee · tap to change". This is the
  product's whole personality and it is currently hidden.
- **Portion reference set.** Household measures the databases don't hold — katori,
  medium roti vs paratha, a "plate" of biryani, home-cooking oil quantities. A
  JSON file plus prompt instructions in the AI service. Start at 100–200 dishes we
  can verify. **Not** a `foods` collection — do not build a database.
- **Split multi-item text entries.** One sentence → several entries. Schema and
  prompt change in the AI service; `LogComposerViewModel` currently creates one
  entry per submission.

### 3. Exercise — minimal now, deletion later

Decided 7 September, replacing the earlier "demote to context". Once lifting is
off the surface, exercise logging has no remaining job:

- Adherence context is decoration in the check-in, not an input to it.
- Explaining weight variance was overstated — variance is dominated by water,
  sodium, carbs, glycogen and cycle, and the log cannot distinguish "trained
  harder" from "ate more salt".
- The calorie rebate at `DailyMacroDetailSheet.swift:12`
  (`target - consumed + burned`, with a "Burned" tile at `:31`) actively
  **corrupts the adaptive engine**: eaten-back calories raise `meanDailyIntake`
  without moving weight, so measured expenditure drifts upward and compounds
  weekly. The rebate and the engine are mutually exclusive.

Deleting it removes a cost centre with zero revenue attached — every exercise log
burns an AI call for a number nothing will read.

**Do the two-line version now; defer the sweep.** The full removal touches 26
Swift files and 3 AI-service files — a whole cycle. It is not worth blocking the
listing on. Ship only:

1. Remove the rebate at `DailyMacroDetailSheet.swift:12`
   (`target - consumed + burned`) and the "Burned" tile at `:31`. **This is the
   part that matters** — eaten-back calories corrupt the expenditure maths later.
2. Stop offering workout logging in the composer. Leave the code in place.

Everything below is the deferred sweep, scheduled after the listing ships.

**Deferred scope: 26 Swift files, 3 AI-service files.** `ExerciseEstimate`, the 11-case
activity enum, `estimatedCalories`, the calories-burned mode in
`ManualMacroEditSheet`, the Burned tile, `workoutLogsThisWeek`, `caloriesBurned`
in `DailyStatsSnapshot`, `StatsActivitySummaryRow`, the exercise branch in
`normalizeLogEntryFeedback`, and the exercise rules in `logEntryPrompt.js`.

**Two things that are not free:**

- ~~**Existing entries.**~~ **No longer a constraint.** `type: food|exercise`
  discriminates the shared `logEntries` collection, and the plan was to keep
  `LogEntryType` and the *read* path so historical entries still render. Firestore
  has no documents, so there is nothing to render: delete the read path with the
  write paths, in one pass, owing no later cleanup.
- **`NonTrainingActivityLevel` stops making sense** — it is named "non-training"
  precisely because training was counted separately. Rename to activity level.
  Low stakes: under the adaptive engine the multiplier is only a **seed** for the
  first 2–3 weeks, after which measured expenditure supersedes it.

Also removed: the sets ask at `OnboardingLoggingTipsStepView:133` and the "22
total sets" worked example at `:42`.

Audit finding #4 (bodyweight never reaches the burn estimator) is **closed as
obsolete**, not fixed.

### 4. The adaptive engine — `Phase 3`

The spine. Three new Firestore collections and one calculator, no network calls,
no inference cost.

```
users/{uid}/weighIns/{yyyy-MM-dd}
  weightKg, loggedAt, source: manual | healthKit

users/{uid}/phases/{phaseId}
  goalType, startedAt, endedAt?, startWeightKg,
  goalRatePercentPerWeek, targetWeightKg?

users/{uid}/checkIns/{weekStart}
  weekStart, trendWeightKg, trendDeltaKgPerWeek,
  estimatedExpenditure, avgIntakeCalories, adherenceDays,
  previousTargets, newTargets, reason
```

```
trend[n]         = alpha * weight[n] + (1 - alpha) * trend[n-1]   // alpha ~0.25
expenditure      = meanDailyIntake + (trendDeltaKg * 7700) / daysInWindow
desiredKgPerWeek = trendWeightKg * (goalRatePercentPerWeek / 100)
targetCalories   = expenditure - (desiredKgPerWeek * 7700 / 7)
```

Replaces the flat offsets in `MacroTargetCalculator.swift:56-65` (`+250` gain,
`-300` cut) with rates that scale to bodyweight:

- Gain — 0.25–0.5 % bodyweight/week
- Lose fat — 0.5–1.0 % bodyweight/week
- Maintain — hold trend weight in a ±0.5 kg band

`weightKg` stays on `UserProfile` as the current value; `weighIns` becomes the
history. `EditWeightSheet` writes both.

### 5. Day-aware goal-fit score — `Phase 4`

`scoreFoodLog({ goal, macros, confidence })`
(`gymfuel-ai-service/src/scoring/logEntryScoring.js:432`, called from
`normalizeLogEntryFeedback.js:159`) sees one meal in isolation. It does not
receive the day's running totals, the day's remaining allowance, the user's
targets, or anything else. A 900 kcal meal is capped the same whether it is the
user's first food of the day or their fourth.

**The design consequence, which is forced rather than chosen:** a score that
depends on day state *cannot* be frozen at log time, because day state keeps
changing after the entry is written. Day-aware therefore implies **computed on
read**, which implies **client-side**. Scoring is pure arithmetic — no AI call —
so this is a port of ~470 lines of JS to Swift, not a redesign.

`goalFitScore` stops being a stored field on `feedback` and becomes derived from
stored macros + current day state + current goal.

That one change closes three separate flags at once:

- **Frozen at log time.** `goalType` is stamped client-side at log time and
  nothing recomputes when the user later changes goal.
- **Saved meals have no score.** `logSavedMeal` writes `goalFitScore: nil`, so a
  re-logged meal silently drops out of every score-based surface while still
  counting toward macros. Derived scoring fixes this for free.
- **Score has no day-level or week-level rollup.** Once it is derived, a day
  score is just the same function over the day's totals.

Historical entries need no migration — macros are stored, so any past entry can
be scored fresh. Ignore the stored `goalFitScore` rather than reading it back.

The AI service keeps `scoreFoodLog` until the Swift port is verified against it,
then the server-side call is removed from `normalizeLogEntryFeedback`.

### 6. Monetisation

| | Now | Proposed |
|---|---|---|
| Monthly | $5.99 | $7.99 |
| Yearly | $49.99 | $54.99 |
| Trial | 3 days | **14 days** |
| Entitlement | `ai_scans` | `ai_scans` — unchanged, closed |

The trial length is a product constraint, not a benchmark: an adaptive coach
cannot demonstrate itself before the first check-in. The trial must span at least
one, ideally two.

**Changing the trial length makes the hardcoded trial string blocking.**
`SubscriptionPaywallSheet.swift:351,364,379` renders `"3-day"` as a literal
instead of reading `package.storeProduct.introductoryDiscount`. Fix it in Step 1 — if the App Store Connect intro offer says 14 days and the
paywall says 3, that is a 3.1.2 metadata-mismatch rejection.

Pricing is lower than the $9.99 in the strategy doc because dropping the lifting
surface means anchoring against Cal AI ($2.49) and Yazio rather than MacroFactor
($11.99). Costs ~20–30 % ARPU; bought back in reach, which is the binding
constraint while the listing shows "insufficient ratings to display".

Grandfather existing subscribers.

**Cost action:** move image analysis off `gpt-5.4`
(`gymfuel-ai-service/src/ai/imageRecognizer.js:27`). At $49.99/yr the net is
$3.54/mo against a 500-scan quota; a heavy annual subscriber is near break-even
before infrastructure.

### 7. Retention surfaces — `Phase 6`, after approval

Added 7 September. Three features, held back deliberately: each adds a new target,
a new entitlement or a new review surface, and none of them helps a listing with no
installs. Detail and sequencing live in `build-order.md` steps 12–14.

**Reminders that read the app's state.** The `ReminderService` note under *Noted,
not scheduled* is now scheduled. Two halves, split across the launch boundary:

- **Step 3a, in the launch build.** Reminders default to `.quiet` and the
  permission ask is buried in Settings, so effectively nobody has them. An
  onboarding opt-in fixes a leak; intelligence added to a feature nobody switches
  on is worth nothing. It also makes the "Smart reminders" line already on the
  paywall (`SubscriptionPaywallSheet.swift:25`) true rather than aspirational.
- **Step 12, after approval.** Local notification content is fixed at *schedule*
  time and a Notification Service Extension only intercepts push — so intelligence
  means rescheduling on every state change, not deciding late. Ranked: the weekly
  check-in nudge, streak protection, and suppressing a nudge when the window
  already has an entry.

**HealthKit, body mass only — `Step 13`.** Read
`HKQuantityTypeIdentifier.bodyMass` into `weighIns`, whose `source` field already
anticipates it. This attacks the engine's weakest link directly: a user with a
smart scale contributes every weigh-in after the first without opening the app,
and Phase 3's success criterion is a second weigh-in. **Read only — no write
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
| Share cards | $0 | Phase 1 |
| Nano-creator seeding, gifted codes | ~$0 | 20–50 creators, 1k–10k followers |
| Own account — failure demos | $0 | Nothing; the demos exist today |
| Long-tail ASO | $0 | Listing rewrite |
| Comparison-site listings | $0 | Outreach |

**Screenshot 1 stays "aloo gobi", not "mutton kunna".** Reverted 7 September.
"No results for kunna" is falsifiable by a single user submission — MyFitnessPal
carries ~20M user-added entries — which makes it a trust risk and an accurate-
metadata risk sitting permanently in the listing. "Forty results, 80–400 calories"
is always true, because it is a claim about variance rather than absence, and it
makes the sharper point anyway: too many wrong answers is worse than none.

Sequencing matters more than any single channel: each engine only starts once the
previous one has proven the funnel converts.

---

## Sequence

| | Scope | Gate |
|---|---|---|
| **0** | Read the trial length from StoreKit on the paywall | Ships with everything else |
| **1** | Share card · assumptions on the card · multi-item split · portion set · remove the calorie rebate | Needs the name decision |
| **2** | App Store Connect: listing rewrite, cross-localization, Custom Product Pages | Needs Phase 1 screenshots |
| **3** | Weigh-ins, trend weight, adaptive targets, weekly check-in | The spine |
| **4** | Day-aware goal-fit score | After 3 |
| **5** | Exercise sweep + dead code | Any time after 1 |
| **6** | State-aware reminders · HealthKit body mass · widgets | After approval |

The onboarding notification opt-in is the one piece of Phase 6 that ships with the
listing — `build-order.md` Step 3a. It is a leak, not a feature.

Phase 2 is the largest distribution lever we have and costs no engineering — 70
Custom Product Pages and up to 1,440 indexable characters across ten US-indexed
locales. Details in `store-copy.md`. Budget four weeks after any keyword change
before rankings settle.

Phase 1 before the engine deliberately: it is cheap, testable as content the week
it ships, and answers "does anything pull" before we spend two months building.
**Phase 1 must ship before the listing goes live** — the copy promises
assumptions-on-card and multi-item logging, and neither exists yet.

The rebate removal moves into Phase 1 because it is two lines and it protects the
expenditure maths; the rest of the exercise deletion waits until after the listing
is live.

### Phase 5 — exercise sweep and dead code, enumerated

From `product-as-built.md`, all verified as unreferenced:

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

- A `foods` collection, barcode scanning, or any nutrition database. The absence
  of one is the differentiator.
- Sets, reps, load, progression, or anything resembling a training log.
- Social, feed, friends, coach marketplace.
- Urdu or Hindi App Store localisations.
- **Renaming the `ai_scans` entitlement.** The one migration-shaped constraint that
  survives the empty Firestore — it is about builds in the wild, not stored rows.
- ~~Renaming `GoalType` raw values~~ — no longer prohibited, just not worth doing
  on its own. See §1.
- ~~Migrating historical `logEntries` or `goalFitScore` values~~ — there is no
  history to migrate. See §3.
- **HealthKit active energy, workouts, or steps** — as an input *and* as displayed
  context. Decided 7 September. Expenditure is derived as
  `meanDailyIntake + (trendΔkg × 7700) / days`, which **already contains every
  calorie the user burned**, measured from the scale rather than estimated. An
  imported burn figure either double-counts it or replaces a measured number with a
  worse one — Apple Watch active energy runs ±20–30 %. This is the calorie rebate
  of §3 arriving through a door marked "more accurate". HealthKit is `bodyMass`,
  read-only, and nothing else.
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
- **Saved meals are severed from their origin.** `SaveLoggedMealSheet` drops
  `estimatedItems`, `assumptions`, `confidence`, `rawInput` and the image; there
  is no foreign key either direction. Partly resolved by derived scoring (Phase 4).

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
2. **Beachhead cuisine.** Brief assumes desi. Swap is mechanical — dish names,
   keywords, portion set — if a different community fits better. Thesis and
   structure are unchanged either way. **Lower stakes now than when this was
   written:** the name no longer encodes a cuisine, so a swap costs keywords and
   screenshots rather than a rename.
3. **`/api/log-entry/analyze`** — delete or wire up (Phase 5).

---

## Risks carried

- **Distribution is the binding constraint and this brief barely touches it.**
  Free channels only, as above.
- **Diaspora targeting is load-bearing.** In-region App Store revenue will not
  cover dollar-denominated inference. If acquisition skews to the home market the
  unit economics invert.
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
- **Founder-audience fit degrades.** Ahmad is a lifter and writes for lifters
  instinctively. Writing for general home cooks is a different muscle, untested.

---

## Success criteria

Directional, not forecasts. The install→paid figure is benchmark-derived, not
measured — there is no funnel to measure yet.

- **Phase 1:** listing live, share card shipped, ≥1 nano-creator post published.
  Watch install→trial rate, not installs.
- **Phase 3:** ≥40 % of trialists log a second weigh-in; ≥1 check-in reached
  before trial end.
- **12–18 months:** ~2,000 active subscribers ≈ $10k MRR at ~$4.80 blended net.
  At ~9 % install→paid that is ~30k downloads cumulative, and ~1,400/month
  sustained to hold against churn.

---

## References

- Strategy: https://claude.ai/code/artifact/c0da5757-5f1f-47f4-9d75-78672c32f2f3
- Store copy: https://claude.ai/code/artifact/a9621d21-e776-4ce9-b8a6-8c3c91803065
- `product-as-built.md` — schema-derived product description
