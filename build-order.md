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

**Custom Product Pages come after approval.** They need no build and get their own
review, so they are genuinely post-launch work — but they need the new screenshots,
so they cannot start early either.

**Retention work comes after approval too.** Steps 12–14 each add a new target, a
new entitlement, or a new review surface, and none of them helps a listing with no
installs. Retention matters once there is someone to retain. The one exception is
Step 3a, which is a leak, not a feature.

---

## Progress

Tick each step as it lands. **This is the source of truth for where we are** — a
fresh session reads this file, not the chat history.

- [ ] **0** · Decisions — name, cuisine, pricing
- [ ] **1** · Paywall: trial length from StoreKit
- [ ] **2** · Vocabulary
- [ ] **3** · Remove exercise and lifting logic
- [ ] **3a** · Notification opt-in in onboarding
- [ ] **4** · The adaptive engine
- [ ] **5** · Food wedge, client
- [ ] **6** · Food wedge, backend
- [ ] **7** · Day-aware goal-fit score · *first to cut*
- [ ] **8** · Rename
- [ ] **9** · App Store Connect metadata
- [ ] **10** · Screenshots and submit
- [ ] **11** · After approval — CPPs, creator outreach
- [ ] **12** · State-aware reminders · *post-approval*
- [ ] **13** · HealthKit body mass · *post-approval*
- [ ] **14** · Widgets · *post-approval*

One branch per step (`git checkout -b step-3-remove-exercise`), one commit at the
end, fresh session for the next one.

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

## Step 0 — Your decisions

Nothing below starts clean without these. None need me.

| Decision | Blocks | Note |
|---|---|---|
| **App name** | Steps 8–10 | Brand word must be **≤ 11 chars** to fit `: Desi Food Tracker`. Check the name is free on the App Store and the handle is available. |
| **Beachhead cuisine** | Steps 6, 9, 10 | Brief assumes desi. Swap is mechanical if not. |
| **Confirm pricing** | Step 9 | $7.99/mo, $54.99/yr, 14-day trial. |

---

## Step 1 — Paywall: the trial string · S

One change, one file, and it is genuinely blocking.

Read trial length from `package.storeProduct.introductoryDiscount` instead of the
hardcoded `"3-day"` at `SubscriptionPaywallSheet.swift:351,364,379`. Nothing in
that file currently references `introductoryDiscount` or `subscriptionPeriod` —
`isEligibleForTrial(package)` reports *whether* a trial exists, never how long.

**Files** `SubscriptionPaywallSheet.swift`

**Done when** the paywall renders "14-day" from StoreKit alone, with no trial
length literal anywhere in the file.

> **Cannot be cut.** It is harmless while the offer really is 3 days. The moment
> Step 9 changes it to 14, the paywall contradicts App Store Connect — a 3.1.2
> metadata-mismatch rejection.

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

## Step 4 — The adaptive engine · L

The biggest step and the riskiest, so it goes early while there is runway to
discover problems.

1. `weighIns` collection + service; `EditWeightSheet` writes both the history row
   and `UserProfile.weightKg`.
2. Trend weight — EMA, `alpha ≈ 0.25`.
3. Expenditure — `meanDailyIntake + (trendDeltaKg × 7700) / days`.
4. `phases` collection — goal, start weight, goal rate.
5. `MacroTargetCalculator` — rate-based, replacing the flat `+250 / −300` at
   `:56-65`. Gain 0.25–0.5 %/wk · Lose fat 0.5–1.0 %/wk · Maintain ±0.5 kg band.
6. `checkIns` collection + the weekly check-in screen.

**Done when** logging a week of weigh-ins and meals produces a check-in that
visibly moves next week's targets, and explains why.

### Two things to leave in place for later steps

Neither is extra work now; both are expensive to retrofit.

- **Keep `source: manual | healthKit` on `weighIns`** even though nothing writes
  `healthKit` until Step 13. Adding a discriminator to a collection that already
  has rows is worse than carrying an unused case for a few months.
- **`checkIns/{weekStart}` must cheaply answer "when is the next one due."**
  Step 12 schedules the weekly nudge off that date, and Step 14's widget may show
  it. If the only way to derive it is replaying the whole collection, both steps
  get harder than they need to be.

> Needs a way to seed data for testing — a week of realistic weigh-ins and logs.
> Worth building a debug seeder rather than tapping through it by hand.

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

## Step 8 — Rename · S

- App name in Xcode: `CFBundleDisplayName` (home screen) **and** the App Store
  Connect name. These are two separate fields; changing one is a common miss.
- Sweep user-facing strings for "LiftEats".

**Done when** nothing user-facing carries the old name.

---

## Step 9 — App Store Connect metadata · M

All of this ships with the version. Copy is written and paste-ready in
`store-copy.md`.

1. Name, subtitle, keywords, description, promotional text.
2. **Intro offer 3 days → 14 days** on both products. Verify the paywall reads it
   dynamically — that is Step 1.
3. Price change to $7.99 / $54.99. Grandfather existing subscribers.
4. **Cross-localization** — two secondary locales, properly. Arabic first: it is
   one of the nine US-indexed secondaries *and* the Gulf localisation we want.
   +160 indexable chars each. **Do not paste the same text into nine slots** —
   Apple rejects that now.

---

## Step 10 — Screenshots and submit · M

Six captions, in `store-copy.md`. Shots 04 and 05 need Step 3 shipped; 02, 03 and
06 need Step 4.

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

Three features, all deliberately held back until the listing is live. Ordered by
cost, cheapest first: Step 12 adds no target and no entitlement, Step 13 adds an
entitlement, Step 14 adds a whole target.

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

## Step 13 — HealthKit body mass · M

Aimed squarely at the engine's weakest link. Step 4's success criterion is "≥40 %
of trialists log a second weigh-in" — a smart scale that already syncs to Health
makes every weigh-in after the first free, with the app closed.

**Read `HKQuantityTypeIdentifier.bodyMass`. Nothing else, in either direction.**

- **No write.** Decided 7 September. `NSHealthShareUsageDescription` only — do not
  add `NSHealthUpdateUsageDescription` for a write path that does not exist.
- **No active energy, no workouts, no steps.** Not as an input, not as displayed
  context. See `project-brief.md` — this is the calorie rebate under a new name.
- Requesting a single type keeps the purpose string narrow, which is what review
  wants. Vague HealthKit strings and unused requested types both draw rejections.
  Cite the actual use: reading weight so targets can track the real trend without
  re-entry.

**Four things that need deciding in the step, not after it:**

- **Which sample wins a day.** `weighIns/{yyyy-MM-dd}` is one row per day; Health
  may hold several. Morning is the trending convention — pick a rule and write it
  down.
- **Manual vs Health precedence** for the same date. Neither should silently
  clobber the other.
- **Read denial is invisible.** iOS does not report denied *read* authorization —
  denied and "no data" both return empty. No "you denied this" UI is possible;
  handle empty as the normal case.
- **iPad has no HealthKit.** Guard on `HKHealthStore.isHealthDataAvailable()`.

Foreground fetch on app open is enough. A weigh-in does not need to land within
minutes, so background delivery and observer queries can wait.

**Files** new `HealthKitWeightService.swift` · the weigh-in service from Step 4 ·
`Info.plist` · `GymFuel.entitlements` · `ProfileEditorView.swift`

**Done when** a weight written in Health appears as a weigh-in and moves the trend,
and a day logged both ways produces one row, not two.

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

Steps 12–14 are not on this list. They are after approval either way.

**Never cut:** Step 1 (rejection risk the moment the trial changes), Step 3's
rebate removal (corrupts the engine), or Step 4 (it is the reason anyone pays).

---

## What I need from you, and when

| When | What |
|---|---|
| Now | The name, and confirmation of the cuisine |
| Before Step 4 | Nothing — I can build and seed test data myself |
| Before Step 9 | App Store Connect access, or you run the metadata changes |
| Before Step 10 | A device to shoot on, and real-looking data to shoot |
| Step 11 | Creator list |
| Before Step 13 | HealthKit capability enabled on the App ID |
| Before Step 14 | An App Group registered, with the bundle identifier settled in Step 8 |
