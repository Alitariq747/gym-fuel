# LiftEats

An iOS calorie tracker, mid-repositioning. Two things a fresh session gets wrong:

- The repo is `GymFuel`, the app ships as `LiftEats`, and it is being renamed again.
- It looks like a lifting app. It is being repositioned **away** from lifting —
  toward home-cooked food that packaged-food databases don't cover. Gym vocabulary
  is being removed on purpose. Do not "restore" it.

## Where things live

| File | Answers |
|---|---|
| `build-order.md` | What we're building now, in order, with progress checkboxes. **Start here.** |
| `project-brief.md` | Scope — especially what is explicitly *out* |
| `store-copy.md` | Exact App Store strings, with character counts |
| `repositioning-strategy.md` | Why we're doing this. Rarely needed mid-build |
| `product-as-built.md` | What the code does today |

The backend (`gymfuel-ai-service/`) is attached as an additional working directory.
Read it directly — it is not missing, and it is not in this repo.

## How we work

- I name one step from `build-order.md`. Do that step and nothing else.
- Plan first. Show me the plan before writing code.
- If something outside the step looks necessary, **stop and ask**. Don't widen scope.
- No opportunistic refactors, renames, or reformatting.
- No new dependencies.

## Finishing a step

Report in this order:

1. Files touched — so I can check `git diff --stat` matches
2. What behaviour changed, one line each
3. Exactly what I should tap in the app to confirm it
4. Anything you noticed but did **not** change
5. Tick the step's checkbox in `build-order.md`

## Stack

SwiftUI, iOS 17.6+. Firebase Auth, Firestore, Storage. RevenueCat with a **custom
paywall** — every Apple-required disclosure is ours to get right, not the SDK's.
Node service on Cloud Run for OpenAI calls.

Entitlement `ai_scans` · offering `default` · packages `pro_yearly`,
`pro_monthly` · products `lifteats_pro_yearly`, `lifteats_pro_monthly`.

## Never do these

Each one is a real failure mode, not a style preference.

- **Don't rename the `ai_scans` entitlement** — it is what
  `customerInfo.entitlements[...]` looks up, and renaming it breaks entitlement
  checks for every user still on an older build.
- **Don't build a `foods` collection, barcode scanner, or nutrition database** —
  its absence is the product.
- **Don't re-add exercise or workout logging** — removed deliberately in Step 3.
  If a burn figure reappears anywhere, it corrupts the adaptive engine. **This
  includes importing one.** HealthKit active energy, workouts and steps are out —
  as an input *and* as displayed context. HealthKit is `bodyMass`, read-only.
- **Don't hardcode a trial length or a price** — read both from StoreKit.

## Relaxed — but only until the first user

**Firestore held no user documents on 7 September 2026.** Two former rules were
protecting data that doesn't exist. They come back the moment someone signs up, so
treat both as *before launch or not at all*.

- **`GoalType` raw values** (`lean_bulk`, `maintain`, `cut`) are safe to change.
  Don't do it opportunistically anyway: `goal.rawValue` reaches the AI prompt,
  which hard-codes the tokens, so it is a two-repo edit that only pays as part of
  the Step 6 prompt work.
- **`logEntries` has no history to protect.** Delete `LogEntryType` and its read
  path in Step 3 rather than keeping them alive for entries that don't exist.

**Neither relaxation reaches `ai_scans`** — that rule is about builds in the wild,
not stored rows, and an empty `users` collection doesn't prove no old install
exists. It stays in the list above.

## The paywall must always hold

After any change touching subscriptions, all six still true:

1. Every price renders from `package.localizedPriceString` — never a literal
2. Terms of Service and Privacy Policy links present
3. Restore Subscription present and reachable
4. Renewal footer discloses auto-renewal and the 24-hour cancellation rule
5. No copy, link, or button points to a purchase method outside Apple IAP
6. A visible dismiss control remains
