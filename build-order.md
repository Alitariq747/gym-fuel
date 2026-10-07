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

**Widgets ship at launch**: Step 14 was built early, on 3–4 October. Step 12 now uses fixed daily reminders
with polished copy; the state-aware experiment was removed on 2 October. The core
repeat-use experience ships at launch:
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
- [x] **7** · Visual sweep and final share card
- [x] **8** · Rename
- [ ] **9** · App Store Connect metadata
- [ ] **10** · Screenshots and submit
- [ ] **11** · After approval — CPPs, creator outreach
- [x] **12** · Fixed daily reminders · *simplified, 2 October; device checks pending*
- [x] **13** · HealthKit body mass — done early as 4a2
- [x] **14** · Widgets · *built 3–4 October; device checks pending*
- [x] **15a** · Onboarding: the guest meal route (backend)
- [x] **15b** · Onboarding: the live meal screen
- [x] **15c** · Onboarding: one edit, its result shown prominently · rating request after the first saved correction
- [x] **15d** · Onboarding: the logging-problem question and the plan callback · no preselected goal
- [ ] **15e** · Onboarding: a paywall that continues the story

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

Reminders default to `.quiet`. Onboarding now offers the opt-in as well as
Settings → Reminders. Step 12 was simplified on 2 October to fixed daily
reminders with polished copy; the paywall makes no smart-reminder promise.

**Where it goes: between `loggingTips` and `summary`.** Not after the summary —
`OnboardingSummaryStepView` commits the profile through `RootView.saveOnboarding`,
which fires `SubscriptionPaywallSheet` on success. An ask placed after it competes
with the paywall sheet for the same moment.

**Soft pre-prompt, not the system prompt.** The step explains the fixed schedule
and offers **Enable** and **Not now**. Only Enable may request system permission;
Not now selects Quiet and clears existing reminders without prompting. A denied
permission can be changed in iOS Settings. Nothing asks on screen appearance.

1. New `OnboardingNotificationsStepView`, plus the case in the `private enum
   OnboardingStep` at `OnboardingFlowView.swift:10` and its `analyticsName`.
2. The stored mode changes from `.quiet` to `.normal` after successful Enable;
   **Not now** selects `.quiet`. The unset preference continues to default to Quiet.
3. Copy and schedules live in `ReminderService`; neither mentions workouts.

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
weigh-ins. No caveat line goes under it: the sentence that did was removed on
26 September, because "about" and the dotted rule already say it is an estimate. A
number that claims to *measure* what this person burns is still out.

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

- **Protein 2.0 g/kg losing, 1.6 g/kg maintaining or gaining** (revised
  24 September; it was a flat 1.6). At or above maintenance 1.6 is the ceiling —
  muscle gain stops improving there even for lifters (Morton 2018). In a deficit
  the job changes from building muscle to keeping the muscle already there, and
  the studied range rises to 1.8–2.5 g/kg (Helms 2014, Longland 2016), with
  Morton's own interval reaching 2.2. Protein also keeps a dieter full (Leidy
  2015). Users who want more can type it.
- **The deficit raises protein, not the training.** Activity already feeds the
  calorie target, so a second question about training would count it twice — and
  a sedentary dieter needs the higher protein just as much. Do not key this off
  activity level, and do not add a training question to get at it.
- **Fat 0.8 g/kg**, 0.9 when gaining.
- **Both use the lower** of the goal weight and the top healthy weight for the
  person's height (BMI 25), so a bigger body does not get 300 g of protein and no
  carbs. *Maintain* uses the current weight in place of a goal weight. That cap is
  also what keeps the basis near lean mass, which is the weight 2.0 g/kg is
  measured against.
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
- **Users edit any of the four, and the app asks rather than guessing** (revised
  24 September; it was calories, protein and fat with carbs filling the rest). A
  typed number stands and the other three stay put until the user picks how to
  reconcile them — nothing is saved until they do. After a **calorie** edit the
  answer is fresh macros from the rules above. After a **protein, carb or fat**
  edit there are two: raise the calories to cover what was typed, or hold the
  calories and let the untouched macros absorb it in proportion. When every macro
  has been typed there is nothing free to absorb, so only the first is offered.
  The calorie floors hold on every path.
- Carbs are therefore no longer guaranteed to be the remainder of a saved target.
  Nothing recomputes them on read, so a typed value survives exactly as typed.
- Editing targets does not redraw the plan line; **Recalculate** does, because it
  re-anchors to the latest weigh-in and today (decided 19 September).

**Goal weight.**

- Asked after *Gain / Lose fat / Maintain*, on the matching side of current weight.
  *Maintain* skips it and gets a flat line.
- Changing goal, goal weight or activity recalculates the targets and restarts the
  plan line from the latest weigh-in and today.
- Reaching the goal changes nothing by itself. The app says so, and the user picks
  *Maintain* or a new goal.

**Store only the current plan and targets**, overwritten in place, never a history.
Past days therefore show against the current targets. Accepted.

**The Weight screen** draws a solid line through the weigh-ins, exactly as weighed,
and the goal as a dashed line. No trend and no plan line: both were dropped on
6 October, and only the onboarding plan screen keeps the plan line. It uses no red,
no green and no "behind" copy, and lets only manual weigh-ins be deleted. Nothing
edits a weigh-in.

### 4a — Weigh-ins and the trend · done 12 September

- A `weighIns` collection, one row per day. `EditWeightSheet` writes the history row
  first, then `UserProfile.weightKg`, sequentially rather than batched: a batch
  fails atomically, so a rules rejection on the profile half would discard a
  correct weigh-in.
- The trend weight built here (an EMA) was dropped on 6 October. Weigh-ins are
  drawn as weighed; nothing is smoothed.
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
   table (FAO/WHO/UNU 2004), protein (Morton 2018, Leidy 2015, Helms 2014,
   Longland 2016), the calorie floor and the BMI limits.

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

1. **Chart** (revised 6 October): a solid line through the weigh-ins, and a dashed
   goal line when the goal is within 10 kg of the weigh-ins in view. **30d · 90d ·
   All** (90d first) only change how much is in view, each starting no earlier
   than the first weigh-in. Tapping the chart shows the nearest weigh-in's day and
   weight. The screen reads every weigh-in. Above the chart, the last weigh-in and
   its date; below it, a goal card ("6.5 kg to go") and **Weigh in**. *Maintain*
   shows no goal.
2. **List** of weigh-ins below it, newest first, showing where each came from.
3. **Delete manual weigh-ins only.** A deleted Apple Health row would come back on
   the next open, because the import fills any day without a row
   (`WeighInImportPlanner.plan`), so a Health row says to change it in the Health
   app. `firestore.rules` has no `delete` on `weighIns` today; add it for the owner,
   manual rows only. Deleting the newest weigh-in sets `weightKg` back to the one
   before it.
4. **"Adjust targets"** opens 4d.
5. **Goal reached** (by the last weigh-in): a plain note and a way to pick
   *Maintain* or a new goal. Nothing changes on its own.

**Files** new `WeightView.swift` · `WeighInService.swift` · `firestore.rules` ·
`WeightTrendCard.swift` · `StatsView.swift` · `UserProfileViewModel.swift`

**Done when** backdated Apple Health weights show as a line of dots,
a deleted manual weigh-in stays gone after a relaunch, a Health weigh-in cannot be
deleted, and reaching the goal shows the note without changing a target.

### 4f — The plan screen in onboarding · M

**What the user gets:** before the paywall, a plan they can read: where they are
headed, roughly when, and why each number is what it is.

1. **Rebuild the summary step** (`Onboarding · your numbers` on the canvas) as the
   plan screen, in the same place. `saveOnboarding` still fires the paywall.
2. **Chart** to the goal date, reusing 4e's chart. *Maintain* shows no date.
3. **One reason per target**, in a card of their own under the targets (revised
   26 September). Calories are a sum rather than a sentence: "To stay at your
   weight · about 2,420", "To lose about 0.4 kg a week · − 470", then the target.
   Protein, carbs and fat follow, one line each.
4. **Edit** with 4d's editor before continuing — the link sits between the two
   cards.

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
  fat-separation rule was kept, as `meal-v15`. **Superseded by the model change
  below**: `gpt-5.6-luna` returns 38 of 55 with a number, unprompted.
- **Per-meal quality telemetry was built and reverted.** Cost is already recorded by
  the existing `logAIMetrics`; breakdown-quality signals live in the evaluation
  harness instead of in the request path.
- **The client still sends `goal`** and still maps `interpretation/invalid-goal`,
  which the server can no longer return, after scoring was removed on 22 September.

**Both models changed on 23 September, after closing.** Text `gpt-5.4-mini` and
vision `gpt-5.4` both became `gpt-5.6-luna`: 72% cheaper, mean absolute error 15%
on the 16 cases against mini's 12–16%, worst case 29% against mini's 45%, and
markedly more readable assumptions. Vision was compared by eye on the same
photos. **`.env` is `.gcloudignore`d, so Cloud Run needs both variables set
there** —
`imageRecognizer.js` still defaults to `gpt-5.4`.

The run also checked per-node density against USDA for the first time — flour 364
against 364, bacon 540 against 541, and 61 of 64 nodes agreeing with their own
macros. **So `meal-contract.md` §4's `nutrition × scale` rests on measured ground,
and the remaining error is portion assumptions** — what the editor already exposes.
A quantity edit must still never call the model: the same input moved one dish 44
points across three runs, so re-asking would add noise to a correction.

**Two references were corrected the same day** — aloo paratha flour and filling,
chowmein oil. A pizza slice-weight change was tried and reverted: 80 g a slice is
right for a 12-inch pizza, and the real weakness in `it-margherita-pizza` is that
its pinned USDA food is a *frozen* pizza. `results.md` regenerates; reports from
before these corrections are not comparable and were deleted.

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
  *6 October:* Day and Week no longer share a date. Week always opens on the
  current week and paging it never moves the Day screen, so "preserves the
  selected day" no longer applies.
- [x] **7i · Menu and destinations.** Replace the separate flame/gear entry points
  with the menu from `design.md`; add Weight and Your targets rows to their already
  built screens. Keep the Week weight card route. **Done when** those destinations
  are reachable from the menu and existing routes still work.
  *28 September:* the menu was replaced by Week and Settings icons in the Day
  header. Weight and Your targets were repeats — each is reachable from Settings,
  and Weight from the Week weight card.
- [x] **7j · Paywall and remaining onboarding chrome.** Apply the light/dark Circa
  treatment, replace emoji with SF Symbols, and use launch-accurate reminder and
  plan copy. Keep all six paywall requirements in `CLAUDE.md`, including live
  StoreKit price/trial text and a visible dismiss control. **Done when** the paywall
  and onboarding summary fit the same visual system without changing purchases.
- [x] **7k · Final meal share card.** After the Step 6 backend returns the final
  meal shape, render the selected meal's image, description, nutrition, key
  assumption and explanation with a watermark; export through the system share
  sheet. Share only that meal, not weight, targets or other meals. **Done when** a
  corrected text or photo meal produces a readable card and the system share flow
  works. Destination-specific variants and one-tap Instagram posting are outside
  this part.
- [x] **7l · Legacy visual cleanup.** Audit remaining views in both themes and
  at accessibility text sizes, replace residual old-palette styling and view emoji,
  then delete `Color.liftEatsCoral` and the four `Fuel*` colorsets once unused.
  Limit any touches to completed Step 5–6 screens to presentation. **Done when**
  no screen renders from the old palette and no view code contains emoji.

> **7m–7t were added on 23 September**, after a sweep of these screens produced
> colour-only changes. Parts 7a–7l never name the Day screen, the Week screen,
> the entry detail sheet or the composer, because the ordering above assumed
> Steps 3, 5 and 6 would each ship their own surfaces in the new language. They
> did not. `Color.liftEatsCoral` and the `Fuel*` colorsets are gone and no view
> code carries emoji, so 7l's own done-when holds — what is left on these four
> surfaces is **typography and shape**. The kit's `CircaMacroBars`, `CircaDock`,
> `CircaEntryRow` and `CircaEstimate` were written for the Day screen and the
> Day screen uses none of them, so the certainty rule (`design.md` rule 1) does
> not appear there at all. These parts are mostly adoption and deletion.
>
> Build them from the canvas artboards, corrected by `design.md`'s *Canvas
> drift* table. `page-2` of the canvas is the round that lost: the live Entry
> artboard is `DetailB`, not `DetailA` or `DetailC`.

- [x] **7m · Day summary and dock.** `DailyMacroDetailSheet` takes `CircaCard` and
  `CircaMacroBars`; `LogActionDock` takes `CircaDock`. **Done when** the summary
  card and dock match the `Day` artboard and hold at AX3 without truncating.
- [x] **7n · The journal row, settled.** `TimelineEntryRow` takes `CircaEntryRow`
  and `CircaEstimate`; rows sit on paper rather than in cards; the metrics view
  folds into the mono meta line. **Done when** a logged meal shows a dotted
  calorie number and the row goes vertical at AX3.
- [x] **7o · The journal row, analysing and failed.** Built from
  `Analysing · text + photo` and `Failed · retry`. **Done when** a pending row
  shows the rule alone and nothing jumps as the estimate lands, and a failed row
  keeps the sentence and the photo.
- [x] **7p · The Day screen frame.** Paper, the `Today ⌄` header, the empty day,
  and a horizontal swipe replacing the date chevrons. **Done when** the Day
  screen matches the `Day` and `Empty day` artboards and swiping still respects
  the today−7d window.
- [x] **7q · The text entry sheet.** Built from `Composer`. **Done when** no
  point size is hardcoded and the sheet scales to AX3.
- [x] **7r · Entry detail, the top half.** Built from `Entry`: hero, the raw
  sentence as title, the dotted total and macros. **Done when** the total carries
  the certainty rule and the title scales.
- [x] **7s · Entry detail, the analysis cards.** Remove the confidence ring and
  the numeric confidence per `design.md`; give the assumptions the room.
  **Done when** no screen presents model confidence as an accuracy figure.
- [x] **7t · The Week screen.** `StatsView` and its cards take `CircaCard` and
  the Circa type scale; the streak tile goes. Its data is not used by reminders.
  **Done when** the Week screen shows the week's food and the weight card, with
  no check-in, no burn number and no streak.

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

# Retention

Fixed daily reminders (Step 12) ship at launch; their state-aware experiment was
removed. Widgets (Step 14) were built early and ship at launch, in their own target. Step 13
was pulled forward into the launch build as 4a2.

**App Intents, Siri, Shortcuts and Control Center controls are out.** Decided
7 September — too much lift for this stack, and widgets do not need them. See
`project-brief.md`. **Push notifications are parked, not rejected** — there is no
APNs setup and no push entitlement today, and Step 12 does not need one.

---

## Step 12 — Fixed daily reminders · complete

**Simplified 2 October.** The state-aware experiment has been replaced with fixed,
repeating local notifications. No meal/weight reads, weekly weigh-in reminder,
suppression after logging, inactivity taper, or notification-specific navigation.
Tapping opens the app normally. No APNs, backend, or new dependency.

- **Quiet** is the default: no reminders. **Normal** repeats at 9:00 AM, 2:00 PM
  and 8:30 PM. **Frequent** repeats at 8:00 AM, 11:00 AM, 2:00 PM, 5:00 PM,
  8:00 PM and 10:00 PM. Its stored value remains `aggressive`.
- Copy is fixed by time slot in `ReminderService.swift`: breakfast, snacks,
  lunch, a note, dinner, and a last opportunity to add something. No claims about
  whether the person logged, no streak language, and no nutritional judgments.
- Onboarding offers three daily reminders; Settings explains that they arrive
  even after logging. Only an explicit enable tap can request permission.
  **Not now** selects Quiet and clears existing Circa reminders without prompting.
- One serialized queue owns notification replacement and preference updates.
  Explicit enable failures clear partial requests and select Quiet. Automatic
  restoration preserves the preference and reports failures through telemetry.
- Signed-in launch, sign-in and return from background restore the saved mode
  independently of profile loading or Health imports. Canceled or stale account
  callbacks are rejected before enqueueing. Sign-out and signed-out launch clear
  pending and delivered Circa reminders, retaining the saved mode for sign-in.
  Onboarding asks and saves the choice without scheduling; reminders start once signed in.
- Prefix cleanup removes old repeating and experimental one-shot requests under
  `lifteats.reminder.`; unrelated notifications remain untouched. Repeating
  requests use stable time-based identifiers. The old weekly-toggle preference
  is unused and may remain on devices that ran the experiment.

**Validation:** all 20 `ReminderServiceTests` pass in an isolated macOS Swift
package, covering schedules and copy, repeating triggers, mode transitions,
migration, permission handling, partial failures, sign-out during an in-flight
apply, and canceled lifecycle callbacks. The iOS-only ephemeral-authorization
test, iOS Debug/Release builds and device checks remain for the user to run.
Swift 6 service type-checking, changed-source parsing and `git diff --check` pass.

**Device acceptance — still required:**

1. Settings → Logging Reminders → Normal, Frequent, then Quiet. Verify exactly
   three, six, then zero pending Circa requests, with the documented times/copy.
2. Enable reminders, log a meal and a weight, and confirm the schedule is unchanged.
3. Sign out: pending and delivered Circa reminders clear. Sign in: the saved mode
   returns, without a permission prompt. Repeat during an in-flight mode change.
4. Test onboarding Enable and Not now, deny permission, then enable it in iOS
   Settings and return. Relaunch and repeat offline.
5. Tap a delivered reminder with the app terminated, backgrounded, and with
   Settings or a sheet already open. It should open normally without redirecting.
6. Launch over an install containing experimental one-shot requests; confirm only
   the selected repeating schedule remains. Complete Debug/Release builds.

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

The passive half of the retention loop. Read-only. Drawn on the canvas, row 8
(2 October); `design.md` owns the look.

**No Firebase in the extension.** A widget process cannot practically reach
Firestore — its own auth via keychain access groups, a cold start, a network
round trip, and a read burned on every timeline refresh. The design is one-way:
the app writes a small `Codable` `TodaySnapshot` into an App Group container
whenever today's entries or the saved target change, then calls
`WidgetCenter.shared.reloadAllTimelines()` — there is one widget kind, so no name
has to match in two places. The widget reads only that file.
The Day screen (`MainTabView`) writes it, because it holds both the entries and
the target, and only while it is showing today. Decided 3 October.

**The widget learns only what the app writes.** A meal that finishes estimating
while the app is closed reaches the widget the next time the app opens, or is
replaced at midnight. Accepted 3 October: the alternatives are push or Firebase in
the extension, and both are out.

Snapshot: the day it describes; target and eaten calories, protein, carbs and
fat, with eaten counting settled entries only; how many entries are logged; and
whether any settled nutrition is an estimate, which decides the dotted rule. **No
burn, streak or weight field** — see Steps 3 and 12. **No estimating count:** the
widget never says a meal is still estimating; an unsettled meal is simply not
counted yet, as on the Day card. Dropped 3 October as overkill.

**A snapshot from an earlier day rolls over.** At midnight the widget shows a new
day from the saved target: the whole target left, nothing eaten. Targets change only
when the person acts, so the saved target is still right. The timeline holds two
entries: now, and the next midnight. With no snapshot at all — never opened, signed
out, or no saved target yet — the widget asks the person to open the app.

- **Sizes:** `systemSmall` (calories left), `systemMedium` (adds the macro card),
  and on the Lock Screen `accessoryInline`, `accessoryCircular` and
  `accessoryRectangular`. No large widget.
- **The mascot appears on home-screen widgets only, never the lock screen,** and
  never reacts to the numbers (`design.md`, mascot rules 8 and 9). On the lock
  screen, progress is the system gauge: one ring, calories only. **It also hides
  whenever iOS is not drawing in full colour** — tinted and clear home screens
  (iOS 18+) recolour it, which mascot rule 7 forbids. Decided 3 October.
- **Light and dark follow the phone,** not the in-app appearance setting, which
  cannot reach a widget cleanly. Decided 3 October.
- **A tap opens the app where it was left.** No `widgetURL` and no deep link:
  a fresh launch starts on today, and a resumed app keeps its day and any open
  sheet. The "go to today" link was dropped on 4 October as not worth it. **No
  App Intents.**
- **Free.** No entitlement check; the extension couldn't reach RevenueCat anyway.
- **The number shows on the Lock Screen** whenever the screen is on, with no
  privacy hiding. Decided 2 October.
- **Signing out and deleting the account delete the snapshot** and reload the
  widgets, so the next account never sees the last one's day.
- **No app name** in the widgets or the gallery text, because the name may change
  again.
- **App Group:** `group.com.ahmad.GymFuel`. Step 8 kept the bundle identifier, so
  this is settled.
- **The extension's version and build numbers always match the app's.** Raise
  both together for every upload; App Store Connect flags a mismatch.

**Files** new `TodayWidgetExtension` target (`TodayWidget/`) · shared with it:
`TodaySnapshot.swift`, `TodaySnapshotStore.swift`, `TodayCopy.swift`,
`PlateMascot+Today.swift`, `Macros.swift`, `CircaTheme.swift`,
`CircaComponents.swift` and the mascot · app only: `TodaySnapshot+Entries.swift`,
the write point on the Day screen, the clear on sign-out and deletion · a still
mode for `PlateMascot.swift` · `CircaMacroBar` pulled out of `CircaMacroBars` ·
the Mascot and Macros drawings moved to `SharedAssets.xcassets` · entitlements on
both targets · tests for the snapshot, the copy and the pose

**Done when** the widget matches the app within one refresh of a log, a cold device
shows the open-the-app state rather than zeros, and the widget rolls over at
midnight without the app opening.

**Built 3–4 October** in seven parts. Things the canvas does not say:

- **Text size.** The small widget stays at standard size — one step larger runs
  its last line into the mascot. The medium headline grows one step; its macro
  card does not, or the three columns stop fitting on an SE. The Lock Screen
  grows one step.
- **The small widget's mascot sits 4 pt below the canvas**, so a descender in the
  last line clears the plate.
- **The Lock Screen ring keeps the system gauge's own size** (about 58 pt) in the
  rectangle too; squeezed to the canvas's 40 pt it spills over the number. The
  inline line is text only — a custom image there was judged too unreliable.

**Validation:** 40 tests across `TodaySnapshotTests`, `TodayCopyTests` and
`TodayMascotTests`. Every home-screen and Lock Screen state was rendered in the
simulator, light and dark, at the regular and SE sizes and the largest allowed
text. Device checks still owed: the overnight rollover without opening the app, a
Lock Screen read while locked, a cold install showing "Your day shows here", and
Debug and Release builds after the last part.

---

## Step 15 — Onboarding: their own meal, live · L

Added 7 October 2026 from the onboarding research session. Five parts, 15a–15e,
each under the ~200-line limit and each in its own session.

**The problem.** Onboarding *describes* Circa's difference twice and never lets
anyone *have* it. Every AI route sits behind `requireActiveProSubscription`
(`logEntryRoute.js`), so nobody gets a real estimate before the paywall; the one
thing that sets Circa apart arrives as a static eggs-and-toast card
(`OnboardingLiftEats.swift`). Nine of the thirteen steps ask about the body or for a
permission; none asks about the person's food or why tracking failed before. The
paywall is the same generic sheet as the in-app gate, and the first open is an
empty journal.

**The idea.** Cal AI's aha depends on the number being right: "it knew." Circa's
aha is **the correction**: "it assumed two spoons of oil, I changed it to one, and
the total followed." That still works when the first guess is off, and it is the
one thing a database app cannot demo. So the onboarding moment **ends on the
person's edit, not on the AI's number**, and that meal then follows them to the plan
screen and the paywall. It is not saved — dropped 7 October (15c).

### Screen order

Today:

```
Welcome → liftEatsIntro → liftEatsDifference → gender → age → height → weight
  → activityLevel → goal → goalWeight* → loggingTips → appleHealth* → notifications
  → summary → Save your progress (sign-in) → paywall
```

After Step 15:

```
Welcome → liftEatsIntro → loggingProblem (15d) → tryMeal (15b, 15c) → gender → age
  → height → weight → activityLevel → goal → goalWeight* → appleHealth*
  → notifications → summary, now with their meal (15d)
  → Save your progress (sign-in) → paywall, now with their plan and a trial timeline (15e)
```

`*` conditional exactly as today: no goal weight on Maintain, no Health step where
Health is unavailable.

- **`liftEatsIntro` stays first and unchanged.** "Four numbers for one dish. None
  of them yours." is the strongest screen in the flow.
- **`loggingProblem` comes straight after it**, while the problem is fresh.
- **`tryMeal` comes before the body questions.** The aha lands in the first minute
  and gives people a reason to sit through height and weight.
- **`liftEatsDifference` and `loggingTips` leave the flow.** The live meal shows
  what the first one only described, and its assumptions teach what the second one
  explained ("a little detail helps") on the person's own words.
- **Sign-in stays after the plan, and the paywall stays last.** Already right.
- **Step count stays at 13.** Two screens in, two out. Between 15b and 15d it is
  12: 15b removes two and adds one.

Both the order in `orderedSteps` and the literal destinations change. Today
`goal` (Maintain) and `goalWeight` point at `.loggingTips`; after 15b they point at
`healthStepAvailable ? .appleHealth : .notifications`, the check `loggingTips` uses
now. Until 15d lands, `liftEatsIntro` points straight at `.tryMeal`.

### Rules that hold across all five parts

- **Example meals are staples spread across cuisines** — "2 eggs, toast and tea",
  "rice with chicken stew", "a bowl of noodles with vegetables". No cuisine's units
  as a default.
- **No invented numbers.** No "87% of people feel the same", no "users lose 2×
  more". We have no such data, and health claims fall under App Store 1.4.1.
- **No fake loaders.** The live meal's wait is real (5–9 s), so showing it work is
  honest. No "Building your plan… 97%" screen; the plan is instant.
- **Nothing judges.** No "you have great potential", no pace slider, no verdict on
  how big the meal is.
- **No burn, no exercise question, no rating prompt in onboarding.** Apple's HIG
  says to wait until people have used the app; 15c asks after the first saved
  correction instead.
- **Onboarding never stops on the network.** Every failure falls back to the
  static example and Continue.
- **No new dependencies, no auth changes.** Guest onboarding stays guest.

### Timing — open decision

Step 10 says to keep onboarding experiments until after launch. This is a
structural change rather than an experiment. **Recommendation (7 October): 15a–15c
before submitting, 15d–15e in the first update.** The launch cohort comes from
seeded creators, and with 55% of trial cancellations happening on day 0, its first
session decides whether the launch works. It pushes submission back a few
sessions. Ahmad decides.

---

### 15a — The guest meal route (backend) · ~90 lines

**Built 7 October** (~96 lines). Deploy it before 15b; nothing calls it until then.

**What the user gets:** nothing visible yet. The route the live meal calls, with no
account and no subscription.

1. **`POST /onboarding/tryMeal`** in `logEntryRoute.js`, beside `/interpretText`, so
   it reuses `runRawInputAnalysis` and `sendMealAnalysisError` without exporting
   them. **`runRawInputAnalysis`, not `runTextMealAnalysis`** — the latter needs a
   uid and charges the quota document.
2. **Middleware:** `requireAppCheck` only. No `requireFirebaseAuth`, no
   `requireActiveProSubscription`, no quota read or write.
3. **Text only.** No photo: it costs more, takes longer, and "in your own words" is
   the point. Body `{ text, installId }`; `installId` must be a UUID
   (`UUID().uuidString`), and text goes through `requireTextValue` with a
   200-character cap. Bad input is a 400 and uses no try.
4. **Same response shape as `/interpretText`** — `type`, `title`, `detail`,
   `feedback` — so the client decodes it with existing code and the payload is
   `meal-contract.md`'s. No contract change.
5. **Limits.** Three tries per `installId` (one try, plus room for a typo or a
   second go), counted once the input is valid, so a timeout or server error uses
   one. They reset 24 hours after the install's first try. A fourth gets 429
   `rate-limit/too-many-guest-meal-tries`. The rule lives in
   `src/routes/guestTryLimiter.js`. In-memory per instance, like
   `applyInterpretTextRateLimit`; a Cloud Run restart resets it, accepted.
   - **No per-IP limit — decided 7 October.** Carrier NAT puts many phones behind
     one address, which hits South Asian and diaspora users hardest, and on Cloud
     Run `req.ip` is Google's front end unless `trust proxy` is set.
   - **The install ID comes from the phone**, so the limit stops a real person
     looping, not a script that invents a new ID each time. App Check is the
     actual lock.
6. **Writes nothing to Firestore.** `logAIMetrics` with `route: "/onboarding/tryMeal"`
   and no uid, so onboarding cost shows in the existing logs.

**Timeout — done 7 October.** `OPENAI_TEXT_TIMEOUT_MS` is 25000 in Cloud Run and in
the backend `.env`, and the code fallback in `openaiClient.js:4` is now 25000 too.
The client stops waiting at 20 s (15b); the server call may still finish, accepted
at ~$0.001.

**Cost:** Luna is ~$0.0011 per text call, so at the strategy's 1,400 installs a
month this is about **$1.50 a month**. Abuse costs about $110 per 100,000 calls;
the bigger risk is that the route shares the OpenAI key's rate limits with paying
users. App Check tokens can be reused for about an hour, so one copied through a
proxy can be replayed from a script.

**Upgrade if abuse shows in the logs — later, not now (7 October):** single-use
App Check tokens. `verifyToken(token, { consume: true })` on this route and
`limitedUseToken()` in the app, so a copied token works once. About 10–15 lines in
`appCheckMiddleware.js` plus one in the 15b client.

**Considered, not chosen:** Firebase anonymous sign-in with `link(with:)` at Save
your progress. Cleaner long term, but it rewires sign-in right before launch.

**Files** `src/routes/logEntryRoute.js` · new `src/routes/guestTryLimiter.js` ·
`src/ai/openaiClient.js` · `test/guestTryLimiter.test.js` ·
`test/onboardingTryMealRoute.test.js`

**Done when** a request with App Check and no ID token returns the same shape as
`/interpretText`; a fourth try from one install gets 429; a request without App
Check gets 401; and nothing is written to Firestore.

### 15b — The live meal screen · ~170 lines

**Built 7 October**, in three parts because it came to ~390 lines: the call and
view model (~183), the screen (~153), then the flow wiring, the example and the
removals (~51). About 260 lines of the two old screens went with it.

**What the user gets:** in the first minute, they describe a meal they actually eat
and see what Circa assumed.

1. **New step `.tryMeal`** (`analyticsName` `try_meal`), placed and wired as in
   *Screen order*. Illustration `.hidden`, like the other teaching screens;
   update `OnboardingIllustrationTests`.
2. **One job per type:** a client call to `/onboarding/tryMeal` with no
   `Authorization` header (beside `BackendLogInterpretationService`'s text call, reusing
   its decoding and error mapping), an `OnboardingTryMealViewModel` holding screen
   state (typing, working, result, fallback), and `OnboardingTryMealStepView`, which
   only draws.
3. **Install ID:** a random UUID in `UserDefaults` (`GuestInstallID`, in the service
   file). A reinstall gets fresh tries; accepted at this cost. The text field stops
   at 200 UTF-16 units, the length the backend measures, so emoji and some scripts
   never earn a 400.
4. **Prompt:** "Tell us a meal you often eat." Detail: "Say it the way you'd tell a
   friend." Three tap-to-fill examples from *Rules*. Ask for a *usual* meal, not
   "what did you last eat": it is more likely to be the home-cooked food databases
   miss, and it never has to guess which day to log it on.
5. **While it works:** their own words being read — "Reading 'rice with chicken
   stew'…". The wait is real; no percentages.
6. **Result:** `MealBreakdownCard`, read-only in this part, under "Circa's first
   guess. Anything different?" The top assumption from
   `MealBreakdownCalculator.assumptions(of:)` (already ranked) sits highlighted above
   it, under "Biggest assumption". Continue is enabled.
7. **Fallback:** an error, App Check failure, offline, a 429, or 20 s without an
   answer shows the static example — today's eggs-and-toast card, moved into this
   screen — with "We couldn't reach Circa just now. Here's an example." and
   Continue. A **"Show me an example instead"** link reaches the same state without
   typing, under "Here's an example." No blocking error, no retry loop.
   - **20 s, not 15 — decided 7 October.** About one Luna call in eight takes
     longer than 12 s, so 15 s would show many people the example instead of their
     own meal, after paying for the call.
   - **An answer with no breakdown** has no card to draw, so it goes back to typing
     with their words kept: "Circa couldn't find a meal in that. Try naming what's
     on the plate." The backend's other two tries are for this.
8. **`OnboardingAnswers.triedMeal`** holds the typed words and the decoded result,
   in memory only. Nothing writes it to Firestore (15c).
9. **Remove** `liftEatsDifference` and `loggingTips`: their cases,
   `OnboardingLiftEats.swift`, `OnboardingLoggingTipsStepView.swift`, and the
   `shake_simple`, `shake_refined`, `pasta_simple`, `pasta_refined` images (used
   nowhere else). `eggs_toast_coffee` stays for the fallback.
10. **Telemetry** through `logOnboardingEvent`: `meal_try_submitted`,
    `meal_try_succeeded`, `meal_try_failed_timeout`, `meal_try_failed_offline`,
    `meal_try_failed_server`, `meal_try_failed_limit` and `meal_try_example_shown`.
    Separate event names rather than a reason parameter, decided 7 October, so
    `FirebaseTelemetryService` stays as it is.

**Files** new `OnboardingTryMealStepView.swift` · new `OnboardingTryMealViewModel.swift` ·
`BackendLogInterpretationService.swift` · `OnboardingFlowView.swift` ·
`UserProfile.swift` (`OnboardingAnswers`) · removed `OnboardingLiftEats.swift`,
`OnboardingLoggingTipsStepView.swift` and four images ·
`OnboardingIllustrationTests.swift` · new `OnboardingTryMealViewModelTests.swift`

**Done when** a fresh install types "rice with chicken stew" and sees a breakdown
with a highlighted assumption, airplane mode shows the example and still continues,
and the flow is 12 steps with no `loggingTips` or `liftEatsDifference` — 13 once
15d adds `loggingProblem`.

### 15c — One edit, its result shown prominently · ~150 lines

**Built 7 October** (~137 lines): the rating request (~32), then the edit (~105).

**Rescoped 7 October.** Saving the tried meal as a `SavedMeal` after sign-up was
dropped as more work than value: no snapshot written at sign-up, no "saved to your
meals" line, nothing waiting at first open. The edit stays, because it is Step 15's
idea; nothing in onboarding is written to Firestore. Two parts, rating first.

**What the user gets:** they correct Circa's guess and see, prominently, what their
edit did to the total. Later, the first time they save a corrected meal in the app,
iOS may ask them for a rating.

1. **Rating request — built 7 October** (~32 lines). When someone saves a meal from
   `LogEntryDetailSheet` whose breakdown has at least one adjustment
   (`MealBreakdownCalculator.adjustedParts(of:)` is not empty), and no rating has
   been requested on this install, SwiftUI's `requestReview` runs from the save
   sheet's `onDismiss`, after the sheet has closed and while the toast shows.
   - **The rule lives in `RatingRequestRule`**, pure and tested. The "asked" flag is
     `@AppStorage(RatingRequestRule.requestedKey)`, set whenever it asks.
   - **Never in onboarding.** Apple's HIG says to wait until people have used the
     app, and onboarding saves nothing, so it cannot reach the rule.
   - **iOS decides whether the prompt appears** and caps it at three a year, so
     nothing may depend on it showing. No "Rate us" button.
2. **The edit.** Quantity edits only, with `MealBreakdownEditorSheet` —
   reinterpretation needs another AI call, and the guest route allows one try. The
   edit is invited, never required. The corrected breakdown replaces the guess in
   `OnboardingAnswers.triedMeal`, through the same rule the app uses (§6), so 15d's
   plan card reads the edited total.
3. **Its result, shown prominently.** After an edit the screen leads with what
   changed: the first guess, their total, the difference, and which parts they
   changed. The first guess comes from the breakdown itself — every
   `adjustedQuantity` sits beside the original `quantity` (§6).
4. **Telemetry:** `meal_try_item_edited`.

**Files** new `RatingRequestRule.swift` (+ tests) · `LogEntryDetailSheet.swift` ·
`OnboardingTryMealStepView.swift` · `OnboardingTryMealViewModel.swift` ·
`UserProfile.swift` (`TriedMeal`) · `MealBreakdownCalculator.swift` (+ tests)

**Done when** saving a corrected meal in the app requests a rating once, and saving
an uncorrected meal does not; in a Debug build the prompt always shows, and in
TestFlight it never does, by Apple's design. In onboarding, changing one amount
moves the total, the screen shows the first guess, the new total and the
difference, and nothing appears under saved meals after sign-up.

### 15d — The logging-problem question and the plan callback · ~130 lines

**Built 7 October** (~187 lines), in two parts: the goal step and the meal card
(~51), then the question and its lines (~145). The meal card names the meal by
Circa's `title`, not the typed words, so it fits. The paywall subtitles are not in
`LoggingProblem` yet — 15e adds them with the paywall that reads them.

**What the user gets:** one question about *their* problem, answered back to them
twice, a goal they chose themselves, and a plan that meets their own meal.

1. **New step `.loggingProblem`** (`analyticsName` `logging_problem`) right after
   `liftEatsIntro`. "What makes logging food hard for you?" Single select. The
   options come from Cordeiro 2015, the study the strategy doc already cites:
   - My food isn't in any database
   - I never know the portions or what went in
   - Searching and weighing takes too long
   - I've never tracked before
2. **A pure `LoggingProblem` enum owns all of its copy** — the try-meal detail line,
   the plan-screen line and the paywall subtitle — so each answer's words live in
   one place. Tested.
3. **Every answer changes something later, or the question goes.** It changes the
   `tryMeal` detail line, one plan-screen line (e.g. "No searching, no weighing:
   describe it, check what was assumed, fix what's different."), and the paywall
   subtitle in 15e.
4. **Kept in `OnboardingAnswers` only.** No profile field: nothing uses it after
   onboarding. The choice is logged as an onboarding event so the mix of answers is
   visible.
5. **Mascot:** an existing move, chosen by `design.md` → *The plate mascot*. No new
   drawing. Update `OnboardingIllustrationTests`.
6. **The plan screen meets their meal.** When `triedMeal` exists, a card above
   the targets: "Your rice with chicken stew is about 640 kcal, roughly a third of
   your 1,950." It uses the edited total. The fraction words ("about a quarter",
   "roughly a third", "about half") come from a pure function in `PlanCopy`, tested.
   No judging words.
7. **"How we got 1,950" stays exactly as it is.** It is the honest working Cal AI's
   plan does not show.
8. **The goal step starts with nothing selected.** Today
   `OnboardingTrainingGoalView.swift:18` preselects Gain (`tempSelection =
   .leanBulk`), so anyone who taps Continue without looking gets a Gain plan — and
   this part is what makes that plan feel like theirs.
   - `tempSelection` becomes optional, and Continue stays disabled until a goal is
     chosen.
   - Restoring an earlier answer that is still allowed stays as it is.
   - No other default replaces Gain. Preselecting Lose fat for everyone would be the
     same mistake the other way round.

**Files** new `OnboardingLoggingProblemStepView.swift` · new `LoggingProblem.swift`
(+ tests) · `OnboardingFlowView.swift` · `UserProfile.swift` (`OnboardingAnswers`) ·
`OnboardingTryMealStepView.swift` · `OnboardingSummaryStepView.swift` ·
`PlanCopy.swift` (+ tests) · `OnboardingTrainingGoalView.swift` ·
`OnboardingIllustrationTests.swift`

**Done when** each answer changes the try-meal line and the plan line, a person who
tried a meal sees it on the plan screen against their target, and a person who took
the example sees no meal card. The goal step opens with nothing selected and
Continue disabled until a goal is picked, and going back to it keeps the earlier
choice.

### 15e — A paywall that continues the story · ~130 lines

**What the user gets:** the paywall after onboarding talks about their plan and
their meal, and shows exactly when billing starts.

1. **Post-onboarding only.** `SubscriptionPaywallSheet` takes an optional context
   (plan, tried meal, logging problem). `RootView`'s post-onboarding sheet passes it;
   every in-app gate passes nil and stays exactly as today.
2. **Headline from the saved plan:** "Your plan is ready: 1,950 kcal a day, toward
   75 kg by 14 March." The date comes from `WeightPlan.goalDate`. Maintain, or no
   date: "Your plan is ready: 2,100 kcal a day to stay at 60 kg."
3. **Subtitle** from `LoggingProblem` (15d). 15d left the four subtitles out;
   add them to `LoggingProblem.swift` (+ tests) in this part.
4. **First feature row is their meal.** It must not say "saved": the tried meal is
   not saved (15c, 7 October). Settle the wording in this part. The four existing
   rows follow. No meal, no extra row.
5. **Trial timeline** (Blinkist): *Today* — full access; *Day N* — billing starts
   at `package.localizedPriceString`. N comes from the StoreKit intro offer. Move
   the period maths out of the private `trialLengthText(for:)` into a pure
   `TrialTimeline` type that the button title, the package subtitle and the
   timeline all read, with tests. Not eligible for a trial: no timeline.
6. **No reminder step in this part.** Optional later: a one-off local
   notification the day before billing, shown on the timeline only when actually
   scheduled. It would need its own identifier prefix, because Step 12's cleanup
   removes everything under `lifteats.reminder.`, and notification permission.

**Re-check all six paywall rules** (CLAUDE.md) afterwards: prices only from
`localizedPriceString`, Terms and Privacy present, Restore reachable, the
renewal footer intact, no outside purchase path, the dismiss control visible.

**Files** `SubscriptionPaywallSheet.swift` · new `TrialTimeline.swift` (+ tests) ·
`RootView.swift`

**Done when** a new *Lose fat* account's paywall shows its own calories, goal and
date, its meal as the first row and a timeline whose day count matches the
StoreKit offer, while an in-app gate shows today's paywall unchanged.

### Measuring it

`step_viewed` already gives per-screen drop-off. With 15b and 15c's events, the
number to watch is **the share of people starting onboarding who edit an item in
their own meal**. Compare trial starts for people who edited against those who
didn't — keen people edit more, so it is a signal, not proof.

### Discussed, not scheduled — ask first

- **"Where did you hear about Circa?"** One tap, +1 screen, ~40 lines. No help to
  the aha, but distribution is creator seeding with no ad attribution, and this is
  the cheapest way to learn which creator brought installs. Worth adding before
  Step 11's outreach.
- ~~**First-open nudge** pointing at the saved meal~~ — dropped with the save, 7 October (15c).

**Not copied from Cal AI**, with the reason: the "lose 2× more" chart (1.4.1), "add
calories burned back?" (Step 3), the potential and pace screens (nothing judges),
the plan-building loader (fake), the onboarding rating prompt (HIG), and a discount
wheel on dismiss.

### Evidence

- RevenueCat, State of Subscription Apps 2026: hard paywall 10.7% against 2.1%
  freemium; 55% of trial cancellations happen on day 0, and 84% of 3-day-trial
  cancellations by day 1.
- Cal AI's documented ~40-screen flow has no scan before the paywall
  ([Screens Design](https://screensdesign.com/apps/cal-ai-calorie-tracker/)).
- Duolingo moved sign-up after the first lesson: +20% next-day retention.
- Superwall, 40M paywall opens, 2026: multi-page paywalls 12.41% against 9.07%;
  a goal surfaced on the paywall beats layout tests.
- Blinkist's trial timeline: +23% trial starts, −55% complaints.
- [Cordeiro et al. 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4755274):
  restaurant meals, parties and buffets 2.9–3.6 out of 7 for ease of logging,
  packaged food 6.5; homemade food the most common database gap; about 75 people
  named unknown ingredients or portions; 22 of 94 who stopped had reached their goal.
- IKEA effect (Norton, Mochon & Ariely 2012): effort raises value, but only when
  the task succeeds — hence a quantity edit that cannot fail. Endowed progress
  (Nunes & Drèze 2006): 34% against 19% — the reason for the saved meal waiting at
  first open, dropped 7 October (15c).

---

## If time runs short

Reduce optional breadth first; do not reopen completed Steps 0–4.

1. **Reference-set expansion** — keep the documented launch cases; defer growth
   toward 100–200 and additional cuisine coverage.
2. **Step 9's cross-localization** — the primary locale alone is a valid listing.
3. **Share-card variants and destination-specific integrations** — keep one
   readable card and the system share sheet.

Steps 12 and 14 are not on this list: both are already built, and Step 13
already shipped as 4a2.

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
| ~~Before Step 14~~ | ~~Register `group.com.ahmad.GymFuel` on both App IDs, and add the Widget Extension target in Xcode~~ — **done 3 October:** target `TodayWidgetExtension`, bundle `com.ahmad.GymFuel.TodayWidget` |
