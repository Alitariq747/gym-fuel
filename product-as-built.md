# LiftEats — The Product As Built

Derived by reading the SwiftUI view tree, the Firestore service layer, the Cloud
Functions, and the Node AI service. Nothing here comes from a README or from
marketing copy. Where copy and schema disagree, the schema is treated as the truth.

Sources: `GymFuel/` (iOS), `functions/src/index.ts` (Firebase Functions),
`/Users/ahmadalitariq/Desktop/gymfuel-ai-service/` (Cloud Run AI service).

---

## 1. Navigation graph

The app has no tab bar and no router. Navigation is a single top-level `Group`
switch in `RootView`, plus per-screen `@State` booleans driving sheets. There are
exactly three `NavigationStack`s: one in `AuthFlowView`, one in
`OnboardingFlowView`, one in `MainTabView`. Everything else is a sheet, a
fullScreenCover, an alert, or a confirmation dialog.

### Top-level gate — `RootView.swift:70`

```
RootView
├── authManager.user == nil ─────────────► AuthFlowView
├── profile != nil && !isOnboardingComplete ─► OnboardingFlowView
├── profile != nil &&  isOnboardingComplete ─► MainTabView
└── otherwise ───────────────────────────► AppLoadingView
```

`RootView` also owns one sheet of its own: the post-onboarding paywall, fired from
`saveOnboarding` when the profile write succeeds and `hasProAccess` is false.

### Unauthenticated branch

```
AuthFlowView  (NavigationStack, path: [AuthRoute])
└── WelcomeView                              ← root
    ├── Sign in with Apple    (inline, no navigation)
    ├── Continue with Google  (inline, no navigation)
    ├── "Sign up"             → push .signUp → SignUpView
    └── "Already have an account?" → push .signIn → SignInView
                                                 └── "Forgot?" → sheet: reset-password form
                                                                → alert: "Reset link sent"
```

All four sign-in paths land back at `RootView`, which re-evaluates on
`authManager.user`.

### Onboarding branch — linear, 11 or 12 steps

`OnboardingFlowView` holds `step: OnboardingStep` and animates between step views
in place. There is a back chevron and a progress bar; there is no skip-to-end and
no way to exit to the main app.

```
liftEatsIntro → OnboardingLiftEats → GoalFitScoreExplainerSheet
  → [OnboardingNameStepView]      ← only when showsNameStep (email/password accounts)
  → OnboardingGenderStepView → OnboardingAgeStepView → OnboardingHeightStepView
  → OnboardingWeightStepView → OnboardingActivityLevelStepView
  → OnboardingTrainingGoalStepView → OnboardingLoggingTipsStepView
  → OnboardingSummaryStepView  ──"Start Tracking"──► RootView.saveOnboarding
                                                     └── success + no Pro → SubscriptionPaywallSheet
```

`OnboardingSummaryStepView` renders only when all five required answers are
non-nil, so `finishOnboarding`'s guard is unreachable in practice.

### Main branch

```
MainTabView  (NavigationStack; nav bar hidden)
│
├── MainTabHeaderView
│   ├── ‹ chevron  → previous day (unbounded backwards)
│   ├── › chevron  → next day, or "Future logging is not allowed" toast
│   ├── 🔥 flame   → sheet: StatsView (own NavigationStack)
│   └── ⚙︎ gear    → push: ProfileView
│
├── DailyMacroDetailSheet   (inline card, despite the name — not a sheet)
├── MainTabTimelineContentView → TimelineEntryRow
│   ├── tap        → push: LogEntryDetailSheet   (a push, despite the name)
│   ├── retry      → composer retry (gated on Pro)
│   └── delete     → detail view model delete
│
└── LogActionDock  (hidden outside the today−7d…today window)
    ├── camera  → AVCapture permission → fullScreenCover: MealCameraCaptureView
    ├── photo   → .photosPicker (system)
    ├── text    → sheet: TextEntrySheet
    └── saved   → sheet: SavedMealsPickerSheet
```

Camera and photo paths converge on `MealImageDraft.state == .readyToAnalyze`,
which auto-fires `analyzePreparedMealImage()`. There is no confirm step between
picking an image and spending an AI scan.

Three separate paths can raise the paywall inside `MainTabView`: the
`canUseAIFeatures()` pre-check, `composerViewModel.shouldPresentSubscriptionPaywall`
(a `subscription/inactive` response mid-flight), and the same flag on
`logEntryDetailViewModel`.

```
LogEntryDetailSheet  (pushed)
└── ⋯ menu
    ├── Edit Manually  → sheet: ManualMacroEditSheet  (macros mode | calories-burned mode)
    ├── Edit Time      → sheet: inline wheel DatePicker (hour+minute only)
    ├── Edit with AI   → inline raw-input editor → re-interpret (Pro-gated)
    ├── Save Meal      → sheet: SaveLoggedMealSheet → savedMeals collection
    └── Delete Entry   → confirmationDialog
```

```
StatsView  (sheet)
└── StatsWeekPicker ‹ › — week paging, clamped at the current week
    StatsStreakCard · StatsActivitySummaryRow · CaloriesStatsCard · macro bars
    ✕ dismiss
```

```
ProfileView  (pushed; titled "Settings")
├── ProfileEditorView
│   ├── height  → sheet: EditHeightSheet   (cm | ft-in)
│   ├── weight  → sheet: EditWeightSheet   (kg | lb)
│   ├── gender  → sheet: inline picker
│   ├── goal    → sheet: inline picker
│   └── activity→ sheet: inline picker
├── ProfileAppearanceSection            (system | light | dark)
├── ProfileReminderSection  → sheet: reminder-mode picker (quiet | normal | aggressive)
├── ProfileSubscriptionSection
│   ├── no Pro  → sheet: SubscriptionPaywallSheet
│   └── has Pro → AppStore.showManageSubscriptions, falling back to the App Store URL
├── ProfileSavedMealsSection → sheet: SavedMealsSheet
│                               ├── + → sheet: AddSavedMealSheet
│                               └── row → sheet: EditSavedMealSheet → delete confirmation
├── ProfileLiftEatsSection
│   ├── "How score is calculated" → sheet: GoalFitScoreExplainerSheet
│   └── "Rate LiftEats"           → App Store review URL
├── ProfileLegalSection
│   ├── Privacy Policy / Terms / Support (mailto) → external
│   └── Nutrition sources → sheet: NutritionSourcesView
└── accountSection
    ├── Sign out → sheet: confirmation → sign out
    └── Delete Account → sheet: warning
                          ├── email/password → alert: email + password reauth
                          └── Apple          → sheet: appleReauthSheet
                          → callable `deleteAccount`
```

`SubscriptionPaywallSheet` is reachable from three places: `RootView`
(post-onboarding), `MainTabView` (any AI gate), and `ProfileView` (subscription
row). `GoalFitScoreExplainerSheet` is reachable from two: onboarding step 3 and
the profile. `NutritionSourcesView` is reachable from two: the profile and the
`NutritionSourcesLinkButton` inside `LogEntryAnalysisCards`.

---

## 2. Screen inventory — what each one does for the user

### Gate
| Screen | Job |
|---|---|
| `RootView` | Decides which of the four app states the user is in; nothing else. |
| `AppLoadingView` | Holds the screen while the profile loads or onboarding is being committed. |

### Auth
| Screen | Job |
|---|---|
| `WelcomeView` | Get the user into an account in one tap via Apple or Google, or route them to email. |
| `SignUpView` | Create an email/password account. |
| `SignInView` | Sign back in with email/password. |
| Reset-password sheet | Send a Firebase password-reset email. |

### Onboarding
| Screen | Job |
|---|---|
| `liftEatsIntro` | Sell the premise: the same meal fits different goals differently. |
| `OnboardingLiftEats` | Show what a finished analysis looks like before asking for anything. |
| `GoalFitScoreExplainerSheet` | Explain what the 0–100 goal-fit number means. |
| `OnboardingNameStepView` | Collect a display name when the auth provider supplied none. |
| `OnboardingGenderStepView` | Collect the sex constant the BMR formula needs. |
| `OnboardingAgeStepView` | Collect age for BMR. |
| `OnboardingHeightStepView` | Collect height for BMR, in cm or ft-in. |
| `OnboardingWeightStepView` | Collect weight for BMR and protein/fat-per-kg, in kg or lb. |
| `OnboardingActivityLevelStepView` | Collect *non-training* activity to pick the TDEE multiplier. |
| `OnboardingTrainingGoalStepView` | Collect cut / maintain / lean bulk — the single variable everything else keys off. |
| `OnboardingLoggingTipsStepView` | Teach the user to write logs the AI can estimate from. |
| `OnboardingSummaryStepView` | Show the computed targets and commit the profile. |

### Daily loop
| Screen | Job |
|---|---|
| `MainTabView` | The whole app: one day at a time, with its totals, its entries, and its log affordances. |
| `MainTabHeaderView` | Move between days and reach stats and settings. |
| `DailyMacroDetailSheet` | Answer "how many calories do I have left, and where are my macros?" at a glance. |
| `MainTabTimelineContentView` / `TimelineEntryRow` | List the day's entries with live analysis state, and offer retry/delete on failures. |
| `LogActionDock` | Offer the four ways to log: photo, camera roll, text, saved meal. |
| `TextEntrySheet` | Type what you ate or trained in plain language. |
| `MealCameraCaptureView` | Take a photo of a meal. |
| `SavedMealsPickerSheet` | Log a previously-saved meal without spending an AI scan. |
| `LogEntryDetailSheet` | Show the full analysis of one entry and offer every correction the user can make to it. |
| `ManualMacroEditSheet` | Override the AI's macros (food) or its calorie burn (exercise). |
| Edit Time sheet | Move an entry to a different time of the same day. |
| `SaveLoggedMealSheet` | Promote a good analysis into a reusable saved meal. |
| `StatsView` | Answer "how did the week go?" — streak, log counts, calories, macro consistency. |
| `NutritionSourcesView` | Show the citations behind the numbers and the not-medical-advice disclaimer. |

### Settings
| Screen | Job |
|---|---|
| `ProfileView` | The settings hub, and the only place targets can be changed after onboarding. |
| `ProfileEditorView` | Edit the body metrics and goal that feed the target calculation. |
| `EditHeightSheet` / `EditWeightSheet` | Change one measurement, with unit switching. |
| `ProfileAppearanceSection` | Pick light / dark / system. |
| `ProfileReminderSection` | Choose how aggressively to be nagged to log. |
| `ProfileSubscriptionSection` | Show subscription state and route to buy or to Apple's manage sheet. |
| `SubscriptionPaywallSheet` | Sell Pro, with the Apple-required disclosures. |
| `SavedMealsSheet` | Browse and manage the saved-meal library. |
| `AddSavedMealSheet` | Create a saved meal by hand. |
| `EditSavedMealSheet` | Edit or delete one saved meal. |
| `ProfileLiftEatsSection` | Reach the score explainer and the App Store review prompt. |
| `ProfileLegalSection` | Reach privacy, terms, support, and the nutrition sources. |
| Sign-out / delete-account / reauth sheets | Confirm and, for deletion, prove identity before an irreversible action. |

---

## 3. The data model

### Firestore

```
users/{uid}                                  ← UserProfile
  name, heightCm?, age?, weightKg?, goalType?, nonTrainingActivityLevel?,
  isOnboardingComplete, gender, createdAt, updatedAt

users/{uid}/logEntries/{entryId}             ← the one event table
  userId, source: text|image|savedMeal, status: analyzing|failed|succeeded,
  loggedAt, type: food|exercise, title, rawInput, detail?,
  image? { storagePath }, imageUploadStatus?: localOnly|uploading|uploaded|failed,
  feedback? {
    explanation, assumptions[], confidence?,
    estimatedCalories?,                      ← exercise only
    macros? { calories, protein, carbs, fat },← food only
    goalFitScore?,                           ← food only
    goalType?,                               ← stamped client-side at log time
    estimatedItems?[ { name, quantity, estimatedComponents[{name, estimatedAmount}] } ],
    exercise? { activityType, durationMinutes, intensity }
  }

users/{uid}/savedMeals/{mealId}
  userId, name, description?, macros, createdAt, lastUsedAt?, updatedAt

users/{uid}/private/subscription             ← written by the backend only
  plan, entitlementActive, entitlementId, productId, periodType, isTrial,
  revenueCatCustomerId, originalRevenueCatCustomerId,
  currentPeriodStartsAt, currentPeriodEndsAt, latestPurchasedAt,
  latestEventType, latestRevenueCatSyncSource, latestRevenueCatSyncAt, updatedAt

usageQuotas/{uid}/monthly/{period}
  totalAiScansUsed, quotaLimit, plan, cycleStartAt, cycleEndAt,
  lastAiScanSource, subscriptionProductId, entitlementPeriodType, updatedAt

revenueCatWebhookEvents/{eventId}            ← webhook dedupe
```

Cloud Storage: `users/{uid}/mealImages/{entryId}.jpg`
On-device: `Caches/MealImageCache/{entryId}.jpg`
`@AppStorage`: `appColorSchemePreference`, `lifteats.reminder.mode`

### What this schema says the product is

**It is a single-table journal of interpreted natural language, not a nutrition
database app.** There is no `foods` collection, no branded-item table, no
barcode, no serving-size registry, no USDA identifier anywhere in the model. The
only durable nutritional record is what one AI call returned for one sentence of
user text. `rawInput` is retained on every entry and "Edit with AI" re-runs the
whole interpretation from it — the raw sentence, not the macros, is the primary
key of truth. The product's asset is the interpretation loop, not a food
database.

**Food and exercise are the same object.** One `logEntries` collection, one
`feedback` envelope, discriminated by a single `type` field, with half the fields
null on each side: `macros` and `goalFitScore` for food, `estimatedCalories` and
`exercise` for exercise. This is a "log your day" model, not a nutrition tracker
that happens to also have workouts.

**The exercise half is a calorie-debit mechanism, not a training log.**
`ExerciseEstimate` is `{ activityType, durationMinutes, intensity }` — an enum of
eleven activities, a duration, and three intensity levels. There is no exercise
name, no sets, no reps, no load, no distance, no pace, no RPE, no volume, and no
per-workout structure of any kind. `strength_training` is one enum case that
covers every barbell movement in existence. Nothing in the schema can answer
"did my bench go up." Workouts exist to produce one number — calories burned —
that widens the day's calorie allowance.

**There is no body-progress dimension at all.** `weightKg` is a single scalar on
the profile document, overwritten in place by `EditWeightSheet`. There is no
weigh-in collection, no measurement history, no photos, no timestamped body
record. For an app whose entire premise is cut / maintain / lean bulk, the schema
cannot answer the one question those goals are about: is the weight moving. The
goal only ever influences the target macro numbers and the per-meal score.

**The score is per-meal and frozen at log time.** `goalFitScore` is computed by
`scoreFoodLog` from one meal's macros plus confidence, and `goalType` is stamped
onto the feedback client-side at the moment of logging. Nothing recomputes a
score when the user later changes their goal. There is no day-level score, no
week-level score, and no rollup — the schema stores five component weights'
worth of judgment about one burrito and never aggregates it.

**Monetization is metered AI, not features.** The entitlement is literally named
`ai_scans`. The quota document counts `totalAiScansUsed` against `quotaLimit`
per billing cycle and records `lastAiScanSource`. Every write path that costs an
OpenAI call is behind `requireActiveProSubscription`; `logSavedMeal` — the one
path that produces a log entry with no AI call — is the only unpaywalled way to
add data. The product being sold is inference, priced per scan.

**Correction is a first-class expectation.** `confidence` on every entry,
`assumptions[]` on every entry, `estimatedItems` with per-component amounts,
`ManualMacroEditSheet` on both entry types, "Edit with AI" re-running the whole
interpretation, plus a `failed` status with retry and a separate
`imageUploadStatus` state machine. The schema is built around the assumption that
the estimate is wrong often enough that the user needs to see the reasoning and
override it.

**Retention is the reminder system and the streak, not social or content.** There
is no sharing, no export, no coach, no friends, no feed, no plan, no recipe.
`ReminderMode` (up to six local notifications a day) and `currentStreakDays`
computed over a 90-day window are the entirety of the return mechanism.

Put plainly: **this is an AI-interpretation meter for a food journal, with an
exercise-shaped calorie rebate bolted onto the same table, sold by the scan.**

---

## 4. Flags

### Screens with no entry point

**`MainTabGradientBackground`** — `GymFuel/Extras/MainTabGradient.swift:3`. A
complete `View` with a `#Preview`, referenced by no file other than its own.
`MainTabView` renders on the default system background.

Every other declared `View` in the project has at least one live call site. Note
that several are reachable only by one path, which makes them fragile rather than
orphaned:

- `SavedMealsPickerSheet` is reachable only from the `LogActionDock` bookmark
  button, which is itself hidden whenever the selected day is outside the
  today−7d…today window. On an older day, saved meals are unreachable from the
  main screen.
- `StatsView` is reachable only from the flame glyph in `MainTabHeaderView`.
- `NutritionSourcesView` is reachable from the profile and from
  `LogEntryAnalysisCards`, but the latter only renders inside an entry that has
  analysis cards.

### Features nothing links to

**`POST /api/log-entry/analyze`** —
`gymfuel-ai-service/src/routes/logEntryRoute.js:263`. A fully implemented,
auth-guarded, quota-metered route. No Swift file contains the string
`api/log-entry/analyze`. The iOS client only ever calls `/interpretText` and
`/interpretMealImage`. The route is also the *only* one that returns
`analysisMeta` (the per-item breakdown, the `exercise` object, `model`, and
`promptVersion`), and it hard-rejects anything where `type !== "meal"` — so the
one endpoint that would surface model provenance is the one nothing calls.

**`analysisMeta`** — built by `normalizeLogEntryFeedback` for every analysis,
including `items` and `exercise`, and then discarded by both live routes before
the response is sent. `model` and `promptVersion` are logged to Cloud Run stdout
and never persisted against the entry that they produced. There is no way, given
a stored `logEntry`, to know which prompt version or model generated it.

**`SavedMeal.lastUsedAt`** — declared on the model, encoded and decoded by
`FirebaseSavedMealService`, preserved by `EditSavedMealSheet`. No code path ever
writes a non-nil value. `logSavedMeal` in `LogComposerViewModel` writes the log
entry and never touches the saved-meal document. `SavedMealsSheet` orders by
`createdAt`. The field is dead in every direction.

**`SavedMealsViewModel.isSavedMeal(name:description:macros:)` and
`fingerprint(for:)`** — public methods with no caller outside their own file. The
duplicate-detection they implement is not wired to any UI; `SaveLoggedMealSheet`
will happily create a second identical saved meal.

**`LogEntryDetailSheet.onSaveMeal`** — declared at
`LogEntryDetail/LogEntryDetailSheet.swift:16`, never passed by `MainTabView` and
never invoked inside the file. The Save Meal path bypasses it entirely and calls
`savedMealsViewModel` directly from the view.

**"and sets" in `OnboardingLoggingTipsStepView:133`** — the onboarding tip tells
the user to include *sets* so LiftEats can judge workouts more accurately. The AI
schema has no field for sets, the prompt has no instruction to extract them, and
`ExerciseEstimate` has nowhere to put them. The information is requested from the
user and then discarded.

**`MealImageInterpretationError.unsupported`** — the protocol default in
`LogInterpretationService` that throws "not available yet." The only conforming
type overrides it, so the message is unreachable.

### Places food data and workout data could be joined but aren't

**1. Exercise burn does not reach the target calculation.**
`MacroTargetCalculator.targetMacros(for:)` reads only the profile:
gender, age, height, weight, `goalType`, and `nonTrainingActivityLevel` — a field
explicitly documented as activity *outside* of training. It never reads a single
`logEntry`. A user who logs a two-hour ride and a user who logs nothing get
identical protein, carb, and fat targets for that day. The only place the two
sides meet is one line in the day view:

```swift
// DailyMacroDetailSheet.swift:12
Int((targetMacros.calories - consumedMacros.calories + burnedCalories).rounded())
```

Calories are rebated. Protein, carbs, and fat are not — the macro tiles below that
ring compare `consumedMacros` against a target that has never heard of the
workout.

**2. The weekly stats screen counts both and joins neither.**
`StatsSnapshot` carries `foodLogsThisWeek` and `workoutLogsThisWeek` side by
side, and `DailyStatsSnapshot` carries `caloriesEaten` and `caloriesBurned` for
the same date. `StatsActivitySummaryRow` renders the two counts as two separate
tiles. `CaloriesStatsCard` and the macro bars use only the eaten side;
`targetCalories` on each day is the flat profile target, copied identically into
all seven days. Net calories per day — the one number the two fields exist to
produce together — is computed nowhere in `StatsView`.

**3. Neither aggregation filters by `type`.**
`TimelineViewModel.consumedMacros` sums `feedback?.macros` across *every* entry
in the day, and `TimelineViewModel.burnedCalories` sums `feedback?.estimatedCalories`
across every entry. `StatsCalculator` does the same at `StatsCalculator.swift:38`
and `:45`. Neither filters on `type == .food` or `type == .exercise`; both rely
on the backend normalizer nulling the other side out. The rendering layer *does*
filter correctly (`TimelineEntryRowState`, `LogEntryDetailSheet:105`), so the
convention is enforced in the views and assumed in the maths. `ManualMacroEditSheet`
can write either field onto either entry type via
`LogEntryDetailViewModel.updateMacros` / `updateCaloriesBurned`, neither of which
checks `entry.type`.

**4. The user's body never reaches the burn estimate.**
`BackendLogInterpretationService` sends exactly two things to the AI service:
`text` and `goal`. The prompt then instructs, at rule 32: *"For exercise, if body
weight is not available, assume a typical adult body size."* The weight the user
was asked for during onboarding, which is sitting in `users/{uid}.weightKg` and is
already used locally for protein-per-kg and fat-per-kg, is never sent. Calorie
burn for a 55 kg and a 110 kg user logging the same run is estimated from the same
assumed body.

**5. The goal-fit score is blind to the rest of the day.**
`scoreFoodLog({ goal, macros, confidence })` sees one meal in isolation. It does
not receive the day's running totals, the day's remaining allowance, the user's
targets, or whether a workout was logged. A 900 kcal meal is capped at 42 on a cut
whether it is the user's only food of the day or their fourth, and whether or not
they logged a session that burned 800.

**6. Saved meals are severed from their origin.**
`SaveLoggedMealSheet` builds a fresh `SavedMeal` from a log entry's title and
macros and drops everything else — `estimatedItems`, `assumptions`, `confidence`,
`goalFitScore`, `rawInput`, and the image. When that saved meal is later logged,
`logSavedMeal` writes `estimatedCalories: nil, goalFitScore: nil,
estimatedItems: nil` and the explanation "Saved meal logged directly." A
re-logged meal therefore carries no score, so it silently drops out of every
score-based surface while still counting toward macros. There is no foreign key
back to the saved meal, and none forward to the entries that used it.

**7. Reminders know nothing about either.**
`ReminderService` schedules fixed wall-clock times from a three-mode enum. It does
not read the timeline, so the 8:30 PM "Log your latest meal or workout" fires
identically whether the user has logged nothing or logged six times.
