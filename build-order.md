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
pulled forward into 4a2 because it feeds the Weight screen.

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
- [x] **4a** · Weigh-ins and the trend
- [x] **4a2** · Apple Health body mass → `weighIns`
- [x] **4b** · Target maths and safety limits
- [x] **4c** · Goal weight and saved targets
- [ ] **4d** · Your targets screen
- [ ] **4e** · The Weight screen
- [ ] **4f** · The plan screen in onboarding
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

What relaxes: the `GoalType` and `ActivityLevel` raw values, the `logEntries` read
path in Step 3, and migrating historical `goalFitScore`. Each is marked at its own
site below.

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

**Moved ahead of Step 4.** Doing this after launch would leave a dead subsystem
sitting under the feature that replaces it. Weigh-ins and the Weight screen *are*
the new framing for effort and expenditure; the exercise log is the old one. Delete the
old one before building the new one, so Step 4 is built on a clean base and nobody
has to reason about which system owns a number.

This is a full sweep, not the two-line version. It is pure deletion, which is the
cheap kind of work and exactly what a coding agent does well in one pass.

**The part that matters most — the rebate.** `DailyMacroDetailSheet.swift:12`
(`target - consumed + burned`) and the "Burned" tile at `:31`. Eaten-back calories
stall the weight while the log says the user is on target, so the Weight screen
shows a stall the log cannot explain. **The rebate and the Weight screen cannot
coexist.**

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

## Step 4 — Weigh-ins, the plan, and saved targets · L

Weigh-ins and Apple Health body mass are done (4a, 4a2). What is left gives the user
a plan they can see: a goal weight, a line to it, targets with a reason for each
number, and a Weight screen that shows how it is going. **Nothing in Step 4
coaches, suggests or judges**, and targets change only when the user acts.

> **Tried and dropped. Do not rebuild any of these.**
>
> - **An expenditure engine** (dropped 14 September): a "you burn X" number we
>   cannot validate, and it needs complete food logs.
> - **Phases and weekly check-ins** (built, then reverted 16 September in
>   `a6775a7`; the work is on `backup/step4b-abandoned`): storing every decision
>   made it thousands of lines.
> - **A weekly page with a one-tap target change** (dropped 17 September, never
>   built): its stall and too-fast rules were subjective, each needed a citation,
>   and three weeks of weigh-ins misread a slow loss as a stall about one time in
>   three.

### The rules

Decided 17 September. Every sub-step below builds on these; none repeats them.

**Pace.** Lose 0.5% of body weight a week, gain 0.25%, maintain 0. The plan line and
the calorie target come from the same pace, at 7,700 kcal per kg:
`daily offset = weight kg × pace × 7,700 ÷ 7`. That is about −470 kcal a day at
85 kg losing, and +190 at 70 kg gaining. Faster gain mostly adds fat (Iraki 2019).

**Maintenance estimate.** Mifflin–St Jeor × the activity multiplier. It may be shown
as "about 2,420 kcal a day to stay at your weight": rounded, dotted as an estimate,
never called "burn", saved with the targets, and never updated from food logs or
weigh-ins. Under it: *"This is a starting estimate. Your weigh-ins will show whether
it's right."* A number that claims to *measure* what this person burns is still out.

**Activity.** One question, four options, each describing a normal week *including*
exercise. The multipliers sit at the careful end of the measured ranges
(FAO/WHO/UNU 2004), because a number that is too high is the one that stalls weight
loss.

| Option | A normal week | Multiplier |
|---|---|---|
| Mostly sitting | Desk or study most of the day, little or no exercise | 1.35 |
| Lightly active | Mostly sitting, plus a daily walk or exercise a few times a week | 1.5 |
| Active | On your feet most of the day, or hard exercise most days | 1.7 |
| Very active | Physical work all day, or hard training every day | 1.9 |

Do not lower *Mostly sitting* to the 1.2 that online calculators use. Measured
everyday lifestyles start at 1.40.

**Macros.**

- **Protein 1.6 g/kg** for every goal. Muscle gain stops improving above about 1.6
  even for lifters (Morton 2018), and 1.2–1.6 is the range for weight loss (Leidy
  2015). Users who want more can type it.
- **Fat 0.8 g/kg**, 0.9 when gaining.
- **Both use the lower** of the goal weight and the top healthy weight for the
  person's height (BMI 25), so a bigger body does not get 300 g of protein and no
  carbs. *Maintain* uses the current weight in place of a goal weight.
- **Carbs take what is left.** Calories round to the nearest 10.

**Safety.**

- Calories never go below 1,200 (women) or 1,500 (men, prefer not to say), and never
  below the calories in protein + fat. This includes numbers the user types.
- Users must be 18 or over, in onboarding and in Settings.
- No goal weight below BMI 18.5, and no *Lose fat* for anyone already below it.

**Targets are saved and stay put.**

- Worked out once and saved on the profile, with the date and weight they were set
  at: "Set at 85 kg on 3 Sep".
- They change only when the user acts: editing them, tapping **Recalculate** (fresh
  numbers from the latest weigh-in), or changing goal, goal weight or activity.
- Weigh-ins never change them, typed or from Apple Health. `weightKg` still updates,
  for display.
- Users edit calories, protein and fat; carbs fill the rest. Editing targets does not
  redraw the plan line.

**Goal weight.**

- Asked after *Gain / Lose fat / Maintain*, on the matching side of current weight.
  *Maintain* skips it and gets a flat line.
- Changing goal, goal weight or activity recalculates the targets and restarts the
  plan line from the latest weigh-in and today.
- Reaching the goal changes nothing by itself. The app says so, and the user picks
  *Maintain* or a new goal.

**Store only the current plan and targets**, overwritten in place, never a history.
Past days therefore show against the current targets. Accepted.

**The Weight screen** draws the plan line dotted and a trend line through the
weigh-ins, uses no red and no "behind" copy, and lets only manual weigh-ins be
deleted. Nothing edits a weigh-in.

### 4a — Weigh-ins and the trend · done 12 September

- A `weighIns` collection, one row per day. `EditWeightSheet` writes the history row
  first, then `UserProfile.weightKg`, sequentially rather than batched: a batch
  fails atomically, so a rules rejection on the profile half would discard a
  correct weigh-in.
- Trend weight is an EMA (`alpha ≈ 0.25`) per observation. Gaps are skipped, not
  filled. It is only ever shown as a level; nothing divides it by elapsed days.
- Onboarding seeds the first weigh-in, so the first real one draws a line.
- Every row keeps `source: manual | healthKit`. 4e uses it to decide what can be
  deleted.

### 4a2 — Apple Health body mass · done 12 September

Commit `a6cd0f6`. Reads `bodyMass` only, on connect and on every app open, for the
last 90 days, and never overwrites a manual weigh-in. The rules are in Step 13.
**The live privacy policy still says the app does not use HealthKit**; it is updated
before submission (see *What I need from you*).

### 4b — Target maths and safety limits · M

**What the user gets:** sensible starting numbers for every body, and no unsafe
target. Targets still follow weight until 4c saves them.

1. **Tests first.** New `MacroTargetCalculatorTests`, starting from the 17 September
   scan: a 45 kg, 150 cm, 60-year-old woman on *Lose fat* (951 kcal today); a 110 kg
   woman (82 g carbs today); a 200 kg woman (0 g carbs today); and gain and maintain
   at a few weights.
2. **`MacroTargetCalculator`** follows *The rules*: the pace offset, the floors,
   rounding, and the protein and fat basis. Until 4c adds goal weight, the basis is
   the lower of current weight and the BMI 25 weight. It also returns the
   maintenance estimate.
3. **`ActivityLevel`** gets the four options and their copy. Raw values may change,
   since there are no users yet.
4. **Age 18 or over** in the onboarding age step and the Settings age field. Today
   onboarding accepts 1–119 and Settings 10–100.
5. **No *Lose fat* below BMI 18.5**, in the onboarding goal step and the Settings goal
   picker, with one plain line saying why.
6. **Sources screen:** methods 01 and 02 rewritten to match. Cite the pace (NHS
   0.5–1 kg and CDC 1–2 lb a week for losing, Iraki 2019 for gaining), the activity
   table (FAO/WHO/UNU 2004), protein (Morton 2018, Leidy 2015), the calorie floor and
   the BMI limits.

**Files** `MacroTargetCalculator.swift` · `ActivityLevel.swift` ·
`OnboardingActivityLevelStepView.swift` · `OnboardingAgeStepView.swift` ·
`OnboardingTrainingGoalView.swift` · `ProfileEditorView.swift` ·
`NutritionSourcesView.swift` · new `MacroTargetCalculatorTests.swift`

**Done when** the tests pass, and on a device the 60-year-old woman above gets
1,200 kcal, the 110 kg woman gets normal carbs, age 17 cannot continue, and a
BMI 17 account cannot pick *Lose fat*.

### 4c — Goal weight and saved targets · M

**What the user gets:** a goal weight, and targets that stop moving on their own.

1. **Profile fields:** `goalWeightKg`, `planStartedOn`, `planStartWeightKg`, and the
   saved targets: `targetCalories`, `targetProteinG`, `targetCarbsG`, `targetFatG`,
   `maintenanceCalories`, `targetsSetOn`, `targetsSetAtWeightKg`. Add every one to
   `onlyAllowedKeys` in `firestore.rules` and **deploy before testing**. A key
   missing from that list once blocked onboarding entirely.
2. **A goal weight step** in onboarding, after the goal step, per *The rules*.
3. **Onboarding saves** the targets and the plan start when it completes.
4. **Day and Week read the saved targets.** A weigh-in, manual or from Apple Health,
   updates `weightKg` and nothing else.
5. **The protein and fat basis** becomes the lower of goal weight and the BMI 25
   weight.
6. **An account with no saved targets** gets them worked out and saved once, on first
   load. Only test accounts exist.

**Files** `UserProfile.swift` · `firestore.rules` · `FirebaseUserProfileService.swift` ·
`UserProfileViewModel.swift` · `OnboardingFlowView.swift` · new
`OnboardingGoalWeightStepView.swift` · `MainTabView.swift` · `StatsView.swift` ·
`MacroTargetCalculator.swift`

**Done when** a new account's targets survive a relaunch, a manual weigh-in and an
Apple Health import both leave the Day target unchanged, Firestore shows the new
fields, and a *Maintain* account is never asked for a goal weight.

### 4d — Your targets screen · M

**What the user gets:** one place to see and change their numbers and their goal.
Built in the Circa design with `CircaComponents.swift`. It opens from Settings until
7a puts it in the menu.

1. **Shows** calories, protein, carbs and fat, "Set at 85 kg on 3 Sep", and the
   maintenance estimate, worded as in *The rules*.
2. **Edit** calories, protein and fat. Carbs fill the rest, and the floors hold.
3. **Recalculate** works out fresh numbers from the latest weigh-in.
4. **Goal, goal weight and activity** are editable here. Changing any of them
   recalculates the targets and restarts the plan line.
5. **Weight is shown, never edited.**

Build the editor once here; 4f reuses it.

**Files** new `TargetsView.swift` · `ProfileEditorView.swift` ·
`UserProfileViewModel.swift` · `FirebaseUserProfileService.swift`

**Done when** editing protein moves carbs and never breaks a floor, Recalculate after
a lower weigh-in lowers the numbers and updates "Set at", and changing goal weight
moves the plan start to today.

### 4e — The Weight screen · M

**What the user gets:** their weigh-ins against their plan. Built in the Circa design.
It opens from the Week screen's weight card until 7a puts it in the menu.

1. **Chart:** weigh-in dots, the trend line, the plan line (dotted, from the plan
   start toward the goal at the plan's pace) and the goal weight. *Maintain* draws a
   flat line.
2. **List** of weigh-ins below it, newest first, showing where each came from.
3. **Delete manual weigh-ins only.** A deleted Apple Health row would come back on
   the next open, because the import fills any day without a row
   (`WeighInImportPlanner.plan`), so a Health row says to change it in the Health
   app. `firestore.rules` has no `delete` on `weighIns` today; add it for the owner,
   manual rows only. Deleting the newest weigh-in sets `weightKg` back to the one
   before it.
4. **"Adjust targets"** opens 4d.
5. **Goal reached:** a plain note and a way to pick *Maintain* or a new goal. Nothing
   changes on its own.

**Files** new `WeightView.swift` · `WeighInService.swift` · `firestore.rules` ·
`WeightTrendCard.swift` · `StatsView.swift` · `UserProfileViewModel.swift`

**Done when** backdated Apple Health weights show as dots around a dotted plan line,
a deleted manual weigh-in stays gone after a relaunch, a Health weigh-in cannot be
deleted, and reaching the goal shows the note without changing a target.

### 4f — The plan screen in onboarding · M

**What the user gets:** before the paywall, a plan they can read: where they are
headed, roughly when, and why each number is what it is.

1. **Rebuild the summary step** (`Onboarding · your numbers` on the canvas) as the
   plan screen, in the same place. `saveOnboarding` still fires the paywall.
2. **Chart** to the goal date, reusing 4e's chart. *Maintain* shows no date.
3. **One reason per target.** For calories: "About 2,420 kcal a day to stay at your
   weight. Your target is 470 less, to lose about 0.4 kg a week." Then the
   starting-estimate line from *The rules*.
4. **Edit** with 4d's editor before continuing.

**Files** `OnboardingSummaryStepView.swift` · `OnboardingFlowView.swift` · 4d's editor ·
4e's chart

**Done when** a new *Lose fat* account sees a goal date and the reasons, can change
calories before continuing, and still reaches the paywall afterwards.

### Testing with real-looking data

The maths is pure, so its tests use plain values. To see the Weight screen on a
device or the Simulator, add backdated weights in the Health app and tap *Sync from
Apple Health*. The import reads the last 90 days
(`HealthKitWeightService.importWindowDays`). Use a fresh account per shape: falling,
flat, rising.

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
- **Judge meal size against the user's own calorie target.** Today the server uses
  the same bands for everyone (`scoreEnergyFit`, `logEntryScoring.js:160`): on Lose
  fat a 450 kcal meal scores top marks and a 900 kcal meal about 30, whatever the
  user's daily target is. Found 17 September.

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
- **Settings** — the hub, reminders, appearance, delete account. The targets screen
  is built in 4d. Weight is **shown, never edited** — it comes from weigh-ins or the
  trend stops being a measurement.
- **Saved meals** — picker, list, add, edit.
- **Explainers** — the goal-fit sheet, nutrition sources.
- **Onboarding metric steps** — gender, age, height, weight, activity. One
  template, five screens; the canvas draws it once as `Onboarding · weight`.
- **Day picker and menu** — the two-scale nav model. Day and Week only, no Month.
  The menu gets **Weight** and **Your targets** rows and becomes the way into the
  screens 4e and 4d built, which open from the Week card and Settings until then.

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
4. **Age rating 13+ → 18+.** The live listing still says 13+, but Step 4b gates
   onboarding and Settings at 18 and the app says so on screen. Change it in the
   age rating questionnaire before submitting, or listing and app disagree in review.
5. **Cross-localization** — two secondary locales, properly. Arabic first: it is
   one of the nine US-indexed secondaries *and* the Gulf localisation we want.
   +160 indexable chars each. **Do not paste the same text into nine slots** —
   Apple rejects that now.

---

## Step 10 — Screenshots and submit · M

Six captions, in `store-copy.md`. Shot 04 needs Step 3 shipped and 05 needs 4e or
4f; 02, 03 and 06 need Step 4. **All six need Step 7a** — a shot of a half-converted screen is
worse than no shot.

> **Shot 05's caption, "They move as your weight moves", is no longer true.**
> Targets are saved and change only when the user acts (Step 4). The shot shows the
> plan, from the Weight screen (4e) or the onboarding plan screen (4f), and its new
> caption comes from `store-copy.md`. Do not ship the old one.

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
after a weigh-in, after a target change.

**`allReminderTimes` breaks here.** `removePendingReminders()` cancels by
enumerating a hardcoded list of eight times (`ReminderService.swift:80-89`). Once
times are state-driven it cannot enumerate what to cancel. Track the identifiers
actually scheduled, or clear all — but do not leave the hardcoded list in place
while the schedule moves, or reminders will accumulate and never be cancellable.

Content, ranked by value:

1. **Weigh-in nudge.** Once a week, a reminder to weigh in that opens the Weight
   screen. It says nothing about whether the plan is working, because Step 4 judges
   nothing. Needs Step 4e.
2. **Streak protection.** `StatsSnapshot.currentStreakDays` already exists
   (`StatsCalculator.swift:57`). Highest-converting nudge shape in this category.
3. **Suppression.** Skip the nudge when the window already has an entry. A reminder
   that stays quiet because you already logged beats a cleverer one that always
   fires, and it is the cheapest thing on this list.

Mind the 64 pending-request cap.

**Files** `ReminderService.swift` · `TimelineViewModel` / `LogComposerViewModel`
hooks · `GymFuelApp.swift` scene phase

**Done when** logging lunch cancels the afternoon nudge, and the weekly weigh-in
nudge fires on the right day and opens the Weight screen.

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
(everything after it assumes the tokens exist), Step 3's rebate removal (corrupts
what the Weight screen shows), Step 4 (it is the reason anyone pays), or Step 7a
(the screenshots come off those screens).

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
