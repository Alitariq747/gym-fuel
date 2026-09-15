# Build Order

One ship, not six. The phases in `project-brief.md` are an ordering of *work*, not
of releases — everything below goes out in a single binary and a single App Store
submission.

That changes the sequencing rule. Nothing here is ordered by "what's cheap to test
first", because nothing reaches a user until all of it does. It is ordered by
**hard dependency** and **discover-problems-early**.

---

## The critical path

```
decisions ──► all UI work ──► screenshots ──► submit ──► approval ──► CPPs
```

**Screenshots are the long pole.** They cannot be shot until the UI is final, and
nothing can be submitted until they exist. Every step before them is really a race
to unblock a photoshoot.

**The redesign is inside this sequence, not beside it.** The app is being rebuilt
visually as well as functionally — the whole system is specified in `design.md`
and drawn on the canvas linked there. It threads through in three parts, and the
ordering is not optional:

1. **Step 2a lands the tokens first**, so no screen is ever built twice.
2. **Every step after it builds its own screens in the new language.** Steps 3,
   3a, 4, 5 and 6 each touch or create surfaces; each one ships them looking
   like `design.md`, not like the current build. This is not extra scope on those
   steps — it is the same work done once instead of twice.
3. **Step 7a sweeps the screens no other step rebuilds** — auth, settings, the
   saved-meal sheets, the explainers. It is the last thing before screenshots
   because it is the last thing that changes what a screenshot shows.

Do not schedule "the redesign" as a phase. There isn't one.

**Custom Product Pages come after approval.** They need no build and get their own
review, so they are genuinely post-launch work — but they need the new screenshots,
so they cannot start early either.

**Retention work comes after approval too.** Steps 12 and 14 each add a new target
or a new review surface, and neither helps a listing with no installs. Retention
matters once there is someone to retain. Two exceptions ship in the launch build:
Step 3a, which is a leak, not a feature, and Apple Health body mass (Step 13),
pulled forward into 4a2 because it feeds the pace check.

---

## Progress

Tick each step as it lands. **This is the source of truth for where we are** — a
fresh session reads this file, not the chat history.

- [x] **0** · Decisions — name, cuisine, pricing
- [x] **1** · Paywall: trial length from StoreKit
- [x] **2** · Vocabulary
- [x] **2a** · Design system — `CircaTheme.swift` + the component kit
- [x] **3** · Remove exercise and lifting logic
- [x] **3a** · Notification opt-in in onboarding
- [x] **4a** · Adaptive engine, part one — weigh-ins and the trend
- [x] **4a2** · Apple Health body mass → `weighIns`
- [x] **4b1** · The trend and the seeder — expenditure pieces removed
- [x] **4b2** · Pick a pace — onboarding, Settings, starting targets
- [x] **4b3** · Phases and the pace rule
- [ ] **4b4** · The weekly check-in
- [ ] **5** · Food wedge, client
- [ ] **6** · Food wedge, backend
- [ ] **7** · Day-aware goal-fit score · *first to cut*
- [ ] **7a** · Visual sweep — the screens no other step rebuilds
- [ ] **8** · Rename
- [ ] **9** · App Store Connect metadata
- [ ] **10** · Screenshots and submit
- [ ] **11** · After approval — CPPs, creator outreach
- [ ] **12** · State-aware reminders · *post-approval*
- [x] **13** · HealthKit body mass — done early as 4a2
- [ ] **14** · Widgets · *post-approval*

Work on `main`. **You commit each step yourself, in Xcode** — no step branches,
and nothing here commits on your behalf. Fresh session for the next step.

---

## The data is empty — what that does and does not relax

**Confirmed 7 September 2026: Firestore holds no user documents.** Several
constraints in these docs exist only to protect existing data. Those relax. Two
notes before anyone gets enthusiastic:

- **This has an expiry date.** It is true until the first real user, which is the
  point of the whole build. Anything on this list is *change it before launch or
  not at all*.
- **It does not extend to `ai_scans`.** That rule is about **builds in the wild**,
  not stored rows — entitlement lookup happens client-side against RevenueCat, so
  an install on an older build breaks on a rename whether or not Firestore has a
  document for that user. And a TestFlight tester who installed but never finished
  onboarding would leave no `users/{uid}` document at all, so an empty collection
  is not proof that no such install exists. **Keep `ai_scans`. Decided, closed.**

What relaxes: the `GoalType` raw values, the `logEntries` read path in Step 3, and
migrating historical `goalFitScore`. Each is marked at its own site below.

---

## Step 0 — Your decisions · **closed 11 September**

All three are made. Nothing downstream is waiting on you any more.

| Decision | Note |
|---|---|
| ~~**App name**~~ | **Done 8 September: `Circa: Food & Calorie Journal`** (29/30), subtitle `AI macro tracker, no weighing` (29/30). App Store name verified clear. **Still owed: a USPTO search on classes 9 and 42**, and the handles. Neither blocks a build. |
| ~~**Beachhead cuisine**~~ | **Decided 11 September: there is no single beachhead — the product is cuisine-agnostic.** Cuisines are *lanes*, not an identity: the default listing carries none in particular, and a cuisine reaches its audience through its own Custom Product Page in Step 11. The name and subtitle were already agnostic, so nothing about them changes. What does change is **Step 6's portion reference set**, which spreads across cuisines instead of being 200 desi dishes. |
| ~~**Confirm pricing**~~ | **Decided 11 September: unchanged — $5.99/mo, $49.99/yr, 3-day trial.** The $7.99 / $54.99 / 14-day move in `project-brief.md` §6 is **deferred, not rejected**; revisit after approval. This is what closes Step 9's items 2 and 3 and takes the urgency out of Step 1. |

---

## Step 1 — Paywall: the trial string · S

One change, one file, and it is genuinely blocking.

Read trial length from `package.storeProduct.introductoryDiscount` instead of the
hardcoded `"3-day"` at `SubscriptionPaywallSheet.swift:351,364,379`. Nothing in
that file currently references `introductoryDiscount` or `subscriptionPeriod` —
`isEligibleForTrial(package)` reports *whether* a trial exists, never how long.

**Files** `SubscriptionPaywallSheet.swift`

**Done when** the paywall renders the trial length from StoreKit alone, with no
trial length literal anywhere in the file. With the offer frozen at 3 days it
should still read "3-day" — but read, not typed.

> **Still not cut — but no longer urgent.** Step 0 froze the trial at 3 days, so
> the literal and the configured offer now agree and the 3.1.2 rejection risk is
> gone for this submission.
>
> It stays in for two reasons. `CLAUDE.md` forbids a hardcoded trial length
> outright, and the risk comes back **silently** the day the offer changes — by
> which point nobody remembers there is a string to update. It is an S. Pay it now.

The rest of the subscription layer was re-verified against the codebase on
7 September and needs no work: entitlement checks, restore, price rendering, the
required disclosures, launch and foreground refresh, and the AI gating all hold.

---

## Step 2 — Vocabulary · S

Small and mechanical. Do it first so everything after uses the new names.

- `GoalType.displayName` → **Gain / Lose fat / Maintain**; `GoalType.detail` copy
  drops the lifting register.
- `GoalType.symbolName` returns `figure.strengthtraining.traditional` for
  `.leanBulk` (`GoalType.swift:44`) — a barbell glyph on the goal picker. It is
  user-facing gym vocabulary and was not in the original scope of this step.

**On the raw values — the constraint is gone, the recommendation is not.** With an
empty Firestore they are safe to change (see above). But changing them is a
two-repo edit and it only pays for itself as part of a larger one:

`goal.rawValue` is what reaches the AI service
(`BackendLogInterpretationService.swift:121`), and the prompt hard-codes the
tokens — `logEntryPrompt.js:55` instructs *"Use the exact goal values lean_bulk,
maintain, or cut"*, and `:76` frames `lean_bulk` as *"carbs that support training
and recovery"*. So the lifting register is not merely internal: it is in the
model's reasoning frame on every estimate, which is a repositioning problem the
display strings do not touch.

The fix for that is the **prompt language**, not the token. Rename the raw values
only if you are already editing those prompt lines — `logEntryRoute.js:36`,
`logEntryPrompt.js:55,76,98` and six sites in `logEntryScoring.js` — in which case
the token rename is nearly free and keeps the frame consistent. On its own it still
buys nothing. **Not scheduled here; carry it into Step 6.**
- Rename `NonTrainingActivityLevel` → `ActivityLevel`. It was named "non-training"
  only because training was counted separately, which stops being true in Step 3.

**Done when** no goal string in the app reads as gym vocabulary.

> **Dropped from the brief: the `ai_scans` → `pro` entitlement rename.** The
> identifier is what `customerInfo.entitlements[...]` checks. Renaming it in the
> RevenueCat dashboard breaks entitlement lookups for every user still on an older
> build — and old builds live in the wild for months. It is a cosmetic, internal
> change with a real revenue-breaking failure mode. **Keep `ai_scans`.**

---

## Step 2a — Design system · M

**Everything visual after this point depends on it, so it goes before anything
that draws a screen.** Step 3a is the first step that *creates* a surface; if the
tokens are not in place by then, that screen gets built twice.

The system is specified in `design.md` — palettes with computed contrast ratios,
the type pairing, radii, spacing, and the ten rules. This step turns the tokens
into Swift and the repeated shapes into views. It does not redesign any screen.

**Two files.**

~~`CircaTheme.swift`~~ — **done 10 September**, at `GymFuel/Design/CircaTheme.swift`.
Fifteen adaptive colour tokens, the paper gradient, eight fonts, and the metrics.
Read it before writing the kit; it is short, and its doc comments carry the two
rules that constrain everything else — dark is a designed twin rather than an
inversion, and fonts are built on **text styles** so Dynamic Type works without
per-screen effort. The fonts are `.circaTitle`, `.circaEntryTitle`, `.circaRow`,
`.circaBody`, `.circaCaption`, `.circaMono`, `.circaMonoValue`, `.circaMonoLarge`.

`CircaComponents.swift` — **this is what Step 2a still owes.** The primitives
every screen repeats:

- the card, the section label (mono, uppercase, tracked), the hairline
- **the certainty rule** — one modifier with three states: estimated (dotted),
  known (none), pending (the rule alone, nothing above it). Rule 1 in `design.md`,
  and the reason nothing jumps when an estimate lands
- the four button tiers, with the dark-mode inversion of the primary built in
- the macro bar row, the entry row, the restyled `LogActionDock`
- the AX3 behaviour, once, where the row goes vertical — not re-solved per screen

> ### Eight, not twenty
>
> **Extract only what genuinely repeats, or what carries a rule.** Anything that
> appears on one screen stays inline on that screen.
>
> The failure mode here is not under-building. It is wrapping every element in a
> `CircaSomething` until there is an abstraction layer nobody can read and every
> screen is fighting it. Eight components for thirty-three screens is the right
> order of magnitude; twenty is a warning sign.
>
> The certainty rule is the clearest example of what *does* earn a component: it
> is not styling, it is a three-state rule, and thirty call sites implementing it
> by hand means one of them eventually shows a spinner or a zero instead of the
> pending rule — and the whole point, that nothing jumps when the number lands,
> quietly dies.

**Files** new `CircaComponents.swift`. `CircaTheme.swift` already exists. Existing
screens are not touched in this step.

**Done when** a scratch view can be built entirely from the kit, it looks like the
canvas in both themes, and it holds at AX3 without truncation.

> `Color.liftEatsCoral` (`Extras/AppColor.swift`) and the four `Fuel*` colorsets
> are the old system. Leave them until Step 7a — deleting them now breaks every
> screen that has not been rebuilt yet.

---

## Step 3 — Remove exercise and lifting logic · M

**Moved ahead of the engine.** Doing this after launch would leave a dead
subsystem sitting under the feature that replaces it. The weekly weigh-in check-in
*is* the new framing for effort and expenditure; the exercise log is the old one.
Delete the old one before building the new one, so the engine is built on a clean
base and nobody has to reason about which system owns a number.

This is a full sweep, not the two-line version. It is pure deletion, which is the
cheap kind of work and exactly what a coding agent does well in one pass.

**The part that matters most — the rebate.** `DailyMacroDetailSheet.swift:12`
(`target - consumed + burned`) and the "Burned" tile at `:31`. Eaten-back calories
raise `meanDailyIntake` without moving weight, so measured expenditure drifts
upward and compounds every week. **The rebate and the engine cannot coexist.**

**Scope: 26 Swift files, 3 AI-service files.**

- Models — `ExerciseEstimate`, the 11-case activity enum, `estimatedCalories`
- Composer — remove the workout logging path entirely
- Detail — the calories-burned mode in `ManualMacroEditSheet`
- Timeline — the exercise branches in `TimelineEntryRowState`,
  `TimelineEntryLeadingVisual`, `TimelineEntryMetricsView`
- Stats — `workoutLogsThisWeek`, `caloriesBurned` in `DailyStatsSnapshot`,
  `StatsActivitySummaryRow`
- Onboarding — the sets ask at `OnboardingLoggingTipsStepView:133` and the
  "22 total sets" worked example at `:42`
- AI service — the exercise branch in `normalizeLogEntryFeedback.js`, the exercise
  rules in `logEntryPrompt.js`, the exercise shape in `logEntrySchema.js`
- Reminders — the three notification strings at `ReminderService.swift:143,147,151`
  ("meal **or workout**", "meal **or workout**", "ate **or trained**"). **Not in
  the original scope list** — add one to the file count. Step 3a writes onboarding
  copy that sells reminders, so leaving these would have the pitch and the
  notifications contradicting each other.

**This step got smaller.** `type: food|exercise` discriminates the shared
`logEntries` collection, and the earlier plan was to keep `LogEntryType` and the
*read* path so historical entries still render. With no documents in Firestore
there is nothing to render — **delete `LogEntryType` and the read path outright**
along with the write paths and the AI branch. One concept removed instead of one
kept on life support, and no follow-up cleanup owed later.

**Done when** no code path can create an exercise entry, no surface aggregates a
burn figure, the day view never credits calories back, and old entries still
render without crashing.

> Worth doing the enumerated dead code in `project-brief.md` in the same pass —
> `MainTabGradientBackground`, `SavedMeal.lastUsedAt`, the unused
> `SavedMealsViewModel` helpers, `LogEntryDetailSheet.onSaveMeal`. Same kind of
> work, same risk profile.

---

## Step 3a — Notification opt-in in onboarding · S

**Ships in the launch build.** Everything else retention-shaped waits until after
approval; this one does not, because it is a leak rather than a feature.

Reminders default to `.quiet`
(`ProfileReminderSection.swift:6`) and the permission ask exists only behind
Settings → Reminders. Effectively nobody has reminders on. No amount of Step 12
intelligence fixes a feature that is never switched on, and the paywall is already
selling "Smart reminders" as a Pro benefit at `SubscriptionPaywallSheet.swift:25`.

**Where it goes: between `loggingTips` and `summary`.** Not after the summary —
`OnboardingSummaryStepView` commits the profile through `RootView.saveOnboarding`,
which fires `SubscriptionPaywallSheet` on success. An ask placed after it competes
with the paywall sheet for the same moment.

**Soft pre-prompt, not the system prompt.** iOS grants exactly one
`requestAuthorization` per install, and a denial is permanent from inside the app —
`ReminderService.hasAuthorization()` returns `false` forever after, and
`ProfileReminderSection` can only surface `authorizationDenied` and point at iOS
Settings. So the step is an explanatory screen with **Enable** and **Not now**, and
only **Enable** calls through to `ReminderService`. Firing the system prompt on
step appearance burns the single attempt on users who were not yet convinced.

1. New `OnboardingNotificationsStepView`, plus the case in the `private enum
   OnboardingStep` at `OnboardingFlowView.swift:10` and its `analyticsName`.
2. Default flips `.quiet` → `.normal` on Enable; **Not now** leaves `.quiet`.
   The `@AppStorage` default at `ProfileReminderSection.swift:6` changes with it.
3. Assumes Step 3 has already fixed the three workout strings in `ReminderService`.

**Files** new `OnboardingNotificationsStepView.swift` · `OnboardingFlowView.swift` ·
`ProfileReminderSection.swift`

**Done when** a fresh install that taps Enable reaches the main screen with three
pending notification requests scheduled, tapping Not now leaves zero, and neither
path can reach the paywall and the permission prompt at the same time.

---

## Step 4 — The adaptive engine · M

> ### Re-scoped 14 September — a pace check, not an expenditure engine
>
> Step 4 was planned as an expenditure engine: estimate what the user burns from
> logged food and trend weight, then set targets from that number — the
> MacroFactor model. 4b1 built and tested that arithmetic, and the testing made
> the case against shipping it:
>
> - **It is a health measurement we cannot validate.** A number like "you burn
>   2,625 kcal" is what App Store 1.4.1 expects to be backed by disclosed,
>   validated methodology. MacroFactor backs theirs with a 748-user, 100-day
>   study. We have no users and no such data.
> - **It is only as good as the food log.** Partial logging is the weakness
>   MacroFactor names first, and an app built on describing food in a sentence
>   will have more of it, not less.
> - **Getting it right is ongoing research.** The trend lags real weight, so the
>   estimate ran 150–240 kcal/day low at a new user's first check-ins and right
>   after a goal change — larger than MacroFactor's entire median error.
>   Fixable, but each fix is more science to cite and to explain.
> - **The audience could not follow it.** People cooking at home want to know
>   whether it is working, not how an energy-balance model works.
>
> **What replaces it — the pace check.** Once a week, one question: *is your
> weight moving at the pace you chose?* Too slow, the target steps a little toward
> the goal. Too fast, it steps back. About right, nothing changes. It reads only
> the weight trend, claims no measurement, keeps working when meals are estimated
> or missed, and explains itself in one sentence. It is what a human coach does.
>
> **Every promise already written survives** — `store-copy.md`'s "Targets that
> move", the weekly check-in, and Shot 05's "They move as your weight moves".
>
> **It is not a MacroFactor copy.** App Store 4.1 is about copying an app's name,
> icon or screens, not a physiological idea. Adjusting targets from weight change
> is textbook and sold in several forms; this rule, these screens and this copy
> are ours.

> ### How Step 4 is split
>
> - **4a — weigh-ins and the trend. Done 12 September.** Items 1, 2 and the
>   weight surface. Works from two data points, changes no targets, and makes no
>   coaching claim — so it adds almost no App Store review risk to a live app.
> - **4a2 — Apple Health body mass. Done 12 September** (commit `a6cd0f6`). Was
>   Step 13, pulled forward: weigh-ins are the pace check's only input, and a
>   smart scale fills them in. `com.apple.developer.healthkit` is in
>   `GymFuel.entitlements` and `NSHealthShareUsageDescription` in `Info.plist`. It
>   reads `bodyMass` only, never writes, and imports on connect and every time the
>   app opens — no background delivery, so scale readings arrive at the next open.
>   **The live privacy policy still says the app does not use HealthKit;** it is
>   updated with the terms before submission (see *What I need from you*).
> - **4b1 — the trend and the seeder.** Built 12–13 September: the time-aware
>   trend (7-day half-life), the expenditure calculator, and the debug seeder. The
>   trend and the seeder stayed; the expenditure pieces were removed 14 September.
>   Nothing user-visible. See *Finishing 4b1* below.
> - **4b2 — pick a pace.** A pace step in onboarding, a Pace row in Settings, and
>   a starting target that follows the chosen pace. Item 5. No new collection.
> - **4b3 — phases and the pace rule.** The `phases` collection and the pure pace
>   rule with full tests. Item 4. Also an optional **target weight** row in
>   Settings, copied onto each phase, and the **full targets** saved on each phase
>   (decisions 10 and 11). Visible only in the debug section, apart from the
>   Settings row.
> - **4b4 — the weekly check-in.** Item 6: the Week-screen card, the check-in
>   screen, accept or reject, plus the next-due date Steps 12 and 14 both read off.
>   Also **full targets saved on each check-in**, past weeks on the Week screen
>   showing the target they had, and the check-in **offering Maintain once the
>   target weight is reached** (decisions 10 and 11).
>
> Split again on 14 September: the old 4b2 was too big for one session, so each
> part now ends with something you can tap.
>
> Plans: 4a `~/.claude/plans/lets-split-into-two-polymorphic-metcalfe.md`
> (includes the App Store 1.4.1 and 5.1.3 framing) · 4b1 as originally built
> `~/.claude/plans/yes-write-the-4b1-sorted-lamport.md` — **superseded wherever
> it describes expenditure** · **4b2–4b4 `~/.claude/plans/calm-launching-planet.md`**
>
> Decisions 10 and 11 came after that plan was written. **Where the plan and this
> file disagree, this file wins.**

Still the step that decides whether the app coaches at all, so it still goes
early.

1. ~~`weighIns` collection + service; `EditWeightSheet` writes both the history row
   and `UserProfile.weightKg`.~~ **Done in 4a.** Written sequentially, history
   first — not batched: a batch fails atomically, so a rules rejection on the
   profile half would discard a correct weigh-in.
2. ~~Trend weight — EMA, `alpha ≈ 0.25`.~~ **Done in 4a, revised in 4b1.** 4a
   smoothed per *observation*, so a 30-day gap and a 1-day gap did identical
   arithmetic — harmless while the trend was only drawn, wrong once
   `trendDeltaKgPerWeek` divides by elapsed days. **4b1 replaced the fixed alpha
   with a 7-day half-life**: `decay = 0.5 ^ (gapDays / 7)`. Still one point per
   observation — gaps are still never carried forward or interpolated; only the
   weight given to each reading changes.
3. ~~Expenditure — `meanDailyIntake − (trendDeltaKg × 7700) / days`.~~ **Dropped
   14 September** in favour of the pace check. Built and unit-tested in 4b1;
   removed 14 September.
4. `phases` collection — goal, start date, start weight, goal pace (% bodyweight
   per week, stored as a magnitude), the running calorie adjustment the pace
   check has made, the optional target weight, and the full targets (calories,
   protein, carbs, fat) the phase started with. **4b3.**
5. Pace and targets — the user picks a pace preset in onboarding and can change it
   in Settings; the starting target follows that pace; the pace check moves it in
   steps from there. Lose fat: Gentle 0.5 % · Steady 0.75 % · Faster 1.0 % a week.
   Gain: Slow 0.25 % · Steady 0.5 % a week. Maintain: no pace, ±0.5 kg band.
   **4b2.**
6. `checkIns` collection + the weekly check-in screen, where the user accepts or
   rejects a suggested change. Each check-in saves the full targets before and
   after. Once the target weight is reached, the check-in offers a switch to
   Maintain. **4b4.**

**Done when** two weeks of seeded weigh-ins moving slower than the goal pace
produce a check-in that moves next week's target by one step and says why in one
sentence — and one week of the same data changes nothing.

### Decided 14 September

| # | Decision |
|---|---|
| 1 | **Pace is picked in onboarding**, right after the goal, and **changed in Settings**, as named presets (item 5). Maintain skips the step. Each preset shows "about X kg a week" for the user's weight. |
| 2 | **The user accepts or rejects** a suggested change at the check-in. Rejecting starts the same 14-day wait as accepting, so the same question is not asked every week. |
| 3 | **A check-in is due every 7 days from the day the goal or pace started.** No weekday setting. Missed weeks collapse into one check-in. |
| 4 | **The check-in shows days logged and average logged calories as context only** — never an input, no colours. Keeps `store-copy.md`'s "what you averaged" true. |
| 5 | **Pace is stored on the profile (`goalPace`) and copied onto each phase.** Goal and pace save in one write, and targets stay a plain calculation. |
| 6 | **The starting offset comes from the pace:** `kg per week × 7,700 ÷ 7`, with the deficit capped at 1,000 kcal a day — worded as a planning estimate, never "you burn". |
| 7 | **Calorie floor 1,200 for women, 1,500 for men and prefer not to say**, and never below protein + fat calories. |
| 8 | **The calorie adjustment carries across a pace or goal change** — it corrects the formula for this person, not for the goal. |
| 9 | **Extra guards:** weigh-ins must span at least 10 days, and Maintain does not step if the trend is already heading back into the band. |
| 10 | **Optional target weight, set in Settings only** — never in onboarding. Stored on the profile (`targetWeightKg`) and copied onto each phase, like pace. Maintain has none. It never touches `weightKg` — only a weigh-in does. Once the trend reaches it, the check-in **offers** a switch to Maintain, and the user accepts or rejects it like any other change (decision 2). **4b3** saves it; **4b4** offers the switch. |
| 11 | **Full targets are saved on phases and check-ins** — calories, protein, carbs and fat. A phase saves the targets it started with; a check-in saves the targets before and after. Past weeks on the Week screen show the target saved for that week, not today's. Today's target is still worked out live (`formula + adjustment`), and there is no daily targets record. **4b3** saves them on phases; **4b4** on check-ins, and wires up the Week screen. |

> **Decision 10 details — agreed 14 September:**
> - **"Reached" means the trend weight** gets there, not a single weigh-in.
> - **Settings only accepts a sensible target:** below today's weight for Lose
>   fat, above it for Gain, and never in the underweight range.
> - **No finish date is ever shown.**
>
> New fields go into `firestore.rules` in the session that first writes them.

> **Trial note.** The first check-in that can change a target is day 14 at the
> earliest, so the launch's 3-day trial shows the trend and a check-in but never a
> target moving. Pricing and trial length stay as decided in Step 0.

### The pace check

Starting values. Each is tunable in the 4b3 plan; none is a claim shown to the
user.

| Rule | Starting value | Why |
|---|---|---|
| **Measure the pace** | Best-fit straight line through the raw weigh-ins of the last 14–21 days | Trend endpoints lag at the start of a phase — tested 13 September, they undercount a steady loss by about a third in exactly the weeks a check-in matters. The 7-day trend line stays on the chart. |
| **Enough data** | 14+ days since the phase started or the last accept/reject, 6+ weigh-ins, spanning 10+ days | Less than that is mostly water weight, and bunched readings can't make a slope |
| **About right** | Within ±50% of goal pace, same direction → no change | Deliberately wide: small misses are noise |
| **Too slow, or the wrong way** | Step toward the goal: −100 kcal on a cut, +100 on a gain | Small steps cannot overshoot |
| **Too fast** | Step back: +100 kcal on a cut, −100 on a gain | Stops a pace faster than the user chose |
| **Maintain** | Step only if the trend leaves ±0.5 kg of the phase start weight, and not if it is already heading back | Maintain has no pace |
| **Target weight reached** | If a target weight is set and the trend reaches it (at or below on a cut, at or above on a gain), offer a switch to Maintain instead of a step | The goal is done — stepping further would carry the user past it |
| **How often** | At most one decision per 14 days — accepting and rejecting both start the wait | Each step needs time to show, and nobody is asked the same question weekly |
| **Food logging** | Step only if food was logged on most days (about 5 in 7); otherwise keep the target and say so neutrally | If the target isn't being eaten, lowering it helps nobody. Counts logged days; never reads calories. |
| **Floor** | Never below 1,200 kcal (women) or 1,500 kcal (men, prefer not to say), and never below protein + fat calories | Safety, and keeps the macros adding up. Needs a source on the Sources screen. |

The user reads it as one sentence: *"You aimed to lose about 0.4 kg a week and
lost about 0.1 kg a week over the last two weeks, so your target is now 1,900 kcal,
down from 2,000."*

**Where the step lives and the starting offset are both decided** (decisions 5
and 6 above). The adjustment lives on the phase and today's target stays a
synchronous `formula + adjustment`, so no screen waits on a stored target and
`dailyMacroTargets` stays unused. Saved targets (decision 11) are history only —
read for past weeks, never for today. The Sources screen's method 01 footnote
changes with the offset in 4b2.

### App Store — what the pace check asks of review

- **No expenditure or metabolism number appears anywhere.** The check-in shows
  weigh-ins, a pace and a target, and calls the target a starting point.
- **Citations owed under 1.4.1:** the pace ranges and the calorie floor.
  Self-weighing is already on the Sources screen from 4a.
- **Copy stays non-judgemental:** no "failed", no red, no streak for hitting a
  target (`design.md` rule 5).

### The sign still matters

Pace is signed — negative means losing — and goal pace is stored as a magnitude,
with its sign taken from `goalType`. Otherwise a stored `0.75` on a cut reads as a
gain goal and the pace check steps the target the wrong way while reading
perfectly. Settled 12 September; the expenditure worked example that forced it is
retired with the formula.

### Finishing 4b1 — done 14 September

Nothing here is user-visible.

- **Kept:** `WeightTrendCalculator` (7-day half-life) and its tests · the Sources
  trend-method copy · `DebugDataSeeder` and `ProfileDebugSection`.
- **Removed:** `ExpenditureCalculator.swift`, `DailyIntake.swift`,
  `ExpenditureCalculatorTests.swift`.
- **Changed:** the debug section's *Estimate expenditure* row is gone rather than
  replaced — a pace readout needs the pace rule, which is 4b3's. The seeder now
  writes one of three scenarios, at −0.1, −0.4 and −0.8 kg a week against an
  assumed "Lose fat" goal of −0.4 (Gentle: 0.5 % at 83 kg), which 4b3's pace check
  should answer with *step the target down*, *no change* and *step it up*. It
  writes no goal yet: `phases` arrives in 4b3.
- **Stale outside this file:** `project-brief.md` §4 still specifies the
  expenditure formulas, and `repositioning-strategy.md` ("Why the retention half is
  worth building") still describes adaptive expenditure. **Do not build from
  either.**

### Finishing 4b3 — done 14 September

Plan: `~/.claude/plans/yes-to-all-four-nifty-parrot.md`. Decided while planning:

- **Changing only the target weight updates the current phase in place** — no new
  phase, so it cannot reset the 14-day wait or the check-in clock.
- **A cleared target weight is written as `FieldValue.delete()`** in
  `updateProfile`. A merge write cannot clear a field, and a target weight can't be
  resolved on read like pace can: checked against today's weight, a reached target
  would vanish.
- **"Target weight reached" is a result of the pure pace rule** (`.targetReached`).
  4b4 only builds the offer.
- **No offline phase write.** Nothing writes a phase offline in 4b3; 4b4 adds its
  own offline branch for check-ins.
- **The current phase is the newest by `startedAt`**, not by key. The same in normal
  use; it lets the debug seeder backdate a phase on an account that already has
  `phases/{today}`.
- **The rule steps from the formula's base, not today's target** — an adjustment
  below `floor − base` does nothing, so a step up from a floored target still moves
  it. `PaceCheckCalculator.Input` takes base and floor calories.
- **Sources method 06 is "Your target weight"** (BMI 18.5, WHO Tech Rep Ser 894).
  4b4's check-in method becomes **07**.

### Two things to leave in place for later steps

Neither is extra work now; both are expensive to retrofit.

- **Keep `source: manual | healthKit` on `weighIns`.** Now in use: 4a2 writes
  `healthKit`, and the import never overwrites a `manual` row.
- **`checkIns/{dueDateKey}` must cheaply answer "when is the next one due."**
  Step 12 schedules the weekly nudge off that date, and Step 14's widget may show
  it. If the only way to derive it is replaying the whole collection, both steps
  get harder than they need to be.

---

## Step 5 — Food wedge, client · M

Everything a screenshot needs to show.

- **Assumptions on the timeline card.** `assumptions[]` currently sits one tap
  deep in `LogEntryDetailSheet`. Surface it: *"Assumed 2 tbsp ghee · tap to
  change"*. This is the product's personality and it is invisible today.
- **Share card.** Render an entry — image, title, macros, score, the one-line
  explanation — to an image, with a share sheet and a watermark. The app has no
  sharing, export, invite or referral of any kind.

**Files** `TimelineEntryRow*` · new share-card view · `MainTabView`

**Done when** shots 02, 03 and 06 can be taken, and a card can be posted to
Instagram Stories in one tap.

---

## Step 6 — Food wedge, backend · M

Client and AI service together; coordinate the schema change.

- **Multi-item split** — one sentence becomes several entries. Schema + prompt in
  the AI service, then `LogComposerViewModel` stops assuming one entry per submit.
- **Portion reference set** — 100–200 dishes you can verify, in household measures
  (katori, roti vs paratha, a plate of biryani, home-cooking oil). A JSON file plus
  prompt instructions. **Not a `foods` collection.**

  > **Spread it across cuisines** — Step 0 closed cuisine-agnostic on 11 September.
  > The examples above are desi because the brief was; they are no longer the
  > shape of the set. What generalises is the **household measure**, not the dish
  > list — a katori, a cup, a ladle, a piece, a home-sized pour of oil — so build
  > the set around measures several cuisines share and verify dishes across them.
  > Still 100–200 you can actually check; still server-side, so it extends without
  > a build.
- **Move image analysis off `gpt-5.4`** (`src/ai/imageRecognizer.js:27`) and stop
  routing exercise text through the vision path.
- **Goal framing in the prompt.** `logEntryPrompt.js:76` tells the model that
  `lean_bulk` means *"carbs that support training and recovery"*, and `:98` repeats
  the register. Step 2 changes the display strings; this is the same vocabulary
  sitting in the model's reasoning on every estimate, where users never see it but
  every explanation inherits it. Rewrite the goal rules at `:55,76,98`. If you
  rename the `GoalType` raw values, do it here — the token rename is nearly free
  while these lines are already open, and pointless otherwise. Sites:
  `logEntryRoute.js:36`, `logEntryPrompt.js:55,76,98`, and six in
  `logEntryScoring.js` (`:23,27,112,149,165,276`).

**Done when** *"two roti, chicken karahi, half a katori rice"* produces three
correctly-portioned entries, and per-scan cost is measured rather than assumed.

---

## Step 7 — Day-aware goal-fit score · M · **first thing to cut**

Not required for launch. Every screenshot caption works with the current score.
Cut this before cutting anything else.

- Port `logEntryScoring.js` (~470 lines, pure arithmetic) to Swift.
- Compute on read from stored macros + current day state + current goal.
  `goalFitScore` stops being a stored field.
- Remove the `scoreFoodLog` call from `normalizeLogEntryFeedback.js` once verified.

**Why it's worth doing eventually** it closes three flags at once — scores frozen
at log time, scores going stale when the goal changes, and `logSavedMeal` writing
`goalFitScore: nil` so re-logged saved meals vanish from every score surface.

---

## Step 7a — Visual sweep · M

The screens no other step rebuilds. By here, Steps 3, 3a, 4, 5 and 6 have shipped
their own surfaces in the new language; this is the remainder, and it is the last
thing that changes what a screenshot shows.

**Scope, from `design.md`'s inventory:**

- **Auth** — Welcome, Sign up, Sign in, reset password. Four screens, one pattern.
- **Settings** — the hub, targets, reminders, appearance, delete account. Weight
  is **shown, never edited** — it comes from weigh-ins or the trend stops being a
  measurement.
- **Saved meals** — picker, list, add, edit.
- **Explainers** — the goal-fit sheet, nutrition sources.
- **Onboarding metric steps** — gender, age, height, weight, activity. One
  template, five screens; the canvas draws it once as `Onboarding · weight`.
- **Day picker and menu** — the two-scale nav model. Day and Week only, no Month.

Then delete the old system: `Color.liftEatsCoral`, the four `Fuel*` colorsets, and
any remaining emoji in view code (the paywall carried eight, the summary step four).

**Done when** no screen in the app still renders from the old palette, and a walk
from launch to paywall to settings looks like one app in both themes.

> **Not on the cut list.** Everything above the line in *If time runs short* can
> go; this cannot. Shots 01–06 are taken from these screens, and a listing that
> mixes two visual systems reads as abandoned rather than minimal.

---

## Step 8 — Rename · S

The name is **`Circa`** — `CFBundleDisplayName` on the home screen, and
`Circa: Food & Calorie Journal` in App Store Connect.

- Both fields, not one. These are separate; changing only one is a common miss, and
  a mismatch between the store name and the app name gets flagged in review.
- Sweep user-facing strings for "LiftEats".
- **The bundle identifier stays `com.ahmad.GymFuel`.** Renaming the app does not
  touch it, nobody sees it, and changing it would be a new app record.

**Done when** nothing user-facing carries the old name.

---

## Step 9 — App Store Connect metadata · M

All of this ships with the version. Copy is written and paste-ready in
`store-copy.md`.

1. Name, subtitle, keywords, description, promotional text.
2. ~~Intro offer 3 days → 14 days~~ — **not this submission** (Step 0, 11 Sep).
   The trial stays at 3 days, so there is nothing to change in App Store Connect.
   Verify only that the paywall and the configured offer still say the same thing.
3. ~~Price change to $7.99 / $54.99~~ — **not this submission** (Step 0, 11 Sep).
   Prices stay at $5.99 / $49.99. Grandfathering is a problem for the day the
   change actually happens, which is after approval at the earliest.
4. **Cross-localization** — two secondary locales, properly. Arabic first: it is
   one of the nine US-indexed secondaries *and* the Gulf localisation we want.
   +160 indexable chars each. **Do not paste the same text into nine slots** —
   Apple rejects that now.

---

## Step 10 — Screenshots and submit · M

Six captions, in `store-copy.md`. Shots 04 and 05 need Step 3 shipped; 02, 03 and
06 need Step 4. **All six need Step 7a** — a shot of a half-converted screen is
worse than no shot.

> **Shot 05 — "They move as your weight moves" — must not ship unless Step 4 did.**
> It is the one caption that promises something the build might not contain.

Then submit. Expect the usual review turnaround, and **budget four weeks after
approval before keyword rankings settle** — do not judge the repositioning before
then.

---

## Step 11 — After approval

- **Custom Product Pages.** Default page generic; a desi page for desi creators,
  with its own link and assigned keywords. Up to 70. No build needed, reviewed in
  a day or two. This is the largest distribution lever available and it costs
  screenshots only.
- **Creator outreach.** 20–50 nano creators, gifted codes, each cohort pointed at
  its own CPP link.

---

# Retention — after approval

Two features still held back until the listing is live. Ordered by cost, cheapest
first: Step 12 adds no target and no entitlement, Step 14 adds a whole target.
Step 13 was pulled forward into the launch build as 4a2.

**App Intents, Siri, Shortcuts and Control Center controls are out.** Decided
7 September — too much lift for this stack, and widgets do not need them. See
`project-brief.md`. **Push notifications are parked, not rejected** — there is no
APNs setup and no push entitlement today, and Step 12 does not need one.

---

## Step 12 — State-aware reminders · M

Step 3a turned reminders on. This makes them worth having on.

**The constraint that shapes the whole design.** `UNNotificationRequest` content is
fixed at *schedule* time, and a Notification Service Extension only intercepts
*push* — which we do not have. There is no way to compute a message at fire time.
"Intelligent" therefore has to mean **rescheduling aggressively**, not deciding
late. `ReminderService.apply(_:)` already has the right shape — tear down, rebuild
— it just takes a `ReminderMode` where it should take a state struct.

Rebuild the pending set on: app foreground, app background, after every log write,
after a weigh-in, after a check-in.

**`allReminderTimes` breaks here.** `removePendingReminders()` cancels by
enumerating a hardcoded list of eight times (`ReminderService.swift:80-89`). Once
times are state-driven it cannot enumerate what to cancel. Track the identifiers
actually scheduled, or clear all — but do not leave the hardcoded list in place
while the schedule moves, or reminders will accumulate and never be cancellable.

Content, ranked by value:

1. **Weekly check-in / weigh-in nudge.** Fires once a week, carries a real payload
   ("your targets moved"), and is the thing they pay for. Needs Step 4.
2. **Streak protection.** `StatsSnapshot.currentStreakDays` already exists
   (`StatsCalculator.swift:57`). Highest-converting nudge shape in this category.
3. **Suppression.** Skip the nudge when the window already has an entry. A reminder
   that stays quiet because you already logged beats a cleverer one that always
   fires, and it is the cheapest thing on this list.

Mind the 64 pending-request cap.

**Files** `ReminderService.swift` · `TimelineViewModel` / `LogComposerViewModel`
hooks · `GymFuelApp.swift` scene phase

**Done when** logging lunch cancels the afternoon nudge, and the weekly check-in
notification fires on the right day carrying the user's actual trend.

---

## Step 13 — HealthKit body mass · done early as 4a2

Pulled forward into the launch build on 12 September (commit `a6cd0f6`) — see
Step 4. The rules this section set are the rules the code follows:

- **Read `bodyMass` only. Nothing else, in either direction.** No write, no active
  energy, no workouts, no steps — `NSHealthShareUsageDescription` only.
- **The earliest sample of the day wins** — the morning reading.
- **A manual weigh-in is never overwritten** by a Health sample for the same day.
- **A denied read is invisible** — iOS reports it as no data, so no screen says
  "you denied this".
- **iPad has no HealthKit** — every surface hides itself when Health is unavailable.

Imports run on connect and on every app open. There is no background delivery.

**Files** `HealthKitWeightService.swift` · `HealthWeightSyncService.swift` ·
`WeighInImportPlanner.swift` (+ tests) · `ProfileHealthSection.swift` ·
`Info.plist` · `GymFuel.entitlements`

---

## Step 14 — Widgets · L

The passive half of the retention loop. Read-only.

**No Firebase in the extension.** A widget process cannot practically reach
Firestore — its own auth via keychain access groups, a cold start, a network
round trip, and a read burned on every timeline refresh. The design is one-way:
the app writes a small `Codable` `TodaySnapshot` into an App Group container
whenever the timeline changes, then calls
`WidgetCenter.shared.reloadTimelines(ofKind:)`. The widget reads only that file.

Snapshot: date, consumed calories, target calories, consumed and target P/C/F,
last-logged-at, streak. **No burned field** — see Step 3.

**Staleness is the whole difficulty.** The widget has to render something sane
when the snapshot is missing, from a previous day, or written before a target
change. Show the date it came from rather than a confidently wrong number.

- Tap → `widgetURL` deep link into that day. **No App Intents** — interactive
  buttons are the only thing that would need them, and they are out of scope.
- `systemSmall` (calories-left ring) and `systemMedium` (ring + macro bars).
  Lock Screen accessory circular/rectangular are near-free once the target exists.
- **After Step 8.** A new target means new bundle identifiers, new provisioning and
  an App Group id. Settle the name once.

**Files** new Widget Extension target · new shared `TodaySnapshot.swift` ·
`TimelineViewModel` write point · `GymFuelApp.swift` · entitlements on both targets

**Done when** the widget matches the app within one refresh of a log, and a cold
device with no snapshot yet shows a sensible empty state rather than zeros.

---

## If time runs short

Cut in this order. Everything above the line still makes a coherent launch.

1. **Step 7** — day-aware score. Nothing depends on it.
2. **Step 6's portion set** — ship 50 dishes instead of 200; extend later without
   a build, it is server-side.
3. **Step 9's cross-localization** — the primary locale alone is a valid listing.
4. **Step 3a** — last, and reluctantly. It is an S, so cutting it saves little, and
   the cost is launching with reminders off for every user until Step 12.

Steps 12 and 14 are not on this list. They are after approval either way, and
Step 13 already shipped as 4a2.

**Never cut:** Step 1 (rejection risk the moment the trial changes), Step 2a
(everything after it assumes the tokens exist), Step 3's rebate removal (defeats
the pace check), Step 4 (it is the reason anyone pays), or Step 7a (the screenshots
come off those screens).

---

## What I need from you, and when

| When | What |
|---|---|
| Now | ~~The name, and confirmation of the cuisine~~ — **all of Step 0 closed 11 September.** Only the USPTO search and the handles are still outstanding, and neither blocks a build. |
| Before Step 4 | Nothing — I can build and seed test data myself |
| Before Step 9 | App Store Connect access, or you run the metadata changes |
| Before Step 10 | A device to shoot on, and real-looking data to shoot |
| Before Step 10 | The live privacy policy and terms updated for the revamp, including Apple Health (App Store 5.1.3) — once the app is final, before submission |
| Step 11 | Creator list |
| ~~Before Step 13~~ | ~~HealthKit capability enabled on the App ID~~ — **done 12 September, in 4a2** |
| Before Step 14 | An App Group registered, with the bundle identifier settled in Step 8 |
