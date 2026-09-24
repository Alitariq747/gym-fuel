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
| `PaywallDark.dc.html` | Paywall · dark |
| `ProofArabic.dc.html` | Arabic RTL |
| `ProofDark.dc.html` | Dark |
| `ProofDynamicType.dc.html` | Dynamic Type AX3 |
| `SavedMeals.dc.html` | Saved meals |
| `Settings.dc.html` | Settings |
| `SettingsDelete.dc.html` | Settings · delete account |
| `SettingsTargets.dc.html` | Settings · your targets |
| `StateAnalysing.dc.html` | Analysing · text + photo |
| `StateEmpty.dc.html` | Empty day |
| `StateFailed.dc.html` | Failed · retry |
| `Week.dc.html` | Week · after a check-in |
| `WeekEarly.dc.html` | Week · day 2 |

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

All data is placeholder. Photos are drawn placeholders, not food.

### note-entry (page-1)

THE ENTRY SCREEN

Goal fit is the one inverted block on the whole canvas — that is what makes it read first.

Confidence uses a dotted arc for the unfilled part, so the ring belongs to the same certainty language as the dotted number rules.

The three assumptions are DISPLAY ONLY. The line under them points at the one edit path, which keeps the cost at one AI call per correction.

Items carry per-item macros with calories dominant. NOTE: EstimatedItem in the current schema has name, quantity and estimatedComponents only — no macro fields. This needs the Step 6 schema and prompt change to be real.

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
