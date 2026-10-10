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
| `AmountsAEditing.dc.html` | Amounts · A · editing |
| `AmountsAReady.dc.html` | Amounts · A · ready to save |
| `AmountsAsBuilt.dc.html` | Amounts · as built |
| `AmountsBEditing.dc.html` | Amounts · B · editing |
| `AmountsBReady.dc.html` | Amounts · B · ready to save |
| `AmountsCOpened.dc.html` | Amounts · C · opened |
| `AmountsCStepped.dc.html` | Amounts · C · after a few taps |
| `AmountsDOpen.dc.html` | Amounts · D · a line open |
| `AmountsDTyping.dc.html` | Amounts · D · typing |
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
| `OnbWidgetHome.dc.html` | Onboarding · widget · Home Screen |
| `OnbWidgetHomeDark.dc.html` | Onboarding · widget · Home Screen · dark |
| `OnbWidgetLock.dc.html` | Onboarding · widget · Lock Screen |
| `OnbWidgetLockDark.dc.html` | Onboarding · widget · Lock Screen · dark |
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
| `PhotoAReady.dc.html` | Photo · A · ready |
| `PhotoATyping.dc.html` | Photo · A · typing |
| `PhotoAsBuilt.dc.html` | Photo · as built |
| `PhotoAsBuiltTyping.dc.html` | Photo · as built · typing |
| `PhotoBReady.dc.html` | Photo · B · ready |
| `PhotoBTyping.dc.html` | Photo · B · the text sheet, filled |
| `PhotoCReady.dc.html` | Photo · C · ready |
| `PhotoCTyping.dc.html` | Photo · C · typing |
| `PhotoReading.dc.html` | Photo · reading |
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
| `TryMealAsBuilt.dc.html` | Try a meal · as built |
| `TryMealAsBuiltWorking.dc.html` | Try a meal · as built · estimating |
| `TryMealEdited.dc.html` | Try a meal · after an edit |
| `TryMealEmpty.dc.html` | Try a meal · ready to write |
| `TryMealEstimatingA.dc.html` | Try a meal · A · estimating |
| `TryMealEstimatingB.dc.html` | Try a meal · B · estimating |
| `TryMealExample.dc.html` | Try a meal · example |
| `TryMealFirstGuess.dc.html` | Try a meal · first guess |
| `TryMealWriting.dc.html` | Try a meal · writing |
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
Row 10: onboarding · the widget step — 10 October.
Row 11: the amounts editor, four versions — A's bar built, D dropped — 10 October.
Row 12: onboarding · try a meal, redrawn — A built — 11 October.
Row 13: photo · check the words, three directions — 11 October.

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

### note-widget-step (page-1)

ONBOARDING · THE WIDGET STEP · drawn 10 October

One screen, after reminders and before the plan. Both are about remembering to write, and the plan and paywall stay one moment.

The preview is the real widget, not a picture of one. The build draws the widget's own views with TodaySnapshot.sample() — 1,020 left of 2,400 — the same made-up day iOS shows in the widget gallery, so the person recognises it when they search. Not their own number: the plan screen reveals that next, with its working.

Home Screen and Lock Screen are one segmented control, the existing UnitToggle. It swaps the panel and the four steps; nothing else moves. Both panels are the same height.

The Home panel suggests a Home Screen: the widget, the name iOS prints under it, blank tiles. The Lock panel's clock and wallpaper are the system's, drawn for placement only. No phone frame and no status bar.

One line per step at standard text size. iOS 17 has no Edit button, so there step 2 reads "Tap + in the top corner." Every other line is the same on every supported iOS.

Continue only. Nothing is asked of iOS, so there is nothing to skip. The mono line is there because anyone who adds the widget now sees "Your day shows here" until the plan is saved.

No mascot above the content: the panel is the illustration, and the medium widget already carries the still mascot (mascot rule 8, the widget exception).

NOT COPIED FROM AMY · "people that add this are 75% more likely to build the habit" (no invented numbers, Step 15) · the eyes emoji (rule 10) · a phone frame and wallpaper (no fake chrome) · purple · "Tap + on the top left" for everyone (iOS 18 changed it to Edit) · "Bonus: tap any nutrition ring" (no rings; a tap opens the app where it was left).

Not drawn, offered separately: saying "Added" once WidgetCenter reports a Circa widget on the phone.

### note-amounts (page-1)

THE AMOUNTS EDITOR · four versions · 10 October

DECIDED, SAME DAY · A's bar is built. D was built and dropped.

Built: the total and its change ride the keyboard with Save. Tapping outside a field, or the bar's keyboard button, puts the keyboard away. A compact title, with one line under it saying what an edit does. Every field stays in view, as before.

Not built: A's per-line calories and its "Estimated … · Reset" notes. B and C were never built.

Dropped: D — lines that open one at a time, with ½× 1× 1½× 2× of the estimate. In use, fields that were all already there read better. design.md rule 2 holds the rule.

The rest of this note is the record of the four versions as drawn.

The pencil on Entry's breakdown opens this sheet. It is where an estimate becomes the person's own meal, so it should show what each change does while it is being made.

AS BUILT · the pins
1 · The estimate disappears. Once an amount is typed, nothing shows what Circa first assumed.
2 · The total and Save sit under the keyboard.
3 · No line shows its calories, so a change can't be traced to the number it moves.
4 · Tapping outside a field leaves the keyboard up.

IN EVERY VERSION
· Tapping outside a field, or dragging the list, puts the keyboard away.
· Every line shows its calories, live, with the dotted rule. An adjusted estimate keeps it (contract §5).
· A changed line names its estimate — "Estimated 1 tbsp · 120 kcal". Reset writes the estimate back, which clears the adjustment (§6).
· The total and its change stay on screen with the keyboard up, in the build's own format: 665 → 708 kcal · +43. Both ends are displayed totals, so the rows agree with it (§6).
· Save is reachable without putting the keyboard away.
· A dish priced by its parts shows its bowl and never edits it; its parts are the handles (§4). A descriptive part says "no amount".
· One line under the title says what happens: the calories scale, nothing else is re-estimated.

A · THE TOTAL RIDES THE KEYBOARD
Today's layout. The delta line and Save move into a bar pinned to the bottom of the sheet, so it sits on the keyboard instead of under it. The keyboard icon puts it away. The smallest change.

B · THE MEAL ON TOP
The Entry's nutrition card, small and live, pinned above the list: calories, protein, carbs and fat, each with its change. The estimate is struck through beside the field, with the line's change under its calories. Cancel and Save move to the top bar; the keyboard gets up, down and Done.

C · STEPPERS FIRST
− and + step by half a measure, or 10 g, so most corrections never open the keyboard. Tap the number to type an exact one. Total bar as A.

D · ONE LINE AT A TIME
The list reads like Entry's breakdown: amount and macros on the meta line. Tap a line to open it — the field, quick multiples of the estimate (½× 1× 1½× 2×; 1× is the estimate) and "120 → 60 kcal". Total bar as A.

Deltas are ink and provenance is ochre: no colour for up or down (rule 5). Light only for now; dark and AX3 follow the chosen version.

The same meal throughout: oil 1 → 0.5 tbsp (−60) and rice 1 → 1.5 cup (+103) make 665 → 708.

### note-try-meal (page-1)

ONBOARDING · TRY A MEAL · redrawn and built 11 October

DECIDED, SAME DAY · A is built. B was not chosen. The example fallback was drawn and left as built.

The third screen, and Step 15's aha. As built it read like a form and waited like a demo. This row redraws it in the app's own language. The flow, the limits and the fallback stay as 15b and 15c built them.

AS BUILT · the pins
1 · The field doesn't look like one: no edge, and a grey "Your meal" that reads as a caption.
2 · The examples are bordered buttons, so they outweigh the field they fill.
3 · The wait is a system spinner, the one thing rule 1 rules out.
4 · The page is empty while it waits, so the answer arrives all at once.

READY TO WRITE · The field is the one raised surface on the page: a white card with the dock's soft shadow (circaLift), a placeholder that says what to do, and its real 200-character limit in mono. The examples become three lines on paper with an ochre ↖. Tapping one fills the card.

WRITING · The card takes an ink border, and the counter counts. Estimate this rides the keyboard; the examples and "Show me an example instead" wait under it.

ESTIMATING · A (built) · The page takes the answer's shape at once: their words as the title, the Entry nutrition card with the dotted rule alone where each number will land (rule 1), and a Breakdown card holding the status line and the timeline's ochre sweep. Waiting and answered are one view, so when the answer lands the numbers appear on their rules and rows replace the status. Nothing above them moves. The status changes every three seconds, as the timeline's does: reading your words → estimating calories and macros → preparing your breakdown. No spinner, no percentage.

ESTIMATING · B (not chosen) · Their sentence large, with an ochre dotted rule sweeping under the words while it's read. More of a moment, but when the answer lands the sentence has to move up into the title and the cards rise under it: one transition where A has none.

FIRST GUESS · Their words stay the title, verbatim (rule 3), where the old build showed Circa's tidied name. The nutrition card leads, calories loudest. The biggest assumption sits in the sunken card with the question and the one Change an amount button; the pencil on Breakdown opens the same sheet. With no assumption, the card keeps the question and the button. Continue stays primary: the edit is invited, never required (15c).

AFTER AN EDIT · The nutrition card's calorie row becomes the change: the first guess struck through, theirs large in ochre on the dotted rule, the difference and what they changed, and the editor's own promise: "Only the amounts you changed were scaled. Nothing else was re-estimated." The changed row says "You set the amount". The button becomes "Let's find your targets": the body questions come next, and the plan screen shows this meal against the calorie target. The first guess keeps Continue.

EXAMPLE · Drawn, not built: the fallback in the same frame — the notice, the example as the title, one card.

NEW COPY · the placeholder, the three status lines, "This takes a few seconds.", the line under the assumption, the correction line and the promise. Everything else is the build's.

UNCHANGED · the 20 s timeout and three tries, the example path, nothing saved, no mascot (mascot rule 5). Built from CircaCard, CircaEstimate's pending rule, CircaProgressRail, DetailMacroSummaryCard, MealBreakdownCard and the amounts editor.

Light only. The build takes dark from the kit's tokens, and the change stacks at AX sizes (rule 8).

The same meal throughout: "rice with chicken stew", oil 2 → 1 tbsp makes 705 → 585 (−120).

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
