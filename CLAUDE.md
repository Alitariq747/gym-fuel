# LiftEats — Paywall & Subscription Fix Pass

## Current task

Applying approved fixes to the RevenueCat paywall and subscription logic, one task at
a time. Each task names its own files. The audit is finished — do not re-audit.

## Rules of engagement

- Edit only the file(s) named in the current task. Do not glob, grep, or explore the
  tree. If a file outside the task scope seems necessary, stop and ask.
- Show the proposed diff and wait for my approval before editing.
- Change only what the task names. No refactors, no renames, no reformatting, no
  "while I was in here" improvements.
- Do not add dependencies. Do not change public signatures unless the task says so.
- Do not touch the backend (`/server`, Cloud Run, Firebase Functions). Separate pass.
- Verify RevenueCat API names against `Package.resolved` before proposing code that
  calls the SDK. Do not rely on remembered signatures.
- If something can't be determined from the files in scope, say so and name what you'd
  need. Do not infer.

## File map

Paths relative to repo root.

**Subscription core**
- `GymFuel/Extras/RevenueCatConfig.swift` — SDK key, entitlement, offering, package
  and product identifiers
- `GymFuel/Services/SubscriptionService.swift` — RevenueCat layer: configure,
  offerings, purchase, restore, entitlement parsing, trial eligibility
- `GymFuel/Services/BackendSubscriptionService.swift` — POST `/api/subscription/sync`
- `GymFuel/ViewModels/SubscriptionViewModel.swift` — state coordinator: packages,
  selection, purchase, restore, refresh, status, loading/error
- `GymFuel/GymFuelApp.swift` — configures RevenueCat at launch, injects the view model
- `GymFuel/Views/RootView.swift` — bridges Firebase auth to `syncUser(userId:)`

**Paywall & profile UI**
- `GymFuel/Views/Components/ProfileComponents/SubscriptionPaywallSheet.swift` — the
  custom paywall
- `GymFuel/Views/Components/ProfileComponents/ProfileSubscriptionSection.swift`
- `GymFuel/Views/Profile/ProfileView.swift` — opens paywall / native manage sheet
- `GymFuel/Views/Onboarding/OnboardingFlowView.swift` — post-onboarding paywall

## Stack facts

- SwiftUI, iOS. RevenueCat SDK. **Custom paywall**, not RevenueCat's template — every
  Apple-required disclosure is our responsibility.
- Firebase Auth + Firestore. Node service on Cloud Run for OpenAI calls.
- Entitlement identifier: `ai_scans`. Offering identifier: `default`.
- Package identifiers: `pro_yearly`, `pro_monthly`. Products:
  `lifteats_pro_yearly`, `lifteats_pro_monthly`.

## Already correct — do not "improve"

These were verified during the audit. Leave them alone unless a task names them.

- Trial eligibility: `checkTrialOrIntroDiscountEligibility` plus a non-nil
  `introductoryDiscount` check in `isEligibleForTrial`. Correct as written.
- Entitlement check via `entitlements[id].isActive` — not product-ID matching.
- Cancelled purchases are handled silently via `result.userCancelled`.
- `Purchases.configure` is guarded behind `isConfigured` and called once at launch.
- Sign in with Apple and in-app account deletion both exist and are tested.

## Regression guards

After any edit, these must still hold:

1. Every price on the paywall renders from `package.localizedPriceString`, never a
   hardcoded literal.
2. Terms of Service and Privacy Policy links remain present and functional on the
   paywall.
3. Restore Subscription remains present and reachable.
4. The renewal footer still discloses auto-renewal and the 24-hour cancellation rule.
5. No copy, link, or button points to any purchase method outside Apple IAP.
6. A visible dismiss control remains on the paywall.

## Output format

After each approved edit:

- List every file touched.
- List every behaviour that changed, one line each.
- Flag anything you noticed but did NOT change, so I can decide separately.
- No summary prose beyond three sentences.
