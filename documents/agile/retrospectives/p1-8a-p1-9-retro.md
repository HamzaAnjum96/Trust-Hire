# Retrospective — P1-8a and P1-9

Covers the schema sprint (0.13.1+17) and verification (0.14.0), the two sprints
after [`phase-1-retro.md`](phase-1-retro.md).

Written the day both landed, which is
[action 1](phase-1-retro.md#actions) from the last retro doing what it was for.
Two sprints rather than one because P1-8a shipped no app change and would have
been three lines on its own.

---

## What these two delivered

| | |
| --- | --- |
| Sprints closed | P1-8a (the schema), P1-9 (verification) |
| Remaining in Phase 1 | P1-8b — repositories, sync, media. Blocked on somewhere to host |
| Tests | 550 Dart, from 513; plus 71 SQL assertions and a 50-rule mutation sweep |
| Versions | 0.13.1+17 (build only, no app change), 0.14.0 |
| Spec sections | 2 in full; the rest restated as database constraints |

---

## What went well

**The sprint split that was not in the plan.** P1-8 was one sprint: schema,
repositories, sync, media. Splitting the schema out was the difference between
a sprint that could be finished and verified here and one that could not — the
schema needs nothing hosted, and the rest needs a Supabase project that does
not exist yet. The plan's own reason for ordering the backend last was "the POC
stays demonstrable throughout", and the split is what keeps that true for as
long as possible instead of trading it away on the first day of P1-8.

**A test suite that was itself tested.** `sweep_schema.sh` drops each of the 50
rules in turn and re-runs the SQL suite; anything whose removal goes unnoticed
fails the sweep. It found two checks that had been green from the moment they
were written — a star-range check that the once-per-side rule refused first,
and a tag-count check whose deferred trigger fired after the assertion had
already reported a pass. **Neither showed up as a failing test, and neither
would ever have.** This is the sharpest version of the phase-1 finding that a
green suite and a working system had drifted apart: a passing suite says the
rules it names were not violated, not that those rules still exist.

The same move carried into P1-9: the "a whole CNIC never reaches storage" test
was checked by breaking the mask and watching it fail, before being trusted.

**Action 3 from the last retro paid off immediately.** "When two structures
must agree, make one derive from the other" was written with the schema in
mind. It applied twice in P1-9 instead:

- The four verification booleans on `AccountReview` became one `Verification`
  the worker's screen and the admin panel both read. Two copies would have
  disagreed the first time somebody re-submitted.
- The CNIC shape check existed in `AdminRules` and was about to be written
  again in `VerificationRules`. It delegates now — and the two had *already*
  disagreed about whether dashes were required.

**Writing down what a check does not establish, as data.** `describeLimits`
returns the caveats a screen must be showing, so they travel with the signal
rather than being layout somebody can delete in a redesign. Section 2 spends
most of its length on what these checks are not, and that is the only form in
which the warning survives contact with a future screen.

---

## What did not

**A seed incoherence sat in the generator until a test went looking.** The
dispute fallback in `build_admin` created a CNIC record and an account review
for the same person in two separate `if` blocks, each generating its own masked
number. The review's and the CNIC file's numbers disagreed for every account
created that way. Nothing surfaced it — the admin panel reads one file, the new
verification screen reads the other, and until P1-9 nothing read both.

This is **action 4 in a new shape**: the previous version was "can somebody
reach this data?"; this one is "do two files describing one thing agree?". The
fix was structural — one `verification_for()` builds the record and both files
are written from it — which is action 3 again.

**Three test failures in P1-9 were the tests being wrong, not the code.** A
digit-run assertion that tripped on microseconds in ISO timestamps; a claim
that the seeded phone numbers were on an unallocated prefix, which was simply
false (Pakistan has no reserved range, and `0300` is Jazz); and widget taps
that silently missed buttons below the fold. Each cost a debugging cycle
against code that was fine.

The middle one is the one worth remembering: **an assertion stating a fact
about the world can be wrong in a way no amount of test-running reveals.** It
passed until the seed changed, and it would have gone on "guaranteeing"
something untrue.

**Screenshot verification was slower than it should have been.** Four rounds
lost to my own harness: serving the build at `/` when it was built with
`--base-href /Trust-Hire/`, then clicking coordinates on a canvas Playwright
cannot query by text. Action 2 says to look at the app before closing a sprint,
and it is right, but the mechanics of doing so need writing down rather than
re-deriving.

---

## Things that turned out to be worth the argument

- **`bids_one_accepted_per_job` has no behavioural test, and says so.** Every
  row it would refuse is refused earlier by a trigger, so the suite asserts the
  index exists and the sweep carries the reason in an allow-list. The
  alternative was leaving a real rule silently uncovered.
- **The build number moved but the version name did not**, for a sprint that
  changed no app code. A minor bump would have promised something to look at.
- **A card the automated check cannot confirm is still stored.** An upload the
  app silently discards is one the worker thinks succeeded.
- **A late correct code is reported as expired, not wrong**, because a screen
  that cannot tell those apart teaches people to distrust the message that is
  actually their fault.
- **A check that could not run gets no verdict.** The device account has no
  name to compare against; reporting a mismatch would fire the fraud flag on
  the one account that has done nothing at all.
- **The simulated SMS says on screen that it is simulated.** The alternative —
  a demo where the phone step silently cannot be completed, or one that implies
  a message was sent — is worse than admitting the seam.

---

## Actions

| # | Action | Owner | Status |
| --- | --- | --- | --- |
| 1 | Run `sweep_schema.sh` whenever the schema changes, and add the reason to `expected_uncovered` rather than leaving a rule silently uncovered. | Claude | Open |
| 2 | Apply the same question to the Dart suite: pick the two or three tests a sprint depends on and check they fail when the thing they guard is removed. Done for the CNIC mask; not done for anything else. | Claude | Open |
| 3 | Write down the screenshot procedure — base-href, the serving path, coordinate clicks — so it is not re-derived each sprint. | Claude | Open |
| 4 | Treat an assertion about the outside world (a phone prefix, a format standard) as a claim needing a source, not a test. | Claude | Open |
| 5 | Get the Urdu catalogue read by a native speaker. **Carried, third time** — now 465 string pairs. | Hamza | Open |

### From the last retro

| # | Action | Status |
| --- | --- | --- |
| 1 | Retro at the end of each sprint | **Done** — this document |
| 2 | Run the app and look at the screens a sprint touched | Done both sprints; see the note above on how slow it was |
| 3 | Make one structure derive from the other | **Done twice in P1-9**, and it caught a live disagreement |
| 4 | Ask whether seed data can be *reached* | Partly — it caught nothing this time, but its sibling question (do two files agree?) found a real defect |
| 5 | Urdu review | Still open, carried above |
| 6 | Set GitHub Pages source to "GitHub Actions" | **Done** — the deploy on `fdcc689` succeeded |

---

## What is left of Phase 1

**P1-8b only**, and it is blocked rather than unscheduled: pointing the
repositories at Supabase needs a Supabase project, credentials, and a decision
about what happens to the demo accounts when real ones exist. Three things wait
behind it, all recorded rather than remembered:

- **Voice-note transcripts** (WCAG 1.2.1, a partial conformance today).
- **Before/after proof photos** (Section 7), which need the retention rules
  that only exist once media has a home off the device.
- **Real SMS delivery** (Section 2, the second partial conformance). The seam
  is `SmsSender`; nothing else about that step changes.

Two partial conformances now wait on the same sprint. That is worth saying
plainly to whoever assesses this: neither is an oversight, both are written
down where the feature is, and both are one implementation of an existing
interface away.
