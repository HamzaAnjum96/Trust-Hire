# Phase 1 retrospective — P1-1 to P1-7

Covers the seven sprints from
[`../sprint-planning/phase-1-sprint-plan.md`](../sprint-planning/phase-1-sprint-plan.md)
delivered between versions 0.4.0 and 0.13.0, plus the two unplanned sprints
that were added along the way (P1-5a, demo accounts; P1-5b, seed history).

Written at the end of P1-7 rather than after each sprint, which is itself the
first finding.

---

## What the phase delivered

| | |
| --- | --- |
| Sprints closed | P1-1 … P1-7, plus P1-5a and P1-5b |
| Remaining | P1-8 backend, P1-9 verification |
| Tests | 513, from ~200 at the start of the phase |
| Versions shipped | 0.4.0 → 0.13.0, every one pushed to `main` |
| Spec sections implemented | 2 (partly), 4, 5, 6, 7, 8, 9, 10, 11, 12 |

---

## What went well

**Rules as pure functions, separate from widgets.** Every sprint added a
`*_rules.dart` — visibility, bidding, lifecycle, wallet, ratings, premium,
admin — holding the part of the spec that decides something, with no Flutter
in it. The payoff was not testability in the abstract; it was that each of
those files became the place the spec's ambiguities got argued out in writing,
next to the code that resolves them. `PremiumRules.hirerDiscountTenthsPercent`
is forty lines of comment and one integer, and that ratio is right.

**Definitions of done read as design instructions.** Three of them turned into
structure rather than test suites:

- "The wallet cannot reach an inconsistent state" → the ledger is the only
  stored state and everything else is derived. There is no balance field to
  disagree with the entries that produced it.
- "Every admin action is logged" → one private `_perform` records the entry
  and then applies the change, and there is no second path.
- "No screen claims a privacy guarantee the app no longer offers" → a test
  that reads the ARB catalogue rather than the widgets.

Each of those replaced a class of bugs with an absence of the code that could
cause them. That is the pattern worth repeating in P1-8.

**Screenshots caught what tests could not.** Five real defects were found by
looking at the running app and by nothing else: the map opening on the whole
country, a 6px overflow stripe on long area names, "Their record" on your own
profile, the staff account offering itself a wallet, and — the worst one — a
worker with seventeen offers whose Offers tab said zero. The suite was green
for all five.

**Recording resolved ambiguities in the sprint plan.** Section 9's discount
contradiction, Section 11's "second job goes unpaid on top of that", Section
10's silence on cancelled jobs. Each is written down with the arithmetic and
the reading chosen. None of them had to be re-derived later, and the Section 9
one is a single constant away from the other reading if the client disagrees.

---

## What did not

**The green suite gave false confidence about integration.** The Offers-tab
bug is the clearest case: four controllers read their storage keys the moment
they are constructed, and seeding happened inside a fifth controller's `load`.
Every unit test passed because each test seeded first and then built one
controller. Nothing exercised the order the *app* uses. The fix was to extract
`bootstrap()` and make the tests that pump the whole app go through it — but
the lesson is that "the tests pass" and "the app works" had drifted apart, and
only a screenshot noticed.

**Two hand-written copies of the same list, twice.** The navigation
destinations existed as a `NavigationDestination` list and a
`NavigationRailDestination` list, and they silently diverged the moment a
fifth destination arrived — on a desktop the rail still showed four, and
tapping "Profile" opened Activity. The status pill existed in three files with
two different paddings. Both were found by reading rather than by failing.

**The seed's blind spot lasted three sprints.** The history generator drew
from jobs posted by *other* people, so the demo accounts' own postings had no
offers on them at all. The hirer's side of Mode A — the screen bidding exists
for — was unreachable from four of the five accounts, and the tests asserted
the seed was coherent without ever asking whether it was *useful*.

**Retrospectives were skipped until the end.** This document covers seven
sprints at once, which means most of its findings are archaeology. Two of the
three problems above would have been caught earlier by a five-minute look back
at the end of each sprint.

**Urdu is still unreviewed.** 417 string pairs, all written by the same
non-native hand that wrote the English. The catalogue is complete and the
guards check for English leaking through, but completeness is not correctness.

---

## Things that turned out to be worth the argument

- **A hirer sees every job**, though the tag rule filters a worker's feed.
- **The offer list is ordered but not ranked** — cheapest first because a list
  needs an order, with nothing marking a row as the one to take.
- **An unrated worker shows no stars rather than a zero.** New is not bad.
- **A cancelled job cannot be rated.** A one-star for work that never happened
  is a weapon, not a signal.
- **The directory is ordered by nothing the platform can sell.** Section 9
  already charges for the shelf; charging twice makes it a racket.
- **A SIM-name mismatch is a flag, never a rejection**, with the caveat next
  to it — because a family member's SIM is the ordinary case.

Each of these is a place where the obvious implementation would have been
worse for the person with the least power in the transaction. Keeping that
question in front of every decision is the thing this project should not lose
in P1-8.

---

## Actions

> **Statuses here are as at the end of P1-7.** They are carried forward, with
> what happened to each, in
> [`p1-8a-p1-9-retro.md`](p1-8a-p1-9-retro.md#from-the-last-retro) — read that
> for the current position rather than this table.

| # | Action | Owner | Status |
| --- | --- | --- | --- |
| 1 | Write the retro at the **end of each sprint**, not at the end of the phase. Ten lines is enough. | Claude | Open |
| 2 | Before closing a sprint, run the app and look at the screens it touched. Every integration bug this phase was found that way. | Claude | Open |
| 3 | When two structures must agree, make one derive from the other. Applied to the nav destinations and the status pill; watch for it in the P1-8 schema, which will duplicate every model. | Claude | Open |
| 4 | Ask of new seed data "can somebody *reach* this?", not only "is it coherent?". The coherence tests passed throughout the three sprints the offers were missing. | Claude | Open |
| 5 | Get the Urdu catalogue read by a native speaker before anything is shown to real users. Carried from Sprint 9 and still open. | Hamza | Open |
| 6 | Set the GitHub Pages source to "GitHub Actions" in repository settings, or the deploy step keeps failing. | Hamza | Open |

---

## Carried into P1-8

Two things were deferred into the backend sprint on purpose, and both should
be planned as part of it rather than remembered late:

- **Voice-note transcripts** (WCAG 1.2.1, currently a partial conformance).
  They need speech recognition, which needs a server.
- **Before/after proof photos** (Section 7). They need the compression and
  retention rules that only exist once media has a home off the device.

P1-8 is also the first sprint that breaks the property every previous sprint
kept: *the POC stays demonstrable throughout*. That is worth deciding
deliberately rather than discovering.
