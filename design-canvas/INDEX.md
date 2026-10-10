# Circa canvas — offline mirror

Exported from the design canvas artifact so an agent without artifact access
(Codex) can read it. Source of truth stays the canvas:
https://claude.ai/code/artifact/5039f517-40d9-4e28-860f-336719ab0cef

Each `.dc.html` is one artboard: a self-contained HTML mock of one screen,
readable as plain text. `design.md` owns the rules; these show the pixels.
Where an artboard's copy disagrees with the *Canvas drift* table in `design.md`,
**the table wins** — several artboards still carry pre-17-September copy.

Re-export after any canvas edit; nothing syncs automatically.

## Page 1 — Circa (the live design)

| File | Artboard |
|---|---|
| `Composer.dc.html` | Composer |
| `DayPicker.dc.html` | Day picker |
| `DetailB.dc.html` | Entry |
| `DetailMenu.dc.html` | Entry · menu |
| `DetailReword.dc.html` | Entry · re-estimate warning |
| `Foundations.dc.html` | Foundations |
| `Main.dc.html` | Day |
| `Menu.dc.html` | Menu |
| `OnbActivity.dc.html` | Onboarding · daily movement |
| `OnbGender.dc.html` | Onboarding · formula |
| `OnbGoal.dc.html` | Onboarding · goal |
| `OnbIntro.dc.html` | Onboarding · the problem |
| `OnbName.dc.html` | Onboarding · name |
| `OnbNotifications.dc.html` | Onboarding · reminders (3a) |
| `OnbSummary.dc.html` | Onboarding · your numbers |
| `OnbTips.dc.html` | Onboarding · how to write |
| `OnbWeight.dc.html` | Onboarding · weight |
| `Paywall.dc.html` | Paywall |
| `Paywall3InApp.dc.html` | Paywall · 1 · in-app |
| `Paywall3Plan.dc.html` | Paywall · 1 · your plan |
| `Paywall3PlanDark.dc.html` | Paywall · 1 · your plan · dark |
| `Paywall3PlansNoTrial.dc.html` | Paywall · 3 · plans, no trial |
| `Paywall3PlansTrial.dc.html` | Paywall · 3 · plans, with trial |
| `Paywall3PlansTrialDark.dc.html` | Paywall · 3 · plans, with trial · dark |
| `Paywall3Trial.dc.html` | Paywall · 2 · the trial |
| `Paywall3TrialDark.dc.html` | Paywall · 2 · the trial · dark |
| `PaywallDark.dc.html` | Paywall · dark |
| `ProofArabic.dc.html` | Arabic RTL |
| `ProofDark.dc.html` | Dark |
| `ProofDynamicType.dc.html` | Dynamic Type AX3 |
| `SavedMeals.dc.html` | Saved meals |
| `Settings.dc.html` | Settings |
| `SettingsDelete.dc.html` | Settings · delete account |
| `SettingsTargets.dc.html` | Settings · your targets |
| `SharePhoto.dc.html` | Share card · photo meal |
| `SharePreview.dc.html` | Share · preview |
| `ShareText.dc.html` | Share card · text meal |
| `StateAnalysing.dc.html` | Analysing · text + photo |
| `StateEmpty.dc.html` | Empty day |
| `StateFailed.dc.html` | Failed · retry |
| `Week.dc.html` | Week · after a check-in |
| `WeekEarly.dc.html` | Week · day 2 |
| `WidgetLock.dc.html` | Widget · lock screen |
| `WidgetLockStates.dc.html` | Widget · lock screen states |
| `WidgetMedium.dc.html` | Widget · medium |
| `WidgetSmall.dc.html` | Widget · small |

## Page 2 — Round 1 · not chosen

**Frozen losing directions. Do not build from these.**

| File | Artboard |
|---|---|
| `DetailA.dc.html` | A · Entry |
| `DetailC.dc.html` | C · Entry |
| `DirectionA.dc.html` | A · Ledger |
| `DirectionC.dc.html` | C · Grouped |

## Canvas notes

The sticky notes that sat beside the artboards, in canvas order.

### circa-brief (page-1)

Circa — the design, growing one batch at a time.

Row 1: the two screens the whole app hangs off.
Row 2: the logging loop — everything the dock leads to, plus the states the day view spends its time in.
Row 3: moving around, and looking back.
Row 4: onboarding.
Row 5: the summary-to-paywall seam.
Row 6: the rest of onboarding, and settings.
Row 7: the constraints, proven.
Row 8: widgets (Step 14).
Row 9: the paywall, three pages (15e) — 8 October.

All data is placeholder. Photos are drawn placeholders, not food.

### note-entry (page-1)

THE ENTRY SCREEN · redrawn 28 September

One card holds the meal's nutrition. Calories stay the loudest number. Protein, carbs and fat sit under it in three equal columns, each with its drawn glyph in a well. All four keep the dotted rule. One ink throughout: no colour per macro (rule 5) and no rings.

Each breakdown row carries its macros on the mono meta line, after the amount, the way the Day row carries its own.

Each action sits beside what it changes. The pencil on the Breakdown card opens the amounts editor. The sparkle beside the title turns the title into a field, to reword the meal and re-estimate it. Neither is in the ⋯ menu any more, and the "Edit amounts" link under the title is gone.

The ⋯ menu keeps what has no place on the page: Save meal, Edit time, Edit totals, Delete entry. Share sits beside it and arrives with 7k.

Rewording replaces every amount the person set (meal-contract §9). So when any amount was changed, Circa asks at the tick, before the scan. With no changed amounts, nothing asks.

Saved-meal entries show no sparkle and no Save meal. A meal whose totals were typed has no breakdown, so no pencil.

The top half of this screen is what the 7k share card crops.

### note-logging (page-1)

BATCH 1 — THE LOGGING LOOP

Composer. Gym vocabulary is gone: the heading and the worked example were both about workouts. Left-aligned rather than centred, because Circa is a journal. No fake keyboard is drawn — the real one renders in that space.

Analysing. The certainty texture does the work: while a number is unknown the row shows the dotted rule with NOTHING above it. The image sweep is the existing ImageAnalysisScannerOverlay, and the status line is the existing three-stage rotation (reading your meal → estimating calories and macros → preparing your summary). The day total counts only what has settled and names how many are still out.

Failed. Both failure shapes, and the point of both is that nothing is lost — the sentence and the photo are kept, so Try again costs the user nothing. Warm brick #A03A28, 6.4:1 on paper, not a system red.

Empty day. The full target is still the headline; an empty log is not an error. The copy teaches the format in one line.

Saved meals. The one path that spends no AI call, and the subtitle says so.

### note-week (page-1)

BATCH 2 — MOVING AROUND, AND LOOKING BACK

The nav model is TWO scales, Day and Week. No Month: the product's cadence is the weekly check-in and the weigh-in, and a month view would be a dashboard idea with nothing to put in it. The calendar is for jumping to a date, not a third scale.

The picker also states the rule the current build only enforces silently — the dock hides outside today−7d, so older days can be read but not written to.

Menu. The hamburger absorbed both header controls (the flame and the gear). Weigh in gets a card rather than a list row because it is the input the whole engine depends on, and Step 4's success criterion is a SECOND weigh-in. The scan quota sits with the subscription, where it belongs, rather than being a headline feature.

Week. The check-in result is the reason this screen exists, so it leads — same inverted block as the goal-fit score. Everything else is habit, not performance. Step 3's deletions are already applied: no workout count, no burn, no net-calorie row.

Week · day 2 is the state most trialists will actually see. It says plainly what Circa still needs before it can say anything true.

### note-onboarding (page-1)

BATCH 3 — ONBOARDING

The intro is the store copy's opening line built as a screen: five results for one dish, 80 to 400 calories, none of them yours. It shows the problem instead of describing it, and it is the only onboarding screen whose job is persuasion.

Weight is the TEMPLATE for the four metric steps — gender, age, height, weight all share this chrome, this wheel and this button. Design one, get four.

Goal carries Step 2's rewrite: Gain / Lose fat / Maintain, and the barbell glyph at GoalType.symbolName is gone — three trend lines instead, which say the same thing without the gym.

How to write keeps the existing vague-vs-helpful pattern, which was already the right idea, and swaps its content. Both workout examples and the "22 total sets" line are deleted, per Step 3. The confidence rings reuse the dotted arc from the entry screen, so the number the user is taught to raise is visibly the same one Circa shows them later.

Reminders is Step 3a, and it is deliberately NOT the system prompt. iOS grants one requestAuthorization per install and a denial is permanent, so this screen has to earn the tap before it spends it. "Turning this on asks iOS for permission" is on the screen for that reason. Not now leaves the mode at .quiet.

Still to do in onboarding: name, gender, age, height, activity level, and the summary. Summary belongs with the paywall batch — it commits the profile and fires the paywall in one move.

### note-paywall (page-1)

BATCH 4 — THE SEAM

Summary and paywall are one moment: RootView.saveOnboarding commits the profile, then fires the paywall on success. So the summary must feel like an ending, not a sales run-up. Its last line is the promise the adaptive engine has to keep.

THE SIX INVARIANTS, all held and marked in the source:
1 · every price renders from package.localizedPriceString — the $4.58 a month is DERIVED from the yearly package price, never typed
2 · Privacy Policy and Terms of Service present
3 · Restore Subscription present and reachable
4 · the footer states auto-renewal and the 24-hour rule verbatim from footerText(for:)
5 · nothing points at a purchase method outside Apple IAP
6 · a visible dismiss remains

Step 1 is visible here: 14-day is shown in three places (card subtitle, button, footer) and all three must come from package.storeProduct.introductoryDiscount. Those are the exact sites that hardcode "3-day" today.

What changed in the pitch. "500 AI scans a month" was feature #1; it is now a fair-use line at the bottom, because the strategy is to stop selling inference. "Exercise logging" is deleted per Step 3. All eight emoji are gone.

Dark is here rather than in the proofs row because this is the one screen where a theme bug costs money. Note the primary button INVERTS — a dark button on a dark ground would vanish.

### note-proofs (page-1)

CONSTRAINTS, PROVEN

Dark is a designed twin, not an inversion — warm near-black, never pure black.

Arabic is the same markup with one attribute flipped: the number moves left, the chevron reverses, the bars fill from the right. Copy is placeholder and needs a native speaker.

At AX3 the entry rows go vertical, the macro bars stack, and the dock drops its labels rather than truncating them — keeping four 56pt targets.

These three proofs cover the Day view only. Batch 1's five screens have not been through them yet.

### note-archive (page-2)

Kept for the record: the two directions not chosen, frozen exactly as they were when B was picked.

They do NOT carry the later refinements — these still show the old bottom summary pill and the inline composer that B has since replaced with the dock.

### note-settings (page-1)

BATCH 5 — WHAT WAS LEFT

Age and height are deliberately NOT drawn. They are the weight artboard with a different label and range, and five near-identical frames would be padding rather than design. Name, formula and daily movement are here because each is a pattern the canvas did not yet have: a text field, a compact choice, and a choice with consequences.

Formula asks the question the BMR equation actually asks, and says so. That is the only reason the app needs the field, and the screen states it rather than implying something broader.

Daily movement carries Step 2 renaming. The enum is called NonTrainingActivityLevel only because training was counted separately, which stops being true after Step 3. The screen also tells the truth about its own value: it is a seed the engine discards within two or three weeks.

Settings absorbed the flame and the gear. Weight is NOT editable here, because it comes from weigh-ins; letting it be typed would let the trend the whole engine rests on be overwritten by hand.

Your targets shows the number the check-in set and when it was set. Changing the goal starts a new phase, and the screen says so before the tap rather than after.

Delete account counts what will actually go, names the re-authentication Apple requires, and states plainly that deleting does not cancel the subscription.

Still undrawn, all variants of patterns already on the canvas: reminders, appearance, the saved-meal editor, nutrition sources, the score explainer, and the four auth screens.

SF SYMBOLS — added 10 September. The mockups draw them as SVG; these are the real names to use in the build.

Formula: figure.stand.dress / figure.stand / person.fill.questionmark
Daily movement: figure.seated.side / figure.walk / shippingbox

NOTE the third movement glyph. The obvious pick is figure.strengthtraining.traditional, and it is exactly the barbell Step 2 removes from GoalType.symbolName. A shipping box says physical work without saying gym.

Settings: target, scalemass, bookmark, bell, circle.lefthalf.filled, sparkles, chart.bar.xaxis, books.vertical, hand.raised, doc.text, envelope, rectangle.portrait.and.arrow.right, trash

Glyphs sit in 30pt wells, monochrome on paper, NOT iOS Settings' coloured squares — a row of tinted icons would break rule 5 and the palette in one go. Delete account is the single exception: its well and glyph carry danger.

### note-share (page-1)

THE SHARE CARD (7k) · drawn 28 September

One meal, rendered as an image 360 pt wide at 3× (1080 px). Always light and at a fixed text size, so every card looks the same whoever sends it. Its height follows the content.

The top half is the Entry screen's: the label, the raw sentence, the nutrition card. Then the one assumption that moves the calories most (the timeline's rule), the explanation cut at five lines, and the footer.

Nothing else leaves the phone: no date or time, no targets, no weight, no other meals.

Photo meals lead with the photo, cropped 4:3. If the photo cannot load, the card leaves it out and the preview says so.

A meal whose totals were typed has no breakdown and no explanation. Its card is the title, the numbers and "You set this total".

The footer is the plate without its face (the app icon's mark, not the mascot) beside the name, with "AI estimate" opposite. The name lives in one place in the code, for Step 8.

The share icon beside ⋯ opens this preview first, so people see exactly what they send. Its Share button opens the system share sheet. It shows on any meal that finished estimating, older days included.

### note-widgets (page-1)

WIDGETS (Step 14) · redrawn 2 October, round 2

The plate mascot sits in the corner; the number still leads. Round 1 copied the Day card onto the home screen and read as flat. This round takes what works in the category's widgets — a character, a big warm number, a compact macro panel, a gauge on the lock screen — and leaves out the flame (rule 10: a flame says burn) and a colour per macro (rule 5).

THE MASCOT NEVER REACTS TO THE NUMBERS. Its pose follows whether the day has anything in it, never how the day is going: writing in its notepad once anything is logged (normal, estimating and over alike), waving on a new day, holding the phone when there is nothing to show. No cheering under target, no sad face over it — that would be judging progress, and Circa judges nothing. Estimating keeps the writing pose: the mascot is never the analysing indicator (rule 8); the ochre line says it.

This amends mascot rule 8 for home-screen widgets only. The number is the largest thing on the widget and sits top-left; the mascot is cropped by the edge, decoration only, hidden from VoiceOver, and drawn at rest — widgets do not animate.

The number is accentLarge (#A8762A, dark #D9A94E): the palette's colour for large numerals, and the plate's own ochre. It carries the dotted rule whenever an estimate is in it (rule 1). On a new day it is the saved target, so it carries none. The Day card's headline does not carry the dotted rule yet.

Small: calories only, as decided. Medium: the mascot standing on the left, the number, and a card with protein, carbs and fat — grams eaten above a bar against the target, one ink.

Lock screen: no mascot. Accessory widgets render in one system tint, which would recolour the drawings (rule 7). The system gauge carries progress instead — one ring, calories eaten against the target, never a ring per macro. The rectangular puts the steaming bowl in its gauge; the circular puts the number in its own.

Unchanged from round 1: one tap opens Today; free, not Pro; the lock screen shows the number whenever the screen is on; signing out clears the snapshot; no streak, no burn, no weight, no app name.

To check on a device: the iOS 18 tinted home screen (the mascot keeps its own colours or desaturates — it never takes the tint) and StandBy.

### note-paywall-15e (page-1)

THE PAYWALL, THREE PAGES (15e) · settled 8 October

Replaces Paywall and Paywall · dark in Row 5. Build-order 15e owns the rules.

One idea per page, and one number leads each: the calories on page 1, the billing date on page 2, the price on page 3. Same frame throughout: the plate mark, a large headline, the content, one button pinned to the bottom. ✕ on every page; Back on 2 and 3. Left-aligned, like the rest of Circa — a centred version was drawn and not chosen.

ORDER · 1 → 2 → 3 when the selected plan has a trial the person can take; 1 → 3 when it doesn't. Without a trial, page 3 drops "Nothing due today" and the trial wording, and the button says Subscribe (today: Continue). The plan rows say "3-day free trial", not "… available", so they stay on one line beside long prices.

PAGE 1 is personal only straight after onboarding: calories, goal and date from the saved plan, the logging-problem line, and the meal they tried — never called saved. In-app gates get the generic page 1.

Restore lives on page 3 only, two taps from page 1.

The plate mark, not the mascot: mascot rule 5 stands. SF Symbols in round wells, never emoji.

NOT COPIED FROM AMY · "we'll remind you" (no reminder is sent) · side-by-side plan cards (they truncate long prices) · a monthly price for the yearly plan (rule 1) · "Save 20%" · green.

The six invariants are marked in the source of every page-3 artboard. Prices are placeholders in a long currency on purpose; the build reads localizedPriceString.

DARK · the trial journey, pages 1–3. The button and Today's well invert (design rule 7). The plate mark has no dark twin, so it stays a light plate.

COPY · settled 9 October, and built. The plan line is the plan screen's own sentence (PlanCopy.headline): month and year only, never a day. The meal sentence has a second version for someone who didn't edit: "It shows what it assumed, and every amount is yours to change." Build-order 15e has every line.

## Not from the canvas — `app-icon/`

The plate app icon's sources, added 26 September 2026. They are not artboards and
do not sync with the canvas.

| File | Becomes |
|---|---|
| `icon-default.svg` | `AppIcon.appiconset/liftEatsLogo.png` |
| `icon-dark.svg` | `AppIcon.appiconset/liftEatsLogo 1.png` |
| `icon-tinted.svg` | `AppIcon.appiconset/liftEatsLogo 2.png` |

To re-export: render each at 1024 × 1024, then save as PNG with **no alpha
channel** (App Store Connect rejects one) — sRGB for default and dark, Gray Gamma
2.2 for tinted. Keep the plate centred and the corners square; iOS masks them. The
dark plate is dimmed on purpose: Apple asks dark icons to avoid excessively
bright images.
