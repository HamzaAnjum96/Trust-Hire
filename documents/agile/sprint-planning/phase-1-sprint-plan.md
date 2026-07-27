# Phase 1 — Sprint Plan

Version: 0.1

Builds the marketplace specified in
[`../../product/phase-1-system-logic.md`](../../product/phase-1-system-logic.md),
in Flutter, continuing from the POC that Sprints 0–12 delivered.

## The framework decision

The spec names React Native. This build stays on **Flutter**, because:

- Everything in the spec is buildable in Flutter — nothing in Sections 2–13
  depends on the React Native ecosystem.
- The spec's stated reason for React Native is being "cross-platform-ready for
  a later iOS port". Flutter already targets Android, iOS and web, and the POC
  runs on all three today.
- It keeps thirteen sprints and roughly 200 tests, including the brand
  implementation, the Urdu catalogue and the accessibility suite. A rewrite
  discards all of it and re-earns nothing.

The spec's Android-only *target* is unaffected — Flutter builds Android.

## The backend decision

The spec names Supabase/Postgres, and it is right that the data is relational.
This plan builds toward that without standing one up yet:

- Every read and write already goes through a repository, which is what makes
  this possible. The sprints below extend those interfaces to the Phase 1 data
  dictionary and keep the local implementation behind them.
- The backend arrives in **P1-8**, once the domain has settled. Introducing it
  earlier would mean designing a schema against a model still in motion.
- Until then the app runs on one device, which also means the POC stays
  demonstrable throughout rather than being broken for weeks mid-migration.

## Two contradictions this plan resolves

Recorded in [`../../product/poc-vs-phase-1.md`](../../product/poc-vs-phase-1.md);
both are settled here in favour of the Phase 1 spec, with the consequences
made explicit rather than absorbed silently.

**Categories.** The brand guidelines say users never choose a category. Phase 1
makes 1–3 tags mandatory on every job and builds visibility on them. Phase 1
wins, because the tag system is what solves the "everyone bids on everything"
problem, and nothing else in the spec replaces it. Two things keep faith with
the guidelines' intent:

- Only the **hirer** picks tags. Workers never classify anything — they default
  to Misc and opt into their own trade, which is recognition rather than
  taxonomy, exactly as Section 8 argues.
- The picker is icon-led and visual, so choosing does not require reading.

**Location privacy.** The POC promises, in copy on every job and in the
onboarding, that an exact location is never shown. Phase 1 reveals exact
addresses to both parties after acceptance. Phase 1 wins — but **the copy must
change in the same sprint as the behaviour**, in P1-3. Leaving a promise in
place after it stops being true is worse than never having made it.

## A third decision: audio-only jobs

WCAG 1.2.1 asks for a text alternative to prerecorded audio. A job described
only by a voice note has none, and **requiring one is not an option**: the
poster spoke because writing is hard, which is the product's entire premise.
A required summary field would shut out exactly the people Trust Hire exists
for, and the brand guidelines rule out asterisks and gatekeeping fields
anyway.

What the app does instead, from 0.3.1:

- **Says so.** A job whose only description is audio is labelled as such in the
  list and in the details sheet, next to the player. Someone who cannot hear it
  learns that immediately rather than working out that they have missed
  something.
- **Asks, without insisting.** The posting form prompts for a few words once a
  voice note is the only description, naming who it would help. It never blocks
  the save.
- **Leaves the rest readable.** Tags, area and time are text, so a job is never
  entirely opaque even when its description is not.

This is a partial conformance and should be recorded as one. Real transcripts
need speech recognition, which needs a server; they arrive with the backend in
**P1-8**, where the media pipeline already lives.

## Sprints

Ordered so each one leaves the app working, and so the load-bearing logic is
settled before anything is built on top of it.

### P1-1 — Roles, tags and visibility ✅
Worker and hirer roles. The fixed tag list, replacing the POC's optional job
type. Jobs carry 1–3 tags; workers carry a tag list defaulting to Misc with
opt-in specialisation. The feed visibility rule: a job appears only where a job
tag overlaps a worker tag *and* the job is within the geofence.

**Done when** the visibility rule is fully tested, including that a
specialty-only job never reaches a default-Misc worker.

**Delivered.** Two calls worth recording, because neither is in the spec and
both soften a rule that would otherwise be visibly wrong:

- **A hirer sees every job.** The rule filters a worker's feed of leads. A
  hirer's map is where they post; hiding other people's jobs from it would
  tell them nothing useful.
- **A job posted on this device is never hidden from its poster**, whatever
  its tags. Watching your own job vanish the moment you post it reads as a
  failed save.

One consequence to carry forward: a worker on the default tag sees roughly a
quarter of the seeded jobs. That is the rule working, not a defect — but it
means every surface showing a reduced set has to say why and offer the way
out, which is what the map notice and the list's empty state do.

### P1-2 — Bidding (Mode A) ✅
Starting fare on a job. Workers bid; hirers review and select. Fare locks at
acceptance.

**Done when** a hirer can take a job from posted to accepted at an agreed fare.

**Delivered.** Three calls worth recording:

- **Reading order is not a recommendation.** Section 4 forbids auto-selection,
  so offers are listed cheapest-first only because a list needs an order.
  Nothing marks a row as the one to take, and the top row gets no more
  emphasis than any other.
- **A fare ceiling the spec does not ask for.** A Rs. 2,000 job carrying a
  Rs. 200,000 offer is a mistyped zero, and the hirer should not have to catch
  it for the worker. Deliberately loose — ten times the opening ask — so it
  only ever catches typos, never a worker who knows the job is worth more.
- **Revising an offer replaces it.** Two live bids from one worker would let
  them occupy a hirer's list twice, and there is no honest way to show that.

The locked fare is enforced on the model rather than in the UI:
`Job.withAcceptedBid` is the only writer of `agreedFare` and refuses to run
twice, because Section 11's commission is trustworthy only while that number
is the one both sides agreed to.

### P1-3 — Job lifecycle and location reveal ✅
Statuses: open, accepted, in progress, completed, cancelled, expired. Arrival
confirmation by hirer judgment. Mutual location reveal on acceptance — **and
the copy rewritten to match**. Optional before/after proof, private by default.

**Done when** a job runs end to end and no screen claims a privacy guarantee
the app no longer offers.

**Delivered**, except the before/after proof, which is deferred to **P1-8**:
it is media, and the compression and retention rules that govern media are
already scheduled there. Keeping proof photos on-device with no retention
policy would be the one place the app stores a picture of someone's home
indefinitely.

Three calls worth recording:

- **The worker can only walk away.** Section 7 gives arrival and completion to
  the hirer. Letting a worker mark a job complete would let them claim a fare
  the hirer has not agreed was earned, and the hirer is the one who can see
  whether anybody turned up.
- **A cancelled job goes back to hiding the address**, while a completed one
  does not. They met; hiding it again afterwards would be theatre.
- **The copy is tested, not just changed.** `lifecycle_test.dart` reads the
  string catalogue and fails if anything still promises the exact location is
  never shown — and separately, that the replacement actually says *when* it
  is shared. A privacy promise that quietly stops being true is the failure
  this sprint existed to prevent, so it is guarded rather than remembered.

### P1-4 — Wallet and commission ✅
Token wallet, Rs. 500 first-job credit, 5% commission on completion, loyalty
bonus at each Rs. 100k, one-job debt tolerance then lockout, cancellation
penalty. Simulated top-up.

**Done when** the wallet cannot reach an inconsistent state, tested against
each rule in Section 11.

**Delivered.** The "cannot reach an inconsistent state" requirement was read
as a design instruction rather than a testing one: **the ledger is the only
stored state**, and balance, lifetime top-up, debt and the lock are all
derived by replaying it. There is no balance field to disagree with the
entries that produced it, so there is no repair routine to write and no
reconciliation bug to have.

Decisions Section 11 left open:

- **The cancellation penalty is Rs. 200, flat.** The spec says "a small token
  penalty". Flat rather than a percentage because the harm to the hirer is
  much the same whatever the job was worth, and small enough that a worker
  with a real emergency is not pushed into going anyway.
- **Commission rounds down.** At 5% the difference is at most a rupee, and it
  should fall in favour of the person being charged.
- **The first-job credit is capped at the commission owed**, not granted as
  500 tokens. Section 11 ties it to the first job, so an unused remainder is
  not carried forward.
- **"A second job goes unpaid on top of that"** is read literally: a
  commission charged while the wallet is already short is a second unpaid job,
  and locks the account. Clearing the balance clears the count — the debt is
  what is owed now, not a permanent record of having once been short.

The credit is recorded as its own entry rather than netted off the commission,
so a worker's history shows both the full 5% taken and the help given.

### P1-5 — Ratings and profiles
Mutual rating, worker rating public and hirer rating internal. Aggregate fare
average and completed count on the worker profile.

### P1-6 — Mode B: directory and premium
Premium subscription, service menus at fixed prices, worker-set service radius,
credentials showcase, direct booking, and the 2.5% hirer discount.

### P1-7 — Admin
User approvals, CNIC dispute lookup, wallet overrides, job oversight, audit
logging.

### P1-8 — Backend
Supabase schema from the settled domain, migration of the repositories, and
sync. Media compression and retention (Section 3) belongs here — it is a
server-side concern, and so are voice-note transcripts (see *A third decision*
above).

### P1-9 — Verification
CNIC upload and plausibility check, SMS OTP, CNIC-SIM name match. Last, because
it depends on the backend and is the piece most constrained by real-world
integrations.

## Carried over unchanged

The brand implementation, the Urdu catalogue and RTL, the accessibility suite,
the map, clustering, voice and photo capture, and the seed data. None of it is
invalidated by Phase 1; all of it is reused.

## What stays out

Everything Section 13 and 13a exclude: live NADRA lookup, real payment
gateways, facial recognition, real-money top-up, and the fee split. Those are
recorded there with reasons and are not revisited here.
