# Paywall Audit — Checklist A (Guideline 3.1.2)

Scope: `SubscriptionPaywallSheet.swift` only, per current audit instructions.

| ID | Status | Evidence | Fix |
|----|--------|----------|-----|
| A5 | FAIL | `SubscriptionPaywallSheet.swift:333,346,361` — trial length rendered as hardcoded literal `"3-day"` (`"Start 3-day free trial"`, `"3-day free trial available"`, `"3-day free trial, then …"`), never read from `package.storeProduct.introductoryDiscount`/`.subscriptionPeriod` | Read the trial period from the StoreKit intro offer on `package.storeProduct` instead of a hardcoded string. Severity: **high** — if the actual App Store Connect intro-offer length ever differs from "3 days", this is a metadata-mismatch rejection, and users see a wrong price/duration promise. |
| A1 | PASS | `SubscriptionPaywallSheet.swift:249` — `Text(isYearly ? "Pro Yearly" : "Pro Monthly")` shown on every package card | — |
| A2 | PASS | `SubscriptionPaywallSheet.swift:275,349,354` — `"/ year"`/`"/ month"` next to price, and `"per year"`/`"per month"` in subtitle/footer, shown for every package | Minor note: the yearly/monthly label comes from comparing `package.storeProduct.productIdentifier` to `RevenueCatConfig.proYearlyProductIdentifier` (lines 235, 353, 358), not from `storeProduct.subscriptionPeriod`. Works for the current 2-package offering but would silently mislabel a third package type. |
| A3 | PASS | `SubscriptionPaywallSheet.swift:271,354,361,364` — `package.localizedPriceString` rendered on every package row, subtitle, and footer | — |
| A4 | PASS | See itemized breakdown below — every price value renders via `package.localizedPriceString` (a StoreKit-backed property on `Package`/`StoreProduct`); no hardcoded price literal (e.g. `"$9.99"`) found anywhere in the file | — |
| A6 | PASS | `SubscriptionPaywallSheet.swift:9,177` — `termsURL` constant + `Link("Terms of Service", destination: termsURL)`, present on the paywall itself | — |
| A7 | PASS | `SubscriptionPaywallSheet.swift:8,174` — `privacyURL` constant + `Link("Privacy Policy", destination: privacyURL)`, present on the paywall itself | — |
| A8 | PASS | `SubscriptionPaywallSheet.swift:148-171` — "Restore Subscription" button present directly on the paywall, unconditionally rendered (not behind any auth/account check in this file) | — |

## A4 detail — every price/duration/trial-length render site

| Line | Rendered text | Source |
|------|---------------|--------|
| 271 | `package.localizedPriceString` (main price on package card) | **StoreKit** — `Package.localizedPriceString` |
| 275 | `"/ year"` / `"/ month"` | **Hardcoded** literal, selected via `isYearly` product-ID comparison (not `storeProduct.subscriptionPeriod`) |
| 310/333 | `"Start 3-day free trial"` / `"Continue"` (button title) | **Hardcoded** — `"3-day"` literal; not read from `storeProduct.introductoryDiscount` |
| 346 | `"3-day free trial available"` (package subtitle) | **Hardcoded** — same `"3-day"` literal |
| 354 | `"\(package.localizedPriceString) per year/month"` (non-trial subtitle) | Price: **StoreKit**. Duration word: **Hardcoded** (via `isYearly` comparison) |
| 361 | `"3-day free trial, then \(package.localizedPriceString) per year/month. Renews automatically…"` (footer, trial case) | Price: **StoreKit**. `"3-day"` and `"per year/month"`: **Hardcoded** |
| 364 | `"\(package.localizedPriceString) per year/month. Renews automatically…"` (footer, non-trial case) | Price: **StoreKit**. Duration word: **Hardcoded** |
| 337 (fallback) | `"Subscription renews automatically unless cancelled at least 24 hours before renewal."` | No price/duration/trial value — static fallback shown only when `selectedPackage` is nil |

No dollar-amount or numeric price literal is hardcoded anywhere in this file — every price figure traces to `package.localizedPriceString`. The only hardcoded values are the trial-length string (`"3-day"`, flagged A5/FAIL) and the duration-unit words (`"year"`/`"month"`, flagged as a minor note under A2), neither of which is a StoreKit-sourced value.

# Paywall Audit — Checklist C (RevenueCat production readiness)

Scope: `RevenueCatConfig.swift`, `SubscriptionService.swift`, `BackendSubscriptionService.swift`, `SubscriptionViewModel.swift`, `GymFuelApp.swift`, `RootView.swift`, `SubscriptionPaywallSheet.swift`.

| ID | Status | Evidence | Fix |
|----|--------|----------|-----|
| C7 | FAIL | `SubscriptionService.swift:49-65` — `SubscriptionService` is an `NSObject` subclass but never sets `Purchases.shared.delegate` and implements no `PurchasesDelegate` method (e.g. `purchases(_:receivedUpdated:)`). `SubscriptionViewModel.swift:82-102` defines `refreshCustomerInfo()`, but across all seven scoped files it is only ever invoked from within `syncUser` at `SubscriptionViewModel.swift:51` — i.e. only when the *same* already-synced user re-triggers `.task(id:)` in `RootView.swift:41-50`. There is no call to it at unconditional app launch and no customer-info listener, so an entitlement change while the app is backgrounded/killed (renewal, billing retry expiry, refund) is not reflected until the user ID happens to resync. | Register a `PurchasesDelegate` (`Purchases.shared.delegate = SubscriptionService.shared`) and implement `purchases(_:receivedUpdated:)` to push fresh `CustomerInfo` into the view model; also call `refreshCustomerInfo()` unconditionally on launch, not only inside the same-user branch of `syncUser`. Severity: **high** — stale entitlement state after a lapsed/refunded subscription is a real-money correctness bug, not just a review risk. |
| C8 | UNKNOWN | No Xcode project/scheme file is in the audit scope (only `.swift` sources were read) | Would need `GymFuel.xcodeproj/xcshareddata/xcschemes/*.xcscheme` (Release scheme's "Options" tab, StoreKit Configuration field) to verify. Cannot infer from source. |
| C1 | PASS | `GymFuelApp.swift:24-28` — `SubscriptionService.shared.configureIfNeeded()` called once in `init()`, before `RootView()` (and therefore any paywall) is ever built. `SubscriptionService.swift:58-65` — `configureIfNeeded()` guards `Purchases.configure` behind `isConfigured`, so repeated internal calls (lines 68, 74, 79, 84, 109, 119, 129) never re-invoke `configure` | — |
| C2 | PASS | `RevenueCatConfig.swift:4` — `publicSDKKey = "appl_eVCJtAkJfJAskxlNlYrFqFeULej"`, an `appl_`-prefixed public SDK key. No secret key present in any scoped file | — |
| C3 | PASS | `RootView.swift:41-49` — `.task(id: authManager.user?.uid)` calls `subscriptionViewModel.syncUser(userId: user.uid)` on sign-in and `syncUser(userId: nil)` on sign-out. `SubscriptionViewModel.swift:48-80` routes those to `service.logIn(userId:)` (`SubscriptionService.swift:67-71`, `Purchases.shared.logIn`) and `service.logOut()` (`SubscriptionService.swift:73-76`, `Purchases.shared.logOut`) respectively | — |
| C4 | PASS | `SubscriptionService.swift:133-145` — `status(from:)` checks `customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier]` (`"ai_scans"`) and `entitlement.isActive`, functionally equivalent to `entitlements.active[...]`. No product-ID string matching or manual receipt parsing is used for gating (`productKind(for:)` at line 160 uses product ID only for display labeling, not access control) | — |
| C5 | PASS | `SubscriptionViewModel.swift:152-155` — `if result.userCancelled { isPurchasing = false; return false }` sets no `errorMessage`, so cancellation is silent | — |
| C6 | PASS | `SubscriptionViewModel.swift:170-177` (purchase) and `:200-207` (restore) — catch blocks assign `errorMessage = AppErrorMessage.message(for:fallback:)`, a non-nil, user-facing string; not a silent no-op. (`AppErrorMessage` itself is out of audit scope — content/quality of its mapped messages is `UNKNOWN`.) | — |

## Trace: three runtime scenarios

**1. Restore Purchases, no prior purchase** — `SubscriptionPaywallSheet.swift:148-154` calls `subscriptionViewModel.restorePurchases()` → `SubscriptionViewModel.swift:180-207` → `service.restorePurchases()` → `SubscriptionService.swift:128-131` (`Purchases.shared.restorePurchases()`) returns a `CustomerInfo` with no active `"ai_scans"` entitlement → `status(from:)` yields `.free` → `restoredStatus.hasProAccess` is `false` (line 188) → `applyFreeStatus()` runs, `errorMessage = "No active LiftEats Pro subscription was found for this Apple ID."` (line 190), `isRestoring = false`, returns `false` → sheet does not dismiss (line 150-153), user sees the message rendered at `SubscriptionPaywallSheet.swift:187-193`.

**2. User cancels the Apple payment sheet mid-purchase** — `SubscriptionViewModel.swift:145-177` → `service.purchase(package:)` → `SubscriptionService.swift:118-126` returns `SubscriptionPurchaseResult(userCancelled: true)` → line 152-155 short-circuits: `isPurchasing = false`, function returns `false`, **`errorMessage` is left untouched (`nil`, cleared at line 147)** → no alert/message shown → paywall sheet stays open (`continueButton` at `SubscriptionPaywallSheet.swift:296-301` only dismisses on `didPurchase == true`).

**3. Offerings fail to load while offline** — `SubscriptionPaywallSheet.swift:47-49` `.task` calls `subscriptionViewModel.loadPaywallPackages()` → `SubscriptionViewModel.swift:104-123` → `service.paywallPackages()` → `SubscriptionService.swift:83-106` → `Purchases.shared.offerings()` throws a network error → caught at `SubscriptionViewModel.swift:115-120`, `errorMessage = AppErrorMessage.message(for: error, fallback: "We couldn't load subscription options. Please try again.")`, `paywallPackages` stays `[]`, `isLoading = false` → `packageOptions` (`SubscriptionPaywallSheet.swift:213-231`) renders the empty-state text "Subscription options are unavailable. Please try again." instead of a spinner or blank view, and `errorMessage` is also shown at lines 187-193 — paywall degrades to a message state, not a stuck spinner or crash.

# Paywall Audit — Premium Feature Gating (C4, C7, C9)

Scope: `MainTabView.swift`, `LogComposerViewModel.swift`, `LogEntryDetailViewModel.swift`, `BackendLogInterpretationService.swift` only.

## Every premium (AI-interpretation) entry point in scope

| Entry point | File:Line | Client-side gate | Server-side backstop |
|---|---|---|---|
| Camera capture tap | `MainTabView.swift:413-414` (`handleCameraTap`) | `guard canUseAIFeatures() else return` | — |
| Photo library tap | `MainTabView.swift:484-485` (`bottomDock.onPhotoTap`) | `guard canUseAIFeatures() else return` | — |
| Text log button tap | `MainTabView.swift:488-489` (`bottomDock.onTextTap`) | `guard canUseAIFeatures() else return` | — |
| "Use AI again" on entry detail | `MainTabView.swift:196-197` (`onUseAIAgain` closure → `logEntryDetailViewModel.reinterpretEntry`) | `guard canUseAIFeatures() else return` | — |
| Retry a failed entry | `MainTabView.swift:524-525` (`retryFailedEntry` → `retryTextEntry`/`retryMealImageEntry`) | `guard canUseAIFeatures() else return` | — |
| Submit current draft | `MainTabView.swift:554,556` (`submitCurrentDraft`) | `guard canUseAIFeatures() else return` | — |
| `LogComposerViewModel.submitText` | `LogComposerViewModel.swift:97` | **None** — no reference to `subscriptionViewModel`/entitlement anywhere in this file | `isSubscriptionInactive(error)` at line 174 → backend `subscription/inactive` code (`BackendLogInterpretationService.swift:175-176`) sets `shouldPresentSubscriptionPaywall` |
| `LogComposerViewModel.retryTextEntry` | `LogComposerViewModel.swift:191` | **None** | Same as above, line 235 |
| `LogComposerViewModel.retryMealImageEntry` | `LogComposerViewModel.swift:244` | **None** | Same as above, line 290 |
| `LogComposerViewModel.submitMealImage` | `LogComposerViewModel.swift:299` | **None** | Same as above, line 388 |
| `LogEntryDetailViewModel.reinterpretEntry` | `LogEntryDetailViewModel.swift:55` | **None** | `isSubscriptionInactive(error)` at line 93 → same backend code |

Not gated, and correctly so — no AI/backend call involved: saved-meal logging (`MainTabView.swift:493-496` → `LogComposerViewModel.logSavedMeal`, direct Firestore write, no `interpretationService` call), delete-entry (`MainTabView.swift:544-552`), and background/retry image *upload* (`MainTabView.swift:518-522`, `LogComposerViewModel.swift:448-498` — re-uploads bytes to storage, never calls `interpretationService`).

## Checklist rows

| ID | Status | Evidence | Fix |
|----|--------|----------|-----|
| C9 | PASS (conditional) | Every AI-triggering user action currently reachable from `MainTabView.swift` is gated by `canUseAIFeatures()` (`MainTabView.swift:458-465`) before the corresponding `LogComposerViewModel`/`LogEntryDetailViewModel` method is ever invoked (see table above). **However**, none of the four AI-calling methods in `LogComposerViewModel.swift` (lines 97, 191, 244, 299) or `LogEntryDetailViewModel.reinterpretEntry` (line 55) perform any entitlement check themselves — each is a public method reachable by any future call site with zero client-side gating of its own. The only thing preventing a bypass today is that `MainTabView.swift` happens to be the sole caller of each, and every one of those call sites currently includes the guard. | Move (or duplicate) the entitlement check into the `LogComposerViewModel`/`LogEntryDetailViewModel` methods themselves — e.g. accept a `hasProAccess: Bool` and short-circuit before calling `interpretationService` — so gating doesn't depend on every present and future UI call site remembering to check first. Severity: **nice-to-have, not a rejection trigger** — the backend independently rejects with `subscription/inactive` (`BackendLogInterpretationService.swift:175-176`) and `monthlyQuotaExceeded` (lines 171-174) regardless of client state, so a missed client-side guard would surface as a paywall bounce after a wasted round-trip, not a free premium feature. |
| C4 | UNKNOWN (out of scope here) | These four files never touch `customerInfo.entitlements` directly — `MainTabView.swift:459` only consumes the black-box `subscriptionViewModel.hasProAccess` Bool. The actual entitlement check lives in `SubscriptionService.swift` (not in this task's scope), already rated PASS in the Checklist C section above (`SubscriptionService.swift:133-145`, entitlement id `"ai_scans"`) | No action from these files. If `hasProAccess` itself changes, re-verify against `SubscriptionService.swift`. |
| C7 | UNKNOWN (out of scope here) | No RevenueCat SDK calls, listener registration, or refresh-on-launch logic exist in these four files — they only read `hasProAccess` as already computed. Already rated FAIL in the Checklist C section above (`SubscriptionService.swift:49-65`, no `PurchasesDelegate` registered) | No action from these files; the FAIL already logged against `SubscriptionService.swift`/`SubscriptionViewModel.swift` stands. |
