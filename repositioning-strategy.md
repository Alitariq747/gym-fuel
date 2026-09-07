# Repositioning LiftEats — Strategy

The *argument*. What we're building and in what order lives in
`project-brief.md`; the exact store metadata lives in `store-copy.md`. This file
deliberately does not duplicate the plan, so the two can't drift.

Written 5 September 2026. Revised 7 September for the drop-lifting and
scrap-exercise decisions — see Revision notes at the end.

---

## 01 · Diagnosis — from the schema, not the copy

`product-as-built.md` gets there on its own: *"an AI-interpretation meter for a
food journal, with an exercise-shaped calorie rebate bolted onto the same table,
sold by the scan."* That is an accurate description of a calorie tracker. It is
not a description of a cut/bulk tracker, and the reason is structural rather than
cosmetic. Three findings do all the damage.

**F1 — We cannot answer the only question a body-composition goal asks.**
Is the weight moving, in the right direction, at the right rate?
`UserProfile.weightKg` is a single optional Double and `EditWeightSheet`
overwrites it. No weigh-in collection, no timestamp, no history, no trend. The app
is blind to the outcome of the phase it is nominally managing.
`GymFuel/Models/UserProfile.swift:52`

**F2 — Targets are static, and statically wrong at the edges.**
`MacroTargetCalculator` runs Mifflin–St Jeor, multiplies by a three-step activity
constant, and adds a flat offset: `+250` lean bulk, `−300` cut. It reads no log
entry and no weight history, ever. That flat offset is ~0.23 kg/week for a 60 kg
user and ~0.11 kg/week for a 110 kg user — the same number producing two different
outcomes. **This is precisely the MyFitnessPal behaviour people leave MyFitnessPal
over.** `GymFuel/Services/MacroTargetCalculator.swift:20, :56-65`

**F3 — We sell the one input whose price is collapsing.**
The entitlement is `ai_scans`; the quota doc counts `totalAiScansUsed` against
`quotaLimit: 500`. We monetise OpenAI calls. Cal AI sells the same thing at
**$2.49/mo**, has 15M+ downloads, and is now owned by MyFitnessPal. Meanwhile the
vision path runs on `gpt-5.4` — not the mini — so every heavy user is a margin
event rather than a margin.
`gymfuel-ai-service/quotaHelpers.js:9`, `src/ai/imageRecognizer.js:27`

Everything else in the audit is downstream of these three.

---

## 02 · The market, with numbers

The category splits cleanly. One half is a **volume game** — cheap, fast, casual
weight loss, won by distribution spend. The other is a **margin game** — expensive,
analytical, goal-driven, won by an algorithm and credibility.

| App | Price/mo | Scale signal | What it actually sells | Game |
|---|---|---|---|---|
| Cal AI | $2.49 | ~$50M ARR at exit | Photo → calories, instantly | Volume · 150+ creators on retainer, then paid, then affiliates |
| MyFitnessPal | ~$9–20 | Acquired Cal AI, 2026 | The food database + brand default | Volume · incumbency |
| MacroFactor | $11.99 / **$6.00 effective** | 400k users · ~$2M/mo | Adaptive expenditure algorithm | Margin · word of mouth off a research audience |
| Carbon Diet Coach | $9.99 | Layne Norton, PhD | Weekly weigh-in → target adjustment | Margin · practitioner credibility |
| RP Diet Coach | to $99.99/yr | ~$200k/mo · 20k dl/mo | Periodised diet templates | Margin · coaching brand |
| Hevy | $2.99 | ~$800k MRR, no ads | The fastest gym log, free forever | Volume · free tier as funnel |
| **LiftEats** | **$5.99** | **Too few ratings to show** | **500 AI scans/month** | **Volume pricing, margin cost base, no distribution** |

Revenue figures are third-party estimates (Sensor Tower / Latka / founder
statements), not audited. MacroFactor user counts are self-reported.

Our position is the worst square on that board: volume-game pricing, margin-game
inference costs, neither a creator budget nor a research brand.

### MacroFactor's growth, for calibration

| | Users |
|---|---|
| Sep 2022 | 35,000 |
| Sep 2023 | 90,000 |
| Sep 2024 | 185,000 |
| Sep 2025 | 400,000+ |

Four years, no paid acquisition, no free tier ($71.99/yr = $6.00/mo effective). Growth more than
doubled in year four — the compounding shape of a niche that talks about itself.
This is the realistic curve for a defensible mechanic with no ad budget, and it is
slow for three years before it isn't.

---

## 03 · The choice — positioning is not the same as mechanic

**A correction to the first version of this document.** It flagged the lifter
niche's *size* as a ceiling. That framing was wrong: MacroFactor does roughly $2M
a month inside that "small" niche. The real objection to positioning on cut/bulk
is **competition** — MacroFactor, Carbon and RP are entrenched, credentialed and
sitting exactly on that phrase. We would be the fourth adaptive-TDEE app without
the PhD or the research audience.

### Nobody out-featured MyFitnessPal. They out-localised it.

Every non-US winner in calorie tracking won on **food localisation**:

| App | Wedge | Scale | How the moat was built |
|---|---|---|---|
| Fitia | Spanish / LatAm | 10M users · YC '21 | ~2M foods, each nutritionist-reviewed, filterable by country |
| HealthifyMe | India | 40M users · ₹229 Cr FY24 | 12 years of crowd contributions, 100k+ regional dishes |
| Yazio | Germany / EU | 50M users · ~$2.8M/mo EU | 2.5M foods incl. European supermarket brands |
| Calorify | Pakistan | New, small | ~190 hand-verified desi home foods + local chain menus |
| Loqma | South Asia | New, small | Hand-verified desi dishes in household portions |

Fitia's own Sensor Tower claim is that it outranks MyFitnessPal, Lose It,
Cronometer *and* MacroFactor on downloads and grossing across Spain and its core
LatAm markets — without beating any of them on features.

### The asset the first draft under-read

**Every one of those moats is a database.** Fitia needed nutritionists and YC
money. HealthifyMe needed twelve years and forty million contributors. Calorify
and Loqma are hand-curating a few hundred dishes each, which is why they are
still small.

Our schema has **no `foods` collection, no barcode, no serving registry, no USDA
identifier**. The first draft filed that as a limitation. In the localisation play
it is the advantage: the app never looks food up, it reasons about a sentence.
Reaching "understands home-cooked desi food" is a prompt and a reference set for
us, and a decade of curation for them.

**The unowned position is not a cuisine. It is the property underneath it: we
don't need to know what the food is called.**

What turns that from a guess into a product is also already in the schema. Every
entry carries `confidence`, `assumptions[]` and `estimatedItems` with
per-component amounts. No competitor surfaces its reasoning. An app that says
*"I assumed two tablespoons of ghee and a 30 cm roti — change it if I'm wrong"* is
having a conversation; every other app hands you a number and dares you to trust
it.

### Two candidate positions

| | A · Cut/bulk coach | B · The tracker for food databases can't handle |
|---|---|---|
| Mouth width | Narrow — lifters running structured phases | Wide — anyone eating home-cooked or non-Western food |
| Who owns it | MacroFactor, Carbon, RP — entrenched | Fitia/HealthifyMe by region; desi contested by three small apps |
| Our edge | Marginal — see correction below | Go-to-market: nobody targets diaspora, and no desi app has adaptive targets |
| Cost to reach | Build the engine first; nothing to say until it ships | Mostly prompt work, a reference set, listing copy |
| Content hook | Weak — an algorithm is hard to film | Strong — "watch MyFitnessPal try to log my mum's biryani" |
| Unit economics | Good — US/UK/EU pricing | Risky in-region; the money is diaspora |

### Two corrections to this document, 7 September

**MacroFactor has AI photo logging, and has since 2025.** Their 2025 annual report
lists it; by 2026 they ship Snap and Describe modes, photo + text, multi-photo,
Plate Stack AI and a multi-language label scanner (upgraded May 2026). An earlier
draft of this file claimed the opposite, sourced from an SEO article summarising
Reddit while their own primary source said otherwise. They are **ahead** of us on
AI logging, not behind.

**Their effective price is $6.00/mo, not $11.99.** The $71.99 annual is what
almost everyone pays. Our proposed $54.99/yr is $4.58/mo — about 24% cheaper, not
60%. "Cheaper, and we have photo logging they don't" was wrong in both halves.

### The frame this document was using was wrong

It reasoned about **moats** — what can't be copied. In a market where an AI-coded
competitor ships a matching feature in a week, that lens produces false comfort
and false alarm in equal measure. Four desi apps already advertise "no database,
just describe your food"; a fifth could tomorrow. Defensibility is not available
at this size, and chasing it is a way of not shipping.

**The operative question is not "what do we own" but "what can we distribute".**
Positioning is chosen for whether it makes content, search and creator outreach
work — not for whether a competitor could copy the claim.

Under that frame the competitive picture reads differently:

- **calog.cc** is web-first. Not in App Store search, not in the listicles, no
  iOS push, no home-screen presence. Same pitch, different surface. Not a
  competitor for the channel we're fighting on.
- **Calorify** is the real benchmark, and the lesson is *distribution*, not
  product: on the App Store, growing dish coverage, free-forever home logging.
  Free-tier pressure is real and comes from here, not from the pitch overlap.
- **MacroFactor** is stronger than this document said, but has no desi food and
  is not going to acquire one.

### Resolution

**Position on B. Retain on A. Then take lifting off the surface entirely.**

Lead with the food problem, because that is what people can hear about, film and
search for. Keep adaptive targets as the depth, because goal-driven users are the
ones who pay and a weekly check-in is what makes month three happen.

The second half of that was settled later, on 7 September: **"lifters" is a
subculture, "goal-driven" is a use case**, and only the second is load-bearing.
Goal-driven also covers recomp, post-partum, a wedding in April, a doctor's
instruction — same engine, same maths, several times the audience. So lifting
comes out of the name, the subtitle and the primary copy, while the adaptive
engine, the phases and the goal-fit score all stay. `GoalType` display strings
become **Gain / Lose fat / Maintain**.

What that costs: roughly 20–30% of ARPU, since a general tracker anchors against
Cal AI's $2.49 rather than MacroFactor's $6.00 effective. What it buys: an order of
magnitude more creators who can plausibly make the video. **Reach is the binding
constraint, not ARPU** — the listing currently shows "insufficient ratings to
display" — and trading price for audience is correct while that holds.

### Why the retention half is worth building regardless

Adaptive expenditure measures real TDEE from the interaction between logged intake
and trend weight, then moves next week's targets to hit a chosen rate. It is what
MacroFactor, Carbon and RP all sell, and it is pure arithmetic — unlike scans, it
costs nothing per user.

A 16-week cut for an 85 kg user, illustrative:

| Week | Static target (today) | Adaptive target |
|---|---|---|
| 0–4 | 2200 | 2200 |
| 4–8 | 2200 | 2120 |
| 8–12 | 2200 | 2040 |
| 12–16 | 2200 | 1960 |

The static column is what the app does now: the same target in week 16 as week 1,
so when expenditure falls the loss stalls and the user concludes the app is wrong.
Each step in the adaptive column is one weekly check-in.

---

## 04 · Distribution

Position B is chosen partly *because* of this section. An adaptive algorithm is
nearly impossible to film; a database failing at your dinner is a fifteen-second
video that makes itself.

**Start here: there is no viral surface at all.** No sharing, no export, no invite,
no referral. Meanwhile every log entry already produces a scored, explained,
image-backed card that is exactly the shape of an Instagram story. A share card is
the cheapest growth mechanic available and it does not exist. Build it before
contacting a single creator, because every channel below leaks without it.

| Channel | Cash cost | Needs from the product | Honest read |
|---|---|---|---|
| Share cards | $0 | Entry card render, one tap to Stories | Compounding, permanent, entirely in our control |
| Nano seeding | ~$0–500 | Lifetime codes; a 15-sec demo that lands | 83% of creators accept gifting alone if they like it. 20–50 nano creators (1k–10k) is the opening move |
| Own account | $0 | Nothing — the failure demos exist today | Slow, but it's how we learn which hook converts before paying anyone |
| Long-tail ASO | $0 | Subtitle + keyword rewrite | Cuisine and homemade terms near-uncontested; indies under-invest here |
| Comparison-site listings | $0 | A listing worth writing up | The "best tracker for X" results are content farms run by rival apps; many accept outreach |
| Micro creators | $100–1,000/post | Proven creative from the tiers above | Only after a nano post has converted |
| **Paid ads** | **$$$$** | **A funnel proven at every step** | **Don't.** The stage Cal AI reached *after* creators got them to ~$2M/mo. The amplifier, never the engine |

Creator rates are 2026 medians: nano (<10k followers) ~$100–250 per deliverable,
micro $100–1,000. The sequence matters more than any single channel — each engine
only starts once the previous has proven the funnel converts.

---

## 05 · Money

Median Health & Fitness monthly pricing is **$9.70**; we are at $5.99 while
carrying a 500-scan inference bill on a full vision model.

| Plan | List | Net after Apple 15% | Per month | Break-even at 500 scans |
|---|---|---|---|---|
| Pro Monthly | $5.99 | $5.09 | $5.09 | $0.0102 / scan |
| **Pro Yearly** | **$49.99** | **$42.49** | **$3.54** | **$0.0071 / scan** |

Excludes Firestore, Storage and Cloud Run. Apple's 15% assumes Small Business
Program enrolment; 30% if not, which roughly halves the headroom again. An annual
subscriber who uses their quota is near break-even before infrastructure — our
best customers are our least profitable, which is backwards.

**Three changes:**

1. **Trial to 14 days.** Not a benchmark call — an adaptive coach cannot
   demonstrate itself in 3 days, because the value arrives at the first check-in.
   The trial must span at least one, ideally two. (Benchmarks agree: sub-4-day
   trials convert at ~25.5% median against ~42.5% for 17–32 day trials.)
2. **Reprice to $7.99/mo and $54.99/yr** once the engine ships. Lower than the
   $9.99 originally proposed here, because dropping the lifting surface means
   anchoring against Cal AI and Yazio rather than MacroFactor. Grandfather
   existing subscribers.
3. **Rename the entitlement.** `ai_scans` is a cost centre wearing a product's
   name. Keep the scan quota as an internal abuse limit, not a headline feature.

**What $10k MRR requires.** At $7.99/$54.99 with the category-typical 68% of
revenue from annual plans, blended net lands near **$4.80 per subscriber per
month**. So ~2,000 active subscribers; at ~9% install→paid under a hard paywall,
~30k downloads cumulative, and ~1,400/month sustained to hold against ~8% monthly
churn. Order-of-magnitude, not a forecast — the point of writing them down is that
they name the actual constraint, and it isn't the code.

---

## 06 · Honest risks

**Distribution is the binding constraint.** Cal AI won on 150+ creators on
retainer, then paid ads on proven creative, then affiliates. MacroFactor won on
four years of word of mouth from a pre-existing research audience. We have neither
a budget nor an audience. §04 gives channels that cost only time, and that is the
honest ceiling on speed.

**Cuisine-first can worsen unit economics.** Inference cost is dollar-denominated;
App Store revenue in Pakistan and India is not, and converts at a fraction of US
rates. Calorify charges ~100 PKR/month (~$0.36) — that cannot fund a `gpt-5.4`
vision call at any volume. **The money in this play is the diaspora**, not the home
market: US, UK, Canada and Gulf accounts, where someone pays Western prices to log
the food they grew up eating. Fitia followed exactly this shape — LatAm for scale,
Spain and the US for revenue.

**The desi niche is not empty, just weakly held.** Calorify, Loqma, Khana AI and
NutriScan are already there. That validates demand and costs us the first-mover
story. It does not cost us the position: three of the four are hand-curating small
databases, the capped approach we specifically avoid. HealthifyMe *is* a moat —
one more reason to aim diaspora rather than India.

**Adaptive targets need adherent users.** The expenditure estimate is only as good
as the intake log feeding it. Systematic under-logging — which AI photo estimation
is prone to, by a commonly cited 150–400 kcal on calorie-dense meals — biases
expenditure downward and the app prescribes too little. We need visible confidence
handling and a way to flag "your log and your weight disagree", which the
`confidence` and `assumptions[]` fields are already shaped for.

**Founder-audience fit degrades.** Ahmad is a lifter and writes for lifters
instinctively. Writing for general home cooks is a different muscle, and untested.

**The paywall was re-verified on 7 September** and is sound apart from one thing:
the trial length is a hardcoded string rather than read from StoreKit, which
becomes a rejection risk the moment the offer changes to 14 days. Step 1 of
`build-order.md`.

---

## Revision notes

Three conclusions in the 5 September version were superseded and have been
corrected in place rather than deleted, so the reasoning stays legible:

- **The ceiling argument (§03)** was the wrong objection. Market size was never
  the problem; incumbency is.
- **The moat frame (§03)** was replaced by a distribution-first one on 7 Sep.
- **Position A alone (§03)** became "position B, retain on A, lifting off the
  surface" once it was clear "lifter" is a costume the goal-driven use case wears.
- **Pricing (§05)** came down from $9.99/$69.99 to $7.99/$54.99 as a direct
  consequence of the above.

Also decided after this document was first written, and recorded in
`project-brief.md` rather than here: exercise logging is removed entirely, the
goal-fit score becomes day-aware and therefore client-side and derived, and App
Store metadata cannot segment cuisines by country in English.

---

## Sources

- [LiftEats — App Store listing](https://apps.apple.com/us/app/lifteats/id6778838787)
- [MacroFactor 2025 Annual Report](https://macrofactor.com/annual-report-2025/) — user counts
- [Sensor Tower — MacroFactor](https://app.sensortower.com/overview/1553503471?country=US)
- [Latka — Cal AI revenue](https://getlatka.com/companies/calai.app)
- [Inc. — Cal AI's $40M and the MyFitnessPal sale](https://www.inc.com/ben-sherry/he-built-an-ai-app-in-high-school-made-40m-and-sold-to-myfitnesspal-now-hes-aiming-even-bigger/91307748)
- [Growthcurve — the Cal AI growth playbook](https://growthcurve.co/three-engines-and-an-exit-the-cal-ai-growth-playbook)
- [RevenueCat — State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps)
- [Sensor Tower — RP Diet Coach](https://app.sensortower.com/overview/1330041267?country=US)
- [FeastGood — Carbon Diet Coach review](https://feastgood.com/carbon-diet-coach-review/)
- [Starter Story — Hevy breakdown](https://www.starterstory.com/hevy-breakdown)
- [Jerusalem Post — Fitia outranking MyFitnessPal across LATAM & Spain](https://www.jpost.com/business-and-innovation/article-898750)
- [Sensor Tower — European food & diet tracking, Q2 2024](https://sensortower.com/blog/2024-q2-unified-top-5-food%20and%20diet%20tracking-revenue-europe-63dd2ccfe1714cfff153fad9)
- [HealthifyMe FY24 revenue](https://entrepreneurvilla.com/healthifyme-tushar-vashisht-ai-fitness-app-revenue-fy24/)
- [Why Western databases fail on Indian food](https://mybiteiq.com/blog/best-calorie-tracker-indian-food)
- [Calorify](https://apps.apple.com/gb/app/calorify-desi-calorie-counter/id6791528606) · [Loqma](https://play.google.com/store/apps/details?id=com.zavistudio.loqma) · [Khana AI](https://apps.apple.com/us/app/khana-ai-calorie-tracker/id6745111999)
- [Micro & nano influencer costs, 2026](https://influenceradvisory.com/blog/micro-nano-influencer-marketing-2026/)
- Internal: `product-as-built.md`, `paywall-audit.md`, `GymFuel/`, `gymfuel-ai-service/`
