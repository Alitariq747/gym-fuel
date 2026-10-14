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

Revised 19 and 22 September: copy now describes one meal with editable items and
preserved saved versions. The meal score is no longer a launch feature. Earlier
TestFlight users liked explicit assumptions. Claims about exclusive competitor
capabilities and unverified search-result counts have been removed. This remains
launch copy, conditional on the completion checks below.

Revised 12 October: **the keywords pass is done, split by English locale.** English
(U.S.) carries broad terms only; a new English (U.K.) localisation carries the desi
terms, because it is the default language in Pakistan, India, the UK and the Gulf.
Arabic moves to a later update.

Revised 14 October: **the description is final** — staples-first examples, widgets
added, and the Pro placeholder replaced with no price or trial length. A new
promotional text with its first test, What's New for 1.1, and the App Review notes
were added the same day.

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

> **The trademark — searched 12 October, risk accepted 14 October.** Of 123 live
> US marks containing "circa", none covers food, nutrition or calorie tracking.
> The closest: NeuroBusiness Group, LLC holds two class 9 registrations for the
> plain word CIRCA (Reg. 6947766 and 6950079, January 2023) for anxiety and stress
> app software, in use as "⊛ CIRCA" in Health & Fitness. Circa Sports' owner has a
> pending class 9 application for a hotel and casino app. Different jobs, and the
> full store name sets Circa apart, so the name stays. Two consequences: a
> complaint to Apple remains possible, and registering CIRCA ourselves for app
> software would likely be refused. The UK and Pakistan registers were not
> searched.

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

### Keywords — one field per English locale

Decided 12 October. Metadata is chosen by language, not country, and Apple sets
**English (U.K.)** as the default language for Pakistan, India, the UK, the UAE
and Saudi Arabia. The US storefront reads English (U.S.) and its nine secondaries,
never English (U.K.). So the two fields do different jobs: the US field stays broad,
and the U.K. field carries the desi terms. See Cross-localization below.

No spaces after commas — a space costs a character. Neither field repeats a word
from the name or subtitle (*circa, food, calorie, journal, AI, macro, tracker,
weighing*); Apple indexes them together.

#### English (U.S.) — 99 / 100

```
counter,diary,meal,photo,diet,log,nutrition,protein,carb,weight,loss,deficit,homemade,recipe,intake
```

- `counter`, `diary`, `log` pair with *calorie* and *food* from the name: "calorie
  counter", "food diary", "food log".
- `meal`, `photo`, `nutrition`, `carb`, `intake`, `diet` build "meal tracker",
  "carb tracker", "calorie intake".
- `weight`, `loss` with *tracker*: "weight tracker", which the Weight screen backs,
  and "weight loss tracker".
- `homemade`, `recipe` are the positioning: "homemade food calories", "recipe
  calories".

#### English (U.K.) — 100 / 100

```
counter,diary,meal,photo,diet,desi,pakistani,indian,roti,biryani,daal,curry,homemade,protein,deficit
```

These storefronts never read the US field, so this one carries the broad terms as
well as the cuisine. Same name, subtitle and description as English (U.S.), in UK
spelling. Keywords are invisible, so the listing still looks broad to every British
user.

#### Left out, and why

- **No cuisine terms in the US field.** US desis lose desi search terms; the desi
  Custom Product Page reaches them through creator links instead. A US secondary
  locale can carry them later.
- `scan`, `scanner` — people searching them expect a barcode scanner.
- `gym`, `bulk` — the listing no longer speaks to lifters, a lifter who lands on a
  food journal leaves, and conversion feeds ranking.
- `kunna` (almost no searches), `halal` (searchers want halal food, not calories),
  `karahi` (space), `macros` (the subtitle has *macro*).

### Promotional Text — 161 / 170

Launch line, decided 14 October:

```
Made for the meals food databases miss: your mom's stew, last night's curry, the stir-fry you make your way. Describe it, see what Circa assumed, fix what's off.
```

**English (U.K.):** "mom's" becomes "mum's" (still 161).

Sits above the description on the product page and is not indexed for search. The
previous line ("Understand the food you actually eat…") was dropped because the
description directly below opens with the same idea.

**First test, about two weeks after launch** (125 / 170):

```
No weighing, no food database. Describe a meal in your own words or snap a photo, see what Circa assumed, and fix what's off.
```

It is the subtitle that lost on ranking grounds but may win on conversion. It does
not lead at launch because the subtitle above it already says "no weighing". This
field costs nothing to change and needs no review. Give each line at least two
weeks, compare product page conversion rate (installs ÷ product page views) in App
Analytics, and promote the winner into the subtitle at the next submission.

### Description — 2,771 / 4,000

Final 14 October; every claim checked against the build and the backend. Lead
with the user's own food and the correction experience. Show the product's
behavior instead of asserting that other apps cannot do it.

```
Understand the calories in the food you actually eat — including the way you make it.

Tell Circa what you ate — "two eggs, toast and a cup of tea" — or take a photo. You get one meal broken into its items, each with an estimated portion, calories, protein, carbs and fat.

Circa shows you what it assumed. Less oil in your noodles? A smaller bowl of rice? Change the amount, see the difference, and save your version for next time.

WHAT IT'S GOOD AT

• Home cooking. The stew, the curry, the stir-fry — meals no packaged-food database knows. Describe them in the portions you use: a plate, a bowl, two rotis, a cup.
• Restaurant and takeout meals. Describe your order and check what the estimate assumed.
• Photos, when you'd rather not type. Take one or pick one from your library, then check the words Circa read from it before it estimates.
• Being corrected. Change an amount, or say what was different — the ingredients or how it was cooked — and Circa estimates the meal again.
• Honest uncertainty. Every number is an estimate and looks like one. Saving a meal doesn't turn it into a measurement.

WHEN YOU'RE WORKING TOWARD SOMETHING

• Lose fat, maintain or gain. Set a goal weight and see a steady path to it, with daily calories, protein, carbs and fat worked out for you.
• Targets that show their working. Each number comes with the reason behind it and its sources, and nothing changes unless you change it.
• Weigh-ins, typed or from Apple Health. See your weight over time against your goal, and how far there is to go.

SAVED MEALS

Your usual breakfast, your regular order, your own recipe. Save the corrected version with its items and assumptions, then log it again without starting over.

ALSO

• Home Screen and Lock Screen widgets with the calories left today.
• Daily reminders at set times, or none at all.
• Share any meal as an image.

CIRCA PRO

Estimating meals from text and photos needs Circa Pro, a monthly or yearly auto-renewing subscription. New subscribers may be offered a free trial. Pro includes up to 500 meal estimates a month, or 50 during the trial. Prices for your country are shown in the app before you subscribe.

Payment is charged to your Apple Account at confirmation of purchase. Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel it anytime in your Apple Account settings.

Circa is for adults 18 and over. Nutrition figures are estimates for general guidance, not medical or dietary advice. Sources are listed in the app.

Privacy Policy: https://ahmadtariq.co/apps/circa/privacy
Terms of Service: https://ahmadtariq.co/apps/circa/terms
Terms of Use (Apple standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

**English (U.K.):** the same text with "takeout" changed to "takeaway".

**Rules this text keeps:**
- **No price or trial length.** English (U.K.) is also the listing in Pakistan and
  India, where a dollar price would be wrong; the store shows each country's price.
- **The 500 and 50 match the backend's quota settings and the Terms.** Change all three
  together. The paywall does not show the cap, and 3.1.2 does not require it there.
- **The Apple Health mention stays** — 2.5.1 expects HealthKit apps to say so.
- **The Apple standard EULA link stays** — a missing one is a common 3.1.2 rejection.
- **Staples first, one desi touch** ("two rotis"), matching the default screenshots.

### What's New in This Version — 763 / 4,000

Decided 14 October, for version 1.1. The same text for both English locales.

```
LiftEats is now Circa: a new name, a new look and a new focus on the food you actually eat.

• Every meal is broken into its items, with the portions and ingredients Circa assumed. Change an amount or say what was different, and the total follows.
• Save the corrected version of a meal and log it again without starting over.
• Set a goal weight and get a plan: daily calories, protein, carbs and fat, each with the reasoning and sources behind it.
• Weigh in by hand, or bring your weight in from Apple Health.
• Widgets for your Home Screen and Lock Screen.
• Share any meal as an image.

Workout logging, meal scores and streaks have been removed, so Circa can focus on food.

Already subscribed? LiftEats Pro carries over as Circa Pro. There's nothing to do.
```

- **The rename leads**, because the Updates tab shows only the opening lines and an
  existing user's icon and name change overnight.
- **Only what is new since LiftEats 1.0.** Photo logging, saved meals and reminders
  were already in 1.0.
- **The removals are named**, so a 1.0 user is not left looking for them.
- **The subscription line holds** because the `lifteats_` product IDs and the
  `ai_scans` entitlement are unchanged.

### App Review Information — notes

Decided 14 October. Every path and button name was checked against the build.
Fill in the two bracketed lines; the notes field allows 4,000 characters.

```
Circa (formerly LiftEats) is a food journal. Describe a meal in words or take a photo, and Circa estimates its calories and macros, shows the portions and ingredients it assumed, and lets you correct them. Workout logging from the previous version has been removed.

DEMO ACCOUNT
On the Welcome screen, tap "Already have an account? Sign in". Onboarding is complete, and the account has meals and weigh-ins but no subscription.
Email: [demo email]
Password: [demo password]
To see onboarding instead, tap "Get Started". It lets you try one typed meal before creating an account, and ends with the paywall, which can be dismissed.

SUBSCRIPTION
Estimating a meal needs Circa Pro, an auto-renewable subscription (monthly or yearly, with an introductory free trial). Tapping the text or camera button asks for AI permission (below), then opens the paywall; a sandbox purchase unlocks estimates. "Restore Subscription" is on the paywall, which Settings > Subscription > Upgrade also opens.

AI DISCLOSURE (5.1.2(i))
Before the first estimate, Circa explains that the meal text or photo is sent to OpenAI through Circa's server, and asks permission. Nothing is sent if you decline.

AGE
Circa's plan is for adults. The age step in onboarding accepts 18 or older only.

APPLE HEALTH
Optional and read-only. Circa reads body mass to add weigh-ins, and writes nothing to Health. It is offered during onboarding and in Settings > Apple Health > Weight Sync. Weigh-ins appear on the Weight screen (Settings > Body Metrics > Weight).

HEALTH INFORMATION (1.4.1)
Calorie and macro targets come from published formulas, with safety limits: no calorie target below 1,200 kcal for women or 1,500 kcal otherwise, and no goal weight below a BMI of 18.5. Citations are under "Sources" on the plan screen and in Settings > Targets > Your targets. Meal figures are shown as estimates.

ACCOUNT DELETION
Settings > Account > Delete Account. It asks you to sign in again to confirm.

Settings is the gear icon at the top right of the Day screen.
```

**Before submitting:**

1. **Create the demo account** with email and password, not Sign in with Apple. Finish
   onboarding and add a few meals and weigh-ins. Logging needs Pro: a sandbox purchase
   on a TestFlight build works and lapses by itself within about an hour, leaving the
   account unsubscribed, as the notes say.
2. **Tick "Sign-in required"** and enter the same credentials in those fields too.
3. **Check that a sandbox purchase on a TestFlight build unlocks estimates.** The
   backend checks the subscription through RevenueCat; if a reviewer subscribes and
   estimates still fail, that is a 2.1 rejection.
4. **Fill in the contact name, phone and email.** An attachment is optional; a short
   screen recording of the paywall and the AI permission sheet can save a round of
   questions.

If a path or label in the app changes before submission, update these notes with it.

### Subscriptions — review notes and screenshots

Decided 14 October. One note per subscription, under Review Information → Review
Notes. No price or trial length: reviewers see both in StoreKit, so the notes stay
true if the trial changes.

**Circa Pro Monthly** (`lifteats_pro_monthly`)

```
Circa Pro Monthly (formerly LiftEats Pro Monthly) is an auto-renewable subscription, billed monthly. It unlocks AI meal estimates: describe a meal in words or take a photo, and Circa returns an estimated breakdown of its items, portions, calories and macros. Re-estimating a meal after a correction is included. It includes up to 500 estimates per month, or 50 during the introductory free trial.

Where to find it: the paywall appears at the end of onboarding, when you tap the text or camera button on the Day screen without a subscription (after the AI permission sheet), and from Settings > Subscription > Upgrade. Prices and trial terms come from StoreKit. "Restore Subscription" is on the paywall.

The product ID keeps its original "lifteats_" prefix because the app was renamed from LiftEats to Circa, and product IDs can't be changed.

A demo account is in the App Review Information for version 1.1.
```

**Circa Pro Yearly** (`lifteats_pro_yearly`)

```
Circa Pro Yearly (formerly LiftEats Pro Yearly) is an auto-renewable subscription, billed yearly. It unlocks AI meal estimates: describe a meal in words or take a photo, and Circa returns an estimated breakdown of its items, portions, calories and macros. Re-estimating a meal after a correction is included. It includes up to 500 estimates per monthly usage cycle, or 50 during the introductory free trial.

Where to find it: the paywall appears at the end of onboarding, when you tap the text or camera button on the Day screen without a subscription (after the AI permission sheet), and from Settings > Subscription > Upgrade. Prices and trial terms come from StoreKit. "Restore Subscription" is on the paywall.

The product ID keeps its original "lifteats_" prefix because the app was renamed from LiftEats to Circa, and product IDs can't be changed.

A demo account is in the App Review Information for version 1.1.
```

- **"Per monthly usage cycle"** is how the backend resets the yearly plan's allowance,
  and the Terms' wording. Change the 500 and 50 here with the backend and the Terms.
- **Review screenshots** are in `app-store/iap-review/`: `paywall-640x920.jpg`
  (Monthly selected) and `paywall-yearly-640x920.jpg` (Yearly selected). ASC rejected a
  full-size device screenshot ("The dimensions of one or more screenshots are
  wrong"), so these are scaled to 640 × 920 and letterboxed in the paper colour
  `#F4F1E8`. Replace both if the paywall changes.

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
| 06 | Save your version. Log it again. | Corrected saved-meal reuse |

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

**Demonstrate the correction.** Earlier TestFlight feedback supports the value of
explicit assumptions. The launch demonstration should show an actual edit and its
effect, then reuse the saved version. Competitors also expose sources or editable
ingredients; do not claim that assumptions or explanations are exclusive to Circa.

---

## What this copy promises that the build doesn't yet deliver

**Verify every promise before the listing goes live.** Steps 0–5 are complete;
the remaining food and saved-meal promises depend on Step 6, with visuals in Step 7.

| Copy | Gap |
|---|---|
| "It shows you what it assumed" | True, but buried one tap deep in `LogEntryDetailSheet` — needs to be on the timeline card |
| One meal with an editable breakdown | Steps 5–6 retain one meal, expose structured quantities/nutrition and reconcile the totals |
| Correct an amount and see the difference | Steps 5–6 preserve unaffected items and show the resulting change |
| Save the corrected version | Step 6 preserves breakdown, assumptions and provenance through save/re-log/relaunch |
| "Set a goal weight and see a steady path to it" | Steps 4c–4f complete; verify final visuals and wording before capture |
| Targets change only when the user acts | Step 4 complete |
| "Your weigh-ins against your plan" and Shot 05 | Step 4e complete; capture the actual plan screen |
| Shot 06 and saved-meal reuse | Step 6 must preserve the corrected version through re-log and relaunch |

Do not advertise verified accuracy or an overall health grade.

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

### Cross-localization — English (U.K.) at launch, Arabic later

Decided 12 October. Apple's storefront table (App Store Connect Help, *App Store
localizations*) sets each storefront's default language and the others it reads:

| Storefront | Default | Also reads |
|---|---|---|
| United States | English (U.S.) | Arabic, Chinese (Simplified), Chinese (Traditional), French, Korean, Portuguese (Brazil), Russian, Spanish (Mexico), Vietnamese |
| United Kingdom | English (U.K.) | — |
| Pakistan | English (U.K.) | Urdu |
| India | English (U.K.) | Hindi, Urdu and nine other Indian languages |
| UAE, Saudi Arabia | English (U.K.) | Arabic |

- **English (U.K.) ships with this version.** One English localisation reaches
  Pakistan, India, British desis and Gulf expats, and needs no translator. Its
  keywords are above.
- **Arabic follows in a later update.** It still pays twice — read by the US and
  Gulf storefronts — but its copy needs a native speaker (`design.md`, Open 1),
  and the app is English-only, so an Arabic listing must say so.
- **The US ceiling is unchanged.** Each of its ten locales adds title 30 +
  subtitle 30 + keywords 100 = 160 indexable characters, up to ~1,440 in all.
  Fill them one at a time and properly: Apple has begun rejecting listings that
  paste identical or machine-dumped metadata across languages.
- **Urdu and Hindi** metadata became available in March 2026 and are read in
  Pakistan and India. They stay outside this launch (`project-brief.md`).

**Timing:** keyword rankings take roughly four weeks to settle after a change.
Ship the new listing and you will not know whether it worked for a month — plan
the creator push around that, not against it.

---

## Cuisine reach

The name and subtitle are deliberately cuisine-agnostic — `Circa: Food & Calorie
Journal` covers kunna, jollof, adobo and tagine equally, because it names no
cuisine at all. Only the English (U.K.) keywords and the screenshots are
desi-specific, and both are cheap to change. **As of 8 September this is finally true**; the deck previously
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
