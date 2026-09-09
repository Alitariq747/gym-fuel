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

### Promotional Text — 160 / 170

```
Most calorie apps are built around barcodes and packaged food. Most of what you eat isn't. Describe your meal in plain words — and see every assumption we made.
```

Sits above the description on the product page. **Rotate weekly against creator
posts** to find the hook that converts, then promote the winner into the subtitle
at the next submission.

**First thing to test here: `No weighing, no food database`** — the subtitle that
lost on ranking grounds but wins on conversion. This field costs nothing to change
and needs no review, so it is where that line earns its place before it takes a
subtitle slot.

### Description — ~1,830 / 4,000

Only the first three lines show before the fold on iPhone, which is why the aloo
gobi line leads: it is *always* true, because it is a claim about variance rather
than absence.

```
Search "aloo gobi" in a normal calorie app and you get forty entries, from 80 to 400 calories. None of them are how your mum makes it.

Circa doesn't have a food database. You say what you ate — "two roti, chicken karahi, half a katori rice" — and it works out the calories and macros from the description. Then it shows you every assumption it made, so you can fix the ones that are wrong.

That's the whole difference. Other apps hand you a number and hope you trust it. Circa shows its working.

WHAT IT'S GOOD AT

• Home-cooked food. Karahi, daal, biryani, salan — described the way you'd describe them to a person. In rotis and katoris, not grams of a branded product.
• Restaurant and street food that was never in anyone's database.
• Photos, when you'd rather not type. Point the camera at the plate.
• Being corrected. Every estimate comes with its confidence, its assumptions, and a breakdown per item. Change any of it, or re-run it with a better description.

WHEN YOU'RE WORKING TOWARD SOMETHING

• Lose fat, maintain or gain. Your protein, carbs and fat come from your bodyweight and your goal, not a generic diet template.
• Targets that move. Weigh in through the week and your numbers adjust to what your body is actually doing — instead of a formula that guessed once and never updated.
• Every meal scored out of 100 against your goal, with the reasoning behind it.
• A weekly check-in: what you averaged, what changed, and what your new numbers are.

SAVED MEALS

The things you eat every week — your shake, your breakfast, your usual order — saved once, logged in a tap.

Circa PRO

[Trial length, price and renewal terms — must match App Store Connect exactly.]

Nutrition figures are estimates for general guidance, not medical or dietary advice. Sources are listed in the app.
```

**Keep the Pro block in sync with the actual intro offer.** A mismatch between
listing copy and App Store Connect is a 3.1.2 rejection — and the paywall itself
still hardcodes `"3-day"` at `SubscriptionPaywallSheet.swift:351,364,379`, which
becomes blocking the moment the trial changes to 14 days.

---

## Screenshot captions

Shots 1–3 appear in search results. The ordering *is* the positioning — wide mouth
first, depth second.

| # | Caption | Job |
|---|---|---|
| 01 | Forty entries for aloo gobi. None of them yours. | The problem |
| 02 | Just say what you ate. | The solution |
| 03 | It shows you what it assumed. You fix what's wrong. | The trust |
| 04 | Targets from your bodyweight and your goal. | The depth |
| 05 | They move as your weight moves. | The engine |
| 06 | Every meal scored — with the reason. | Retention |

Shots 1–3 sell the food problem to everyone; 4–6 sell the coach to the people who
will actually pay.

---

## How to say it out loud

For creators, for the App Store, for anyone who asks what you're building.

**One sentence**

> Every calorie app is a database of packaged food. This is the one that works on
> the food you actually cook.

**Thirty seconds**

> Calorie apps were built around barcodes. That works for a protein bar and falls
> apart on dinner. Search "aloo gobi" in MyFitnessPal and you get forty entries
> between 80 and 400 calories — none of them your mum's.
>
> This app has no food database at all. You describe the meal the way you'd
> describe it to a person — "two roti, chicken karahi, half a katori rice" — and it
> estimates from the description. Then it tells you what it assumed: two
> tablespoons of ghee, a 30 cm roti. If that's wrong, you change it.
>
> Every other app hands you a number and hopes you trust it. This one shows its
> working.

**The load-bearing word is "assumed".** It is the one thing no competitor can say,
because none of them store their reasoning. We already do — `confidence`,
`assumptions[]` and `estimatedItems` are on every entry. It converts "the AI is
guessing" from the objection into the feature. If a line has to be cut, cut
anything else first.

---

## What this copy promises that the build doesn't yet deliver

Three lines are writing cheques against unbuilt work. All three are Phase 1 in
`project-brief.md`. **Ship them before the listing goes live, or soften the lines
until you have.**

| Copy | Gap |
|---|---|
| "It shows you what it assumed" | True, but buried one tap deep in `LogEntryDetailSheet` — needs to be on the timeline card |
| "two roti, chicken karahi, half a katori rice" | Three entries from one sentence; `LogComposerViewModel` creates one entry per submission |
| Shot 05, "They move as your weight moves" | The adaptive engine is Phase 3. **Do not ship this caption before it exists.** |

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

Swapping beachhead is mechanical: dish names in the keywords, dish names in the
description bullets, one screenshot. Nothing structural changes, because the real
claim is that packaged-food databases don't cover what people cook.

**Arabic is the best second localisation** — high Gulf ARPU, large South Asian
expat populations, and its own uncovered cuisine. Post-launch. **Not Urdu or
Hindi:** that acquires the users who can't cover our inference cost.
