# Build Order

One ship, not six. The phases in `project-brief.md` are an ordering of *work*, not
of releases — everything below goes out in a single binary and a single App Store
submission.

One public release still allows focused TestFlight checks before submission.
Order the remaining work by **data contract, dependable meal editing, then
presentation**. Steps 0–5 remain complete.

**Agreed 19 September:** TestFlight users already liked explicit ingredient and
portion assumptions. Finish that validated interaction with editable items in one
meal and preserve corrected saved meals. This feedback establishes usefulness, not
measured accuracy or paid retention. Steps 5–6 own the meal contract. The numeric
meal score was removed from launch scope on 22 September.

---

## The critical path

```
meal schema ──► client + backend editing ──► visual sweep + share card
            ──► launch checks ──► screenshots ──► submit ──► approval ──► CPPs
```

**Screenshots follow working behavior.** The estimate, correction and saved-meal
paths must agree before their presentation is finalized.

**The redesign is inside this sequence, not beside it.** The app is being rebuilt
visually as well as functionally — the whole system is specified in `design.md`
and drawn on the canvas linked there. It threads through in three parts, and the
ordering is not optional:

1. **Step 2a lands the tokens first**, so no screen is ever built twice.
2. **Every step after it builds its own screens in the new language.** Steps 3,
   3a, 4, 5 and 6 each touch or create surfaces; each one ships them looking
   like `design.md`, not like the current build. This is not extra scope on those
   steps — it is the same work done once instead of twice.
3. **Step 7 sweeps the screens no other step rebuilds** — auth, settings, the
   remaining sheets and explainers, plus the final share card. It precedes screenshots
   because it is the last thing that changes what a screenshot shows.

Do not schedule "the redesign" as a phase. There isn't one.

**Custom Product Pages come after approval.** They need no build and get their own
review, so they are genuinely post-launch work — but they need the new screenshots,
so they cannot start early either.

**Additional retention surfaces come after approval.** State-aware reminders and
widgets remain Steps 12 and 14. The core repeat-use experience ships at launch:
corrected saved meals, the plan and weight history. Onboarding
notification opt-in and Apple Health body mass are already complete.

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
- [x] **4d** · Your targets screen
- [x] **4e** · The Weight screen
- [x] **4f** · The plan screen in onboarding
- [x] **5** · Meal contract and editable meal client
- [x] **6** · Meal backend, references and saved-meal round trip
- [ ] **7** · Visual sweep and final share card
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
path in Step 3. Each is marked at its own
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

**On the raw values.** With an empty Firestore they were safe to change (see
above), but there was no user-facing gain. The meal-analysis backend now ignores
the goal field; the prompt no longer uses it. Keep the raw values unless a later
change has a concrete reason and checks stored profiles and older app builds.
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
  reference-based (none), pending (the rule alone, nothing above it). Saving or
  editing an estimate never removes its uncertainty. Rule 1 in `design.md`,
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
> are the old system. Leave them until Step 7 — deleting them now breaks every
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
When the calorie floor lifts a losing target, the plan line slopes only as fast as
the maintenance estimate minus the floor allows, so it never promises a loss the
targets cannot deliver (decided 19 September).

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
  redraw the plan line; **Recalculate** does, because it re-anchors to the latest
  weigh-in and today (decided 19 September).

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
7 puts it in the menu.

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
It opens from the Week screen's weight card until 7 puts it in the menu.

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

## Step 5 — Meal contract and editable meal client

**Start with the contract, before implementation.** Describe the shared payload
and persistence shape, worked examples, and the smallest next implementation part.
Continue the existing small-step workflow; do not implement this entire step in
one pass. Steps 5 and 6 share a contract and must be verified together.

- **One submission, one meal, several editable items.** "Two roti, chicken karahi,
  half a katori rice" stays one timeline entry, with three items and one meal total.
- **Structured amounts and nutrition.** Define stable item/component identity,
  numeric quantity and unit, nutrition for that amount, material assumptions, and
  source information. Composite foods expose the major components users can
  correct. Specify which components contribute to which totals so an ingredient
  is never counted twice; displayed contributions reconcile within rounding.
- **Predictable editing.** Scale an unchanged item/component using its stored
  nutrition when its quantity changes. Changing ingredients or preparation can
  request reinterpretation of the affected part. Apply several edits together;
  preserve unaffected values. Show the calorie difference before saving. Whole-
  meal rewording remains an explicit action, not a requirement for quantity edits.
- **Honest provenance.** Distinguish estimated, user-adjusted and reference-based
  values. Saving or editing does not establish accuracy. Preserve uncertainty
  through edits and photo analysis; do not present model confidence as measured
  accuracy. A manual total override must explicitly supersede or invalidate an
  incompatible breakdown and explanation rather than showing both as consistent.
- **Assumptions on the timeline.** Surface the most consequential assumption,
  with a route into the editor; keep the full breakdown in meal detail.
- **Saved-meal contract.** Preserve the corrected items, amounts, assumptions,
  source information and meal description in a reusable snapshot. Re-logging
  copies that version; later saved-meal edits do not rewrite previous logs.
  Older totals-only meals remain usable and never gain invented component detail.

**Likely files** `LogEntryFeedback.swift` · `SavedMeal.swift` · meal detail/editor
views and view models · `TimelineEntryRow*` · serialization services. Confirm the
precise list when planning each implementation part.

**Done when** client fixtures support inspect → edit mayonnaise from two tbsp to
one → see the delta → save → reopen with the correction intact, while unaffected
ingredients retain their values. No final share-card layout until Step 7.

**Closed 21 September**, in eight parts, against `meal-contract.md`. Two things
carried forward rather than fixed:

- **`MealBreakdownEditorSheet` holds its own draft-building and validation**, so
  the rule *typing the original amount back clears the correction* is verified by
  tapping, not by a test. The part ran 47% over the size limit and this was the
  agreed cost. Pull it into a pure type when something next touches that file.
- **`MealFixtures.swift` and the `#if DEBUG` button in `ProfileView`** are Step 5
  scaffolding — the only way to get a breakdown onto the timeline before the
  backend sends one. Step 6 deletes both.

---

## Step 6 — Meal backend, references and saved-meal round trip

**The contract is `meal-contract.md`, settled 21 September.** Read it before
anything else; §10 is the list of what this step's normalizer must guarantee, and
a change to the shape is a two-repo edit that Step 6 may not make alone.

- **Implement the contract end to end.** Align the AI schema, prompt, normalizer,
  API responses, Swift models and persistence rules. The existing AI schema
  already requests item nutrition, but `normalizeEstimatedItems` discards it;
  retain it and add the structured component data the client now decodes.
- **Validate, do not trust a fluent explanation.** Two requirements from §10 that
  the current normalizer does not meet and that are real work:
  - **Recompute `feedback.macros` server-side** from the contribution rule (§4),
    rather than copying the model's own `totals`. Totals that reconcile are the
    whole point of the breakdown; a copied number cannot be relied on to.
  - **Enforce item-nutrition XOR priced components.** If the model returns both,
    keep the item's own nutrition and strip nutrition from its components, leaving
    them descriptive. Without this the no-double-counting guarantee is a
    convention rather than a property.
- **No wire compatibility with older builds — decided 21 September.** Firestore
  holds no rows, so this was only ever about TestFlight installs, and testers
  update. So: **delete `estimatedItems`, `EstimatedItem`, `EstimatedItemComponent`
  and `LogEntryEstimatedItemsCard.swift` outright** rather than keeping a read path
  alive for entries that do not exist — the same call as `LogEntryType` in Step 3 —
  send only `breakdown`, and spend no time on response versioning. The `version`
  field still ships, so the mechanism exists the day it starts to matter. **This
  expires at the first real user**, like everything else in *The data is empty*.
- **Preserve photo uncertainty.** Recognition must pass ambiguity and assumed
  quantities to nutrition estimation, rather than turning the most likely guess
  into a user-confirmed fact. Distinguish user text from a generated description.
- **Verify household measures.** *Done 22 September with 16 cases, not 30–50 —
  see `gymfuel-ai-service/evaluation/results.md`.* Agreed to stop there: the two
  problems worth finding turned up by reading output, not by averaging error, and
  the marginal value of cases 17–50 did not look worth the drafting. Originally:
  roughly 30–50 documented meal/recipe
  cases and preparation variants, using weighed recipes or credible references.
  Use Pakistani/home-cooked examples the founder and testers can evaluate, plus
  everyday meals across cuisines. Step 0's brand remains cuisine-agnostic. State
  serving sizes, cooked/raw basis and oil allocated to the eaten portion, not the
  whole cooking pot. A server-side reference file can grow toward 100–200 cases
  later; this is not a searchable food database or a required new user study.
- **Finish saved-meal reuse.** Verify corrected breakdowns, assumptions and source
  information survive saving, re-logging and relaunch. Repeat logging needs no AI
  call. Automatic learning across unrelated meals is outside this launch.
- **Measure quality and cost together.** Use existing usage/cost telemetry for
  text, photo recognition plus analysis, corrections and failed attempts. Compare
  cheaper image models on the same examples before switching; no automatic
  downgrade based on model name. Exercise interpretation stays removed.
- **Rewrite the gym-oriented prompt.** Nutrition estimates describe the meal and
  its assumptions, without a generic goal verdict. Raw goal tokens need not change;
  rename only as a coordinated compatibility-aware edit if it adds value.

**Done when** both text and photo paths produce one meal with editable items,
totals reconcile, quantity edits preserve unrelated items, saved versions round-
trip correctly, and per-completed-meal cost and observed errors are recorded.

**Closed 22 September**, in nine parts. Five things carried forward rather than fixed:

- **Scoped reinterpretation (`meal-contract.md` §9) was not built.** §9 says "built in
  Step 6"; the Step 6 bullets and its done-when never mention it, and whole-meal
  *Edit with AI* already works. Decided out on 21 September. The contract section
  stands as the design for whenever it lands.
- **16 verification cases, not 30–50**, as above. `evaluation/` holds the harness:
  30 USDA-pinned ingredients, the cases, and a results file that regenerates.
- **Most assumptions carry no number** — 19 of 69 did. A prompt demanding numbers in
  every assumption was tried (`meal-v14`) and rejected as worse to read; only its
  fat-separation rule was kept, as `meal-v15`.
- **Per-meal quality telemetry was built and reverted.** Cost is already recorded by
  the existing `logAIMetrics`; breakdown-quality signals live in the evaluation
  harness instead of in the request path.
- **The client still sends `goal`** and still maps `interpretation/invalid-goal`,
  which the server can no longer return, after scoring was removed on 22 September.

---

## Step 7 — Visual sweep and final share card · M

The screens no other step rebuilds. Step 6's meal-editing front end is complete;
its backend work can proceed separately. These parts are presentation and
navigation work. Do not change the meal contract or editor behavior here. Each
part gets its own plan and manual check before the next starts; if its code change
looks likely to exceed roughly 200 lines, split that part before implementation.
Keep the parent Step 7 box unticked until every part is done.

- [x] **7a · Welcome.** Apply the Circa auth pattern to the first screen, including
  the entry points to Sign up and Sign in. Keep the existing auth actions. **Done
  when** Welcome works in light/dark and at large text sizes.
- [x] **7b · Sign up, Sign in and password reset.** Carry the same pattern through
  the forms and reset sheet, preserving validation and Firebase Auth behavior.
  **Done when** each auth path, error and reset confirmation is readable and usable.
- [x] **7c · Onboarding metrics, part one.** Use one repeatable visual pattern for
  gender and age; preserve their existing values and validation. **Done when**
  both steps match the Circa system without changing their answers.
- [x] **7d · Onboarding metrics, part two.** Apply that pattern to height, weight
  and activity. Weight remains an onboarding input and later a weigh-in, never a
  directly editable Settings value. **Done when** all five metric steps read as one
  sequence in both themes and at large text sizes.
- [x] **7e · Settings hub.** Restyle the Profile/Settings landing screen and its
  reusable rows; link the existing Your targets and Weight screens without
  changing either screen's rules. **Done when** every row has a clear destination
  and the hub uses Circa tokens.
- [x] **7f · Settings details.** Restyle reminders, appearance, account deletion
  and the remaining settings sheets. Preserve reminder scheduling, theme choice,
  reauthentication and deletion behavior. Show weight but offer no direct edit.
  **Done when** each settings path and its destructive confirmation works in both
  themes.
- [x] **7g · Saved meals and sources.** Finish the saved-meal picker/list and
  Nutrition Sources presentation. Align source wording with the final estimate,
  assumptions and provenance. Steps 5–6 retain ownership of editor behavior and
  saved-meal persistence. **Done when** a corrected saved meal is easy to find and
  reuse, and sources make no accuracy claim the estimate cannot support.
- [x] **7h · Day/Week picker.** Build the two-scale Day/Week navigation and the
  date jump. No Month view. State that older days can be read but logging is limited
  to today and the previous seven days. **Done when** switching scale/date preserves
  the selected day and never offers a log action outside that window.
- [x] **7i · Menu and destinations.** Replace the separate flame/gear entry points
  with the menu from `design.md`; add Weight and Your targets rows to their already
  built screens. Keep the Week weight card route. **Done when** those destinations
  are reachable from the menu and existing routes still work.
- [x] **7j · Paywall and remaining onboarding chrome.** Apply the light/dark Circa
  treatment, replace emoji with SF Symbols, and use launch-accurate reminder and
  plan copy. Keep all six paywall requirements in `CLAUDE.md`, including live
  StoreKit price/trial text and a visible dismiss control. **Done when** the paywall
  and onboarding summary fit the same visual system without changing purchases.
- [ ] **7k · Final meal share card.** After the Step 6 backend returns the final
  meal shape, render the selected meal's image, description, nutrition, key
  assumption and explanation with a watermark; export through the system share
  sheet. Share only that meal, not weight, targets or other meals. **Done when** a
  corrected text or photo meal produces a readable card and the system share flow
  works. Destination-specific variants and one-tap Instagram posting are outside
  this part.
- [ ] **7l · Legacy visual cleanup.** Audit remaining views in both themes and
  at accessibility text sizes, replace residual old-palette styling and view emoji,
  then delete `Color.liftEatsCoral` and the four `Fuel*` colorsets once unused.
  Limit any touches to completed Step 5–6 screens to presentation. **Done when**
  no screen renders from the old palette and no view code contains emoji.

**Done when** no screen in the app still renders from the old palette, a walk
from launch to paywall to settings looks like one app in both themes, and the final
meal card can be exported through the system share sheet.

> **The visual sweep is not on the cut list.** Optional share-card variants can
> wait, but the core visual consistency cannot. Shots 01–06 use these screens, and a listing that
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

Six captions, in `store-copy.md`. Shots 01–03 and 06 need Steps 5–6; 04–05 need the
completed Step 4. **All six need Step 7.**

Before shooting, confirm text/photo logging, reconciled totals, predictable edits,
saved-meal reuse, assumption explanations, failure recovery and cost telemetry. Use
existing TestFlight participants for a focused pass through the changed experience.
Keep broader onboarding, trial and pricing experiments after launch.

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

Reduce optional breadth first; do not reopen completed Steps 0–4.

1. **Reference-set expansion** — keep the documented launch cases; defer growth
   toward 100–200 and additional cuisine coverage.
2. **Step 9's cross-localization** — the primary locale alone is a valid listing.
3. **Share-card variants and destination-specific integrations** — keep one
   readable card and the system share sheet.

Steps 12 and 14 are not on this list. They are after approval either way, and
Step 13 already shipped as 4a2.

**Required for launch:** completed Steps 0–4, the editable meal and saved-version
contract (5–6), and the coherent visual sweep (7).

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
