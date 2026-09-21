# Store Copy Deck

Paste-ready App Store Connect metadata. The argument behind it is in
`repositioning-strategy.md`; the build scope is in `project-brief.md`.

Written 5 September 2026. Revised 7 September: lifting removed from all
user-facing copy, exercise bullets deleted, "aloo gobi" retained as the lead demo (see Screenshot captions), app name reduced to a placeholder pending the rename decision.

Revised 8 September: **the name is decided — `Circa`.** Name and subtitle set, and
the name is now genuinely cuisine-agnostic, which resolves the contradiction this
deck previously carried (it declared the name agnostic while proposing
`[BRAND]: Desi Food Tracker`). **The keywords field now needs a pass — see the note
under Keywords.**

Revised 16 and 17 September: **the weekly check-in became a weekly page, and then the
weekly page was dropped.** `build-order.md` Step 4 now builds a plan the user can
see — a goal weight, a steady line to it, and saved targets that change only when
the user changes them — plus a Weight screen. The goal bullets in the description,
Shot 05 and the cheques below are rewritten to match.

Revised 19 September: copy now describes one meal with editable items, preserved
saved versions, and personal-target **and** day-aware Goal Fit at launch. Earlier
TestFlight users liked explicit assumptions. Claims about exclusive competitor
capabilities and unverified search-result counts have been removed. This remains
launch copy, conditional on the completion checks below.

---

## Sequence this correctly

**Name, subtitle, keywords and description are version-locked** — editable only
while a version sits in "Prepare for Submission", so they ship with the next build
and go through review.

**Promotional text is the exception:** editable any time, no review, no build. It
is the only free testing lever — use it to try hooks before committing one to the
subtitle.

---

## The fields

### App Name — 29 / 30

```
Circa: Food & Calorie Journal
```

Highest search weight of any field. Decided 8 September.

**Why `Circa`.** It means *approximately* — which is the product. Every other
candidate needed the subtitle to explain the idea; this one carries it in the name.
It is also cuisine-agnostic, which the beachhead strategy requires: cuisines are
delivered by keywords, screenshots and Custom Product Pages, never by the name.

**Why `Journal` and not `Tracker` or `Counter`.** Softer competition. In the top
six for "calorie journal" the weakest app has **0 ratings**; for "food journal",
407. Compare "calorie counter" at 14,972 and "macro tracker" at 7,856. With no
ratings we cannot enter the hard lanes, so the title takes the soft one and the
subtitle picks up *tracker* separately.

**Collisions checked.** Four other `Circa` apps exist — Games, Lifestyle, Social.
One shares the category, `Circa: Health Intelligence`, at 0 ratings with a
different job. No meaningful clash.

> **Still open: the trademark.** Circa Lighting, Circa Resort & Casino and Circa
> Sports are real companies. A different class does not block an app, but the odds
> of a registered mark are higher here than for an invented word. **Run a USPTO
> search on classes 9 and 42 before submitting.**

### Subtitle — 29 / 30

```
AI macro tracker, no weighing
```

Shares **no word** with the app name — Apple indexes them together and duplicates
are wasted characters. Name carries *circa / food / calorie / journal*; subtitle
carries *AI / macro / tracker / weighing*.

**Why not `No weighing, no food database`** (the alternative, also 29): it repeats
**food**, which the title already owns, so four characters buy nothing. And its one
distinctive word is worthless in search — the top six for "food database" bottoms
out at **0 ratings**, not because the term is winnable but because nobody types it.
It is a sentence you say to a person, not a query.

The version above adds four fresh words instead of two. That matters more than it
sounds: Apple builds search phrases by *combining* indexed words, so distinct words
multiply into long-tail phrases ("calorie macro journal", "AI food journal") while
duplicates multiply nothing.

> **The trade, and where it goes instead.** `No weighing, no food database` is the
> better *conversion* line — it says why we are different in five words, and the
> subtitle is visible in search results. Run it as **promotional text**, which is
> editable any time with no review, and promote it into the subtitle at a later
> submission if it converts.

### Keywords — 100 / 100 in the primary locale

```
roti,kunna,biryani,karahi,daal,halal,pakistani,indian,curry,protein,macros,bulk,deficit,homemade,gym
```

No spaces after commas — a space costs a character. Apple adds plurals and the
category automatically.

> ### ⚠ This field is now stale — decide before submitting
>
> The string above was written against the old name and subtitle. Two things broke
> when those changed on 8 September, and **neither is fixed below — this needs your
> call, not mine.**
>
> **1. `macros` is now a duplicate.** The subtitle carries *macro*, and Apple stems
> plurals automatically (as this section itself notes). Seven characters buying
> nothing.
>
> **2. `desi` is missing entirely.** It was never in this field because the old name
> carried it. The new name is agnostic, so the highest-value cuisine term is now
> nowhere in the listing. Calorify, Khana AI, MasalaFit and RotiCal all put *Desi*
> in their **app names**, which outranks our keywords on those searches — being
> absent from the field altogether concedes the term completely.
>
> **3. `home` and `cooking` are now free**, since the old subtitle released them.
>
> Proposed replacement — swaps `macros` for `desi`, 98/100 with 2 spare:
>
> ```
> roti,kunna,biryani,karahi,daal,halal,pakistani,indian,curry,protein,desi,bulk,deficit,homemade,gym
> ```

Keywords are invisible to users, which is why goal and gym terms stay here even
though lifting is off the surface: ranking for them costs nothing and catches the
users who pay most.

**This is not our ceiling.** See Cross-localization below — the US storefront
indexes ten locales, so the real budget is up to 1,440 characters, not 100. Fill
this field first, then spill the overflow into secondary locales.

### Promotional Text — 148 / 170

```
Understand the food you actually eat. Describe your meal, see the portions and ingredients assumed, correct your version, and save it for next time.
```

Sits above the description on the product page. **Rotate weekly against creator
posts** to find the hook that converts, then promote the winner into the subtitle
at the next submission.

**First thing to test here: `No weighing, no food database`** — the subtitle that
lost on ranking grounds but wins on conversion. This field costs nothing to change
and needs no review, so it is where that line earns its place before it takes a
subtitle slot.

### Description — 1,963 / 4,000 (with Pro placeholder)

Lead with the user's own food and the correction experience. Show the product's
behavior instead of asserting that other apps cannot do it.

```
Understand the calories in the food you actually eat — including the way you make it.

Tell Circa what you ate — "two roti, chicken karahi, half a katori rice" — or take a photo. See one meal with an estimated breakdown of its items, portions, calories and macros.

Circa shows the ingredients and quantities it assumed. Less mayonnaise in your wrap? A smaller portion of rice? Correct the amount, see the difference, and save your version for next time.

WHAT IT'S GOOD AT

• Home-cooked food. Karahi, daal, biryani, salan — describe the meal in familiar portions such as rotis, katoris and cups.
• Restaurant and street food. Describe your order and review the estimate's assumptions.
• Photos, when you'd rather not type. Point the camera at the plate.
• Being corrected. Adjust item quantities, or describe a change in ingredients or preparation. See how the meal total changes.
• Honest uncertainty. Review what was assumed. Saving an estimate does not make it an exact measurement.

WHEN YOU'RE WORKING TOWARD SOMETHING

• Lose fat, maintain or gain. Set a goal weight and see a steady path to it, with protein, carbs and fat worked out for you — not a generic diet template.
• Targets that show their working. Every number comes with the reason behind it, and nothing changes unless you change it.
• Goal Fit with a reason. See how a meal contributes to your personal targets, considering the meals you logged earlier that day. Based on your logged meals; not a health rating.
• Your weigh-ins against your plan. Weigh in by hand or sync from Apple Health, and see how it's going.

SAVED MEALS

Your breakfast, your usual order, your own recipe — save the corrected breakdown and its assumptions, then log that version again without starting over.

Circa PRO

[Trial length, price and renewal terms — must match App Store Connect exactly.]

Nutrition figures are estimates for general guidance, not medical or dietary advice. Sources are listed in the app.
```

**Keep the Pro block in sync with the actual intro offer.** Step 1 is complete:
the paywall reads the trial length from StoreKit. Launch pricing and the trial
remain as decided in `build-order.md` Step 0. Replace the placeholder before
submission and verify the listing against the configured offer.

---

## Screenshot captions

Shots 1–3 appear in search results. The ordering *is* the positioning — wide mouth
first, depth second.

| # | Caption | Job |
|---|---|---|
| 01 | Understand the food you actually eat. | The promise |
| 02 | Just say what you ate. | The solution |
| 03 | It shows you what it assumed. You fix what's wrong. | The trust |
| 04 | Targets from your bodyweight and your goal. | The depth |
| 05 | Your plan, and how it's going. | The plan |
| 06 | How this meal fits your day — with the reason. | Personal targets and earlier logged meals |

Shots 1–3 sell the food problem to everyone; 4–6 sell the goal side to the people
who will actually pay.

---

## How to say it out loud

For creators, for the App Store, for anyone who asks what you're building.

**One sentence**

> Understand the food you actually eat: see what went into the estimate, correct
> what's different, and save your version.

**Thirty seconds**

> Your wrap, biryani or homemade dinner depends on the ingredients and portions
> you actually ate. Circa lets you describe the meal or take a photo, then shows
> the estimated breakdown and what it assumed.
>
> If it assumed two tablespoons of mayonnaise and you used one, correct the
> amount and see the difference. Save your version so next time is easier.
>
> Goal Fit explains how the meal contributes to your targets, considering what
> you've already logged that day.

**Demonstrate the correction.** Earlier TestFlight feedback supports the value of
explicit assumptions. The launch demonstration should show an actual edit and its
effect, then reuse the saved version. Competitors also expose sources or editable
ingredients; do not claim that assumptions or explanations are exclusive to Circa.

---

## What this copy promises that the build doesn't yet deliver

**Verify every promise before the listing goes live.** Steps 0–4 are complete;
the remaining food and scoring promises depend on Steps 5–7.

| Copy | Gap |
|---|---|
| "It shows you what it assumed" | True, but buried one tap deep in `LogEntryDetailSheet` — needs to be on the timeline card |
| One meal with an editable breakdown | Steps 5–6 retain one meal, expose structured quantities/nutrition and reconcile the totals |
| Correct an amount and see the difference | Steps 5–6 preserve unaffected items and show the resulting change |
| Save the corrected version | Step 6 preserves breakdown, assumptions and provenance through save/re-log/relaunch |
| "Set a goal weight and see a steady path to it" | Steps 4c–4f complete; verify final visuals and wording before capture |
| Targets change only when the user acts | Step 4 complete; this promise applies to targets, not derived Goal Fit assessments |
| "Your weigh-ins against your plan" and Shot 05 | Step 4e complete; capture the actual plan screen |
| Shot 06 and contextual Goal Fit | Step 7 must deliver personal-target and day-aware assessment together, with an explanation from the same factors |

Historical assessments use current saved targets and say so. Adding a later meal
does not alter earlier scores; correcting an earlier log can affect later scores.
Do not advertise permanent scores, verified accuracy or an overall health grade.

---

## App Store Connect — the distribution surface

The highest-leverage work available, and none of it is code. Apple reviews these
in a day or two.

### Custom Product Pages — up to 70

Same app, same name, same price; **different screenshots and promotional text per
page**, each with its own URL. The limit doubled from 35 to 70 on 29 October 2025,
and as of 2026 you can **assign keywords to a CPP so it appears in organic
search**, not just Search Ads.

This routes around the constraint that metadata is served by device language, not
storefront. We cannot show a desi listing only to desi Brits — but we can run:

| Page | Screenshots | Given to |
|---|---|---|
| Default | Generic home cooking | Organic search, broad terms |
| Desi | Biryani, roti, karahi | Desi creators, desi keywords |
| *(later)* West African | Jollof, egusi | That creator set |
| *(later)* Arab / Gulf | Machboos, kabsa | Gulf creators |

One app, no new build, no rename dependency. **Each creator cohort gets its own
link**, which also makes attribution legible — you learn which cuisine converts
before committing the main listing to it.

Note what CPPs do *not* do: they assign keywords **from the existing field**, they
do not add keyword space. That comes from cross-localization, below.

### Cross-localization — up to 1,440 indexable characters

The US storefront indexes **ten** locales: English (U.S.) as primary plus nine
secondaries — Spanish (Mexico), Russian, Chinese (Simplified), Chinese
(Traditional), Arabic, French, Portuguese (Brazil), Vietnamese and Korean.

Each contributes title 30 + subtitle 30 + keywords 100 = **160 indexable
characters**. Filling them all takes the US footprint from 160 to ~1,440.

Two things follow:

- **Arabic pays twice.** It is one of the nine US-indexed secondaries *and* the
  Gulf storefront localisation we already wanted. One piece of work, two returns.
- **Do two locales properly, not nine lazily.** Apple has begun rejecting listings
  that paste identical or machine-dumped metadata across languages. Treat each as
  real copy.

**Timing:** keyword rankings take roughly four weeks to settle after a change.
Ship the new listing and you will not know whether it worked for a month — plan
the creator push around that, not against it.

---

## Cuisine reach

The name and subtitle are deliberately cuisine-agnostic — `Circa: Food & Calorie
Journal` covers kunna, jollof, adobo and tagine equally, because it names no
cuisine at all. Only the keywords and screenshots are desi-specific, and both are
cheap to change. **As of 8 September this is finally true**; the deck previously
claimed agnosticism while proposing `Desi Food Tracker` in the name.

**What that costs, stated plainly.** Calorify, Khana AI, MasalaFit and RotiCal all
put *Desi* in their **app names** — the highest-weight field. Carrying it in
keywords instead means ranking below them on desi searches. The trade is reach:
Arabic, West African or any other cuisine can be added later with no rename.

This matters because App Store metadata is served by **device language, not
storefront**, and the only English variants App Store Connect offers are U.S.,
U.K., Australia and Canada. A Pakistani-British user in London sees the English
(U.K.) listing — the same one every other British person sees. The *default*
listing therefore has to carry every cuisine, which is why the name and subtitle
stay generic. Custom Product Pages are how the specificity gets delivered to the
people it is for — see above.

The brand stays broad. Launch examples can emphasize Pakistani/home-cooked meals
the founder and testers know, alongside everyday foods. Expanding a cuisine lane
requires checking its portions and preparation assumptions as well as changing
the marketing examples.

**Additional localisation follows `build-order.md`.** Urdu and Hindi remain out
of this launch's scope. Future choices should use observed demand, regional
proceeds and inference cost, rather than assuming a language cannot monetize.
