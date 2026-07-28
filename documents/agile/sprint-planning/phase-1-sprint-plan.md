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
  earlier would mean designing a schema against a model still in motion. The
  schema itself landed first, as **P1-8a**, because it can be executed and
  tested without anything hosted; the repositories move in **P1-8b**.
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
**P1-8b**, where the media pipeline already lives.

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

**Delivered**, except the before/after proof, which is deferred to **P1-8b**:
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

### P1-5 — Ratings and profiles ✅
Mutual rating, worker rating public and hirer rating internal. Aggregate fare
average and completed count on the worker profile.

**Done when** a hirer's rating is never shown publicly and a worker's record
is visible where it can change what they are offered.

**Delivered.** The rules are pure functions over plain data, like visibility,
bidding and the lifecycle before them: what a worker's public number is
decides what future hirers offer them, so it is checkable without a widget.
The worker's record sits under every offer in the hirer's list — the one place
in the app where it can change an outcome — and on the worker's own profile,
because a number that governs your income should not be something you have to
go looking for.

Decisions Section 10 left open:

- **A cancelled job cannot be rated.** Nobody did any work, and a one-star for
  a job that never happened is a weapon rather than a signal. Cancelling
  already has its own consequence in the wallet.
- **An unrated worker shows no stars, not a zero.** New is not bad, and a zero
  out of five says the opposite of the truth about somebody who has not
  started yet.
- **The fare average comes from the jobs, not from the ratings.** A worker who
  was never rated has still been paid, and a hirer deciding what to offer
  should see that. Jobs with no agreed fare are left out rather than counted
  as zero.
- **No public free text.** The note is collected for the admin panel in P1-7
  and never shown beside the average. A marketplace where a stranger's
  paragraph follows a labourer around is one where a single bad day costs
  somebody their livelihood.

The hirer's ratings are reachable only through `internalHirerRatings`, named
so that P1-7 has to ask for them by name. A general "ratings for this user"
accessor would have made leaking them a one-word mistake.

### P1-5a — Demo accounts ✅
Not in the original plan. Added because every rule Phase 1 has added is a rule
about **two** people — who may bid, who may edit, who is charged commission,
who may rate whom — and a device that could only ever be one of them left half
the behaviour unreachable. Ratings in particular could be written but never
seen from both ends.

**Done when** one device can post a job as one person, offer on it as another,
accept, finish and rate in both directions.

**Delivered.** Six accounts: the one the app started on, plus five people from
the seed, one per city and each with jobs already posted. Switching changes
ownership, whose bids are yours, whose wallet is charged, and which trades
filter the feed.

Decisions:

- **Ownership moved from `isLocal` to `postedBy`.** "Posted on this device"
  and "posted by me" were the same thing until now. Jobs written before the
  switcher existed fall back to the device account rather than becoming
  unowned — otherwise an update would orphan everything a user had posted, and
  leave them able to bid on their own work.
- **Role, trades, saved jobs and the wallet are per account; bids and ratings
  are not.** A bid records its worker and a rating records its job and side,
  so those two lists stay shared — which is exactly what lets one person's
  offer appear in another person's list.
- **The device account keeps the unsuffixed storage keys**, so anything
  already in somebody's browser is still theirs after the update.
- **The five personas duplicate their names from the seed** so the switcher
  can be drawn before the seed loads. A test fails if the copies drift, and
  another fails if a persona has no jobs — landing on an empty "my postings"
  list reads as a failed switch.

These are **not** accounts: no password, no verification, no privacy between
them, and everything shares one browser's storage. P1-8b replaces the idea
entirely.

### P1-5b — A demo with a past ✅
Also not in the original plan. The seed produced jobs that had only just been
posted: no offers to choose between, nobody with a record, and every wallet
empty. Half of what P1-2 to P1-5 built was therefore invisible from a fresh
install, and the five demo accounts were five identical blank slates.

**Done when** every screen Phase 1 added can be reached from a fresh install
without editing storage by hand.

**Delivered.** The generator gained a second phase, on its own random seed, so
regenerating the history leaves every job where it was and posted by the same
person. It emits offers, winners and passed-over offers, ratings on finished
work, and a role, trades and wallet per demo account. Jobs now arrive in every
state the lifecycle has.

Decisions:

- **The five accounts are deliberately unalike.** A hirer with postings in
  three states; a busy worker paid up and well rated; a worker locked out by
  debt; a nearly-new worker whose first-job credit is still in the ledger; a
  generalist. Five similar accounts would demonstrate nothing that one does
  not.
- **A persona only ever holds offers on work Section 8 would have shown
  them.** An electrician with an offer on a bricklaying job contradicts the
  rule the whole feed rests on, and it is the detail somebody looking closely
  at the demo notices first.
- **No loyalty bonus is seeded.** It triggers at Rs. 100,000 of lifetime
  top-up, which at 5% implies about Rs. 2,000,000 of completed work. The seed
  does not have those volumes, and a ledger faked to reach it would be visibly
  incoherent on the wallet screen, which shows every entry. The rule stays
  covered by tests.
- **The device account is left empty.** It is what a first-time user sees, and
  the only clean slate in the set.

An **Offers** tab was added to Activity in the same pass. A worker's own list
is mostly the jobs they did not get, and a passed-over offer had nowhere to be
seen.

**Found by building it.** Seeding used to happen inside `JobController.load()`.
That was safe while the only seeded keys were the ones that controller read
back itself, and unsafe the moment the seed grew offers, ratings and wallets:
four other controllers read their keys as they are constructed and raced the
write. It surfaced in a screenshot — a worker with seventeen offers behind him
whose Offers tab said zero — not in the test suite, which passed throughout.
Seeding moved to `bootstrap()`, ahead of the first frame, and the tests that
pump the whole app now go through the same function.

### P1-6 — Mode B: directory and premium ✅
Premium subscription, service menus at fixed prices, worker-set service radius,
credentials showcase, direct booking, and the 2.5% hirer discount.

**Done when** a hirer can find somebody by what they do, book them at a fixed
price, and that booking reaches nobody else.

**Delivered.** A destination of its own rather than a filter on the map: the
map answers *where is there work* and the directory answers *who can do this
and what do they charge*, and folding one into the other would make both
worse. Ten seeded listings across nine kinds of work give it something to show
from a fresh install.

**The one real contradiction in Section 9, resolved.** The spec says the
platform "keeps 2.5% and passes the other 2.5% back to the hirer", that "the
worker's cost is unaffected", and that workers "still pay the standard 5%
commission regardless of mode". Those three cannot all hold. On a Rs. 3,000
service:

| | Hirer pays | Worker charged | Worker nets |
| --- | --- | --- | --- |
| Mode A | 3,000 | 150 | **2,850** |
| Mode B at 5% | 2,925 | 150 | 2,775 |
| Mode B at 2.5% | 2,925 | 75 | **2,850** |

Only the third leaves the worker unaffected *and* has the platform splitting
its own take — which is what the leakage argument requires, since a worker who
funds the discount will simply raise their listed price and the discount stops
existing. **So a Mode B commission is half the usual rate.** It is one constant
in `PremiumRules` if the literal reading is ever preferred.

Other decisions the spec left open:

- **A declined booking is cancelled, not reopened.** The hirer chose one
  person; putting it back on the map would broadcast the thing they asked not
  to broadcast. They can book somebody else, and that is a new booking.
- **Declining costs nothing.** Nothing was agreed and nobody was left waiting
  on the day, so the cancellation penalty does not apply. Charging for it
  would make availability something a worker has to pay to have.
- **A booking never expires.** Seven days of nobody bidding means a job nobody
  wants; seven days of an unanswered booking means one person has not opened
  the app, and cancelling it for them would be the platform making their
  excuses.
- **A listing with no services is hidden**, even while paid for. A name with
  nothing to book is a dead end for the hirer and a bad first impression for
  the worker; the "add a service" notice says so on their own screen.
- **The directory is ordered by nothing the platform can sell.** Cheapest
  first would push people into undercutting each other and "featured" would
  make the order a second thing to pay for. Section 9 already charges for
  being on the shelf; charging twice is how a directory becomes a racket.
- **Prices are Rs. 1,000 a month or Rs. 10,000 a year.** The spec names none.
  A month is roughly one small job, and the year is ten months' money for
  twelve — enough of a discount to be worth committing to, not so much that
  the monthly price looks like a trap.
- **The subscription is not the first thing asked for.** A worker can build
  their menu and set their radius before spending anything. A screen that
  leads with a price asks somebody to buy before they know what they are
  buying, and this audience is being asked for real money on a promise.

**Found by building it.** The bottom bar and the side rail held two
hand-written destination lists. They drifted the moment a fifth destination
arrived — the rail kept showing four, and tapping "Profile" on a desktop
opened Activity. One list now, mapped into both.

### P1-7 — Admin ✅
User approvals, CNIC dispute lookup, wallet overrides, job oversight, audit
logging.

**Done when** no admin action can happen without appearing in the log.

**Delivered.** Four tabs — approvals, disputes, every job with its offers, and
the log. A seventh demo account, *Trust Hire staff*, is the only one that can
reach it; its profile drops the role picker, trades, wallet and directory
listing, because the platform's own account is neither looking for work nor
hiring.

**The definition of done is a design instruction, not a test plan.** Every
mutating method on `AdminController` goes through one private `_perform`,
which records the entry and *then* applies the change, and there is no second
path. So "every admin action is logged" holds the way "the wallet cannot reach
an inconsistent state" holds: not because tests check each case, but because
the code has no way to do otherwise.

The order is deliberate. A failed change leaves a line for something that did
not happen, which a human can investigate; the other order loses the line for
something that did, which nobody can.

Decisions:

- **An override with no reason does not happen at all.** Suspensions and
  wallet adjustments are refused without a note. Section 12's own argument for
  the log is that overrides should not be a black box, and "adjusted balance
  by -4,000" with nothing beside it is that box. A word is enough — the check
  stops an empty field, not bad writing.
- **A CNIC opens on an open dispute naming that person, or not at all.** The
  rule lives in `AdminRules.mayOpenCnic` rather than in a screen, because a
  screen can be rebuilt without it. A dispute about somebody else does not
  open it; a settled one closes it again. **A refusal writes nothing** — a
  logged refusal would read as somebody having seen a document they did not.
- **CNIC numbers are stored masked.** Enough to match a document against a
  claim, and no more; Section 13 rules out looking one up in any case.
- **A SIM-name mismatch is a flag, never a rejection**, and the caveat sits
  next to it on the card. Section 2 expects false positives — a worker on a
  family member's SIM is the ordinary case, and a flag that read as guilt
  would get people rejected for lending their brother a phone.
- **Job oversight is read-only.** An admin who could edit a job could change
  an agreed fare after the fact, and that number is the one the commission
  depends on.
- **An unlock clears exactly what is owed, computed rather than typed.** An
  admin unlocking somebody means "let them work", and making them work out the
  figure first is a way to get it wrong.
- **Overrides land in the worker's own ledger.** The wallet has no balance
  field to overwrite, so a correction sits in their history next to the
  charges it is putting right — where they can see it.
- **The audit log is not seeded.** It records what staff did, and inventing
  entries for actions nobody took would be the one place in the demo where the
  data is a lie about a person rather than a plausible example of one.

### P1-8a — The schema — done

Four migrations under `code/backend/migrations/`, and a test file that tries to
break every rule in them.

**Split out of P1-8 deliberately.** The rest of that sprint — pointing the
repositories at Supabase, sync, media retention — cannot be demonstrated from a
static Pages deploy and would break "the POC stays demonstrable throughout" for
however long it took. The schema does not: it is the part of a backend that can
be settled, executed and checked with nothing hosted anywhere, and settling it
first is what the sprint order was for. The app still runs entirely on-device
and is untouched by this sprint.

**The schema is where the rules live, not a place to put the same rows.** Nine
of the app's load-bearing rules are re-stated as constraints, triggers and a
view, because a rule enforced in Dart is a rule for as long as the only client
is this Flutter app. The fare lock, one winning bid per job, the append-only
ledger, the once-per-job commission, the CNIC door and the reason on an
override each decide either what money moves or who reads somebody's identity
document — and each is now refused by the database for every client there will
ever be.

Decisions:

- **`auth.users` is the account; `profiles.id` is that id and nothing else.**
  No second password or session table. Section 13a excludes authentication, and
  running an identity store beside a managed one is how the two end up
  disagreeing about who somebody is.
- **The tag vocabulary is a lookup table, not a Postgres enum.** The list is
  closed today, but adding to it is a product decision, and an enum makes that
  a migration holding an exclusive lock.
- **`worker_standing` is what a public screen reads.** It cannot leak a hirer's
  rating because it never selects one — Section 10's asymmetry as a property of
  the query rather than a rule every screen has to remember.
- **No balance column anywhere.** Balance, debt and the lockout are replays of
  `wallet_entries`. There is no second number to drift, which is the same
  argument the app's wallet already makes, kept rather than re-litigated.
- **A migration nobody ran is a guess.** `tool/verify_schema.sh` builds a
  throwaway database, applies the migrations and runs the tests; it was run
  against PostgreSQL 16 and everything below is a thing it actually observed.
- **And a test nobody tried to break is a guess too.** `tool/sweep_schema.sh`
  drops each of the 50 rules in turn and re-runs the suite; a rule whose
  removal goes unnoticed is reported and fails the sweep. It found two checks
  passing for the wrong reason — the star-range check was being refused by the
  once-per-side rule before the range was consulted, and the tag-count check
  was deferred past the assertion entirely — neither of which showed up as a
  failing test. **This is the transferable one.** A green suite says the rules
  it names were not violated; it does not say those rules exist.
- **One rule cannot be provoked, and says so.** `bids_one_accepted_per_job` is
  unreachable behind a stricter trigger, so the suite asserts the index still
  exists and the sweep carries the reason in an allow-list. The alternative —
  leaving it silently uncovered — is the gap the sweep was written to close.

### P1-8b — The repositories, sync and media
Pointing the repositories at Supabase, sync, and the media pipeline:
compression and retention (Section 3), and voice-note transcripts (see *A third
decision* above). Needs somewhere hosted to point at, which is what defers it.

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
