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
  drops the lifting register. **Do not touch the enum raw values** — they are
  persisted on every `logEntry.feedback` and in `users/{uid}`.
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

**One thing that is not free.** `type: food|exercise` discriminates the shared
`logEntries` collection. **Do not migrate.** Keep `LogEntryType` and the *read*
path so historical entries still render; remove every write path and the AI
branch. The read path can go later once it is cold.

**Done when** no code path can create an exercise entry, no surface aggregates a
burn figure, the day view never credits calories back, and old entries still
render without crashing.

> Worth doing the enumerated dead code in `project-brief.md` in the same pass —
> `MainTabGradientBackground`, `SavedMeal.lastUsedAt`, the unused
> `SavedMealsViewModel` helpers, `LogEntryDetailSheet.onSaveMeal`. Same kind of
> work, same risk profile.

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

## If time runs short

Cut in this order. Everything above the line still makes a coherent launch.

1. **Step 7** — day-aware score. Nothing depends on it.
2. **Step 6's portion set** — ship 50 dishes instead of 200; extend later without
   a build, it is server-side.
3. **Step 9's cross-localization** — the primary locale alone is a valid listing.

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
