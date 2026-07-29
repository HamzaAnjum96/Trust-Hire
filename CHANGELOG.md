# Changelog

All notable changes to Trust-Hire are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it reaches a first release.

Group entries under `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, or
`Security`. New work goes under `[Unreleased]`; when a version ships, rename
that heading to the version and date, and open a fresh `[Unreleased]`.

## [Unreleased]

### 0.15.0 — P1-8b, the backend seam and sync

There is no Supabase project and no credentials, so this is the **seam** plus a
stand-in behind it. Swapping in a real client means implementing `RemoteApi`.

#### Added

- **`RemoteApi`**, and `MockBackend` behind it: in-memory, with server-assigned
  timestamps and versions, a latency setting and a switch that makes it
  unreachable.
- **An outbox.** Local writes queue and survive being closed while offline —
  the queue exists because the network is not there, and an app closed while
  offline would otherwise lose exactly the writes it was protecting.
- **`SyncRules`** — the conflict decisions, as pure functions.
- **A Backend panel on the profile**, with the queue, a "pretend there is no
  connection" switch, and any refusals. A seam nobody can see is a claim rather
  than a demonstration.
- **Six mutations** in `sweep_tests.py` for the promises above.

#### The decision the sprint turns on

**The mock refuses what the schema refuses.** A mock that accepts whatever it is
handed is a dictionary with latency: the sync layer would look correct while
being unable to cope with the one thing a server does, which is say no. So the
fare lock, the swapped worker, one accepted bid per job, the append-only ledger
and audit log, the once-per-job commission and the rating rules are all enforced
at the mock — and `rulesEnforcedHere` names the migration each comes from, with
a test that every refusal it can return is on that list.

#### Other calls worth recording

- **A permanent refusal leaves the queue**, and is reported. One that will be
  refused identically forever otherwise sits at the head of an ordered outbox
  and stops everything behind it from ever being sent.
- **The server assigns the time.** A device's clock is somebody's phone, and
  phones are wrong by more than the gap between two edits.
- **The queue is ordered oldest-first and never regrouped by kind**, because
  accepting an offer and locking a job's fare make sense in one sequence only.
- **A refusal travels as a code, not a sentence** — caught by
  `localisation_test.dart`, which refused the first version of this for putting
  English prose on the wire. A server that sends display text decides what
  language the app speaks, and this one speaks two.

#### Changed

- `localisation_test.dart` now exempts `throw` lines for the same reason it
  already exempted `Error(`: an exception message is read in a stack trace,
  never on a screen.

#### Not done, deliberately

Pulling is implemented and tested but not applied back into the repositories.
Deciding what happens when a demo account's seeded history meets a server's copy
of it has nothing to be right about while no server holds a second copy.
`SyncRules.merge` is where it goes. Media, transcripts and real SMS are P1-8c
and all wait on the same thing.

### 0.14.4 — The cast stops moving about

Three seed defects, all found by walking the app for the demo script rather
than by anything failing.

#### Fixed

- **A worker called "Noor Noor", and two people sharing a name.** One of the
  duplicated names was Hina Butt, who is also a demo persona — so the admin
  queue listed two of her and a decision about one was ambiguous. Names are now
  drawn without repeating, and a first name is never also the family name.
- **The five personas were named by the random seed.** Every regeneration
  renamed the demo's cast and silently invalidated the README, the demo script,
  and anything anybody had written down. Their names and areas are pinned in
  the generator now, next to the rest of what each persona is *for*.
  `account_test.dart` already checked the roster and the seed agree; this makes
  them agree by construction rather than by luck.
- **A hirer in Islamabad had postings in Sukkur.** Jobs are handed out
  round-robin, which scatters each person's across the country — invisible for
  the fifty-five names nobody switches to, and wrong for the five in the
  switcher. Switching to a persona now shows a map framed on their own city
  instead of on jobs a thousand kilometres apart.

#### Added

- Tests for all three, in `account_test.dart`: no repeated names, no name
  whose first word is its last, and every persona posting in the city they
  live in.

### 0.14.3 — A demo somebody can follow

#### Added

- **[`documents/product/demo-script.md`](documents/product/demo-script.md)** —
  fifteen minutes, eight stops, which account to be and what to point at. Built
  by walking the release build in a browser rather than by reading the code, so
  it describes what is on screen rather than what ought to be.
- **`test/demo_walkthrough_test.dart`** — an assertion per stop. It does not
  test the rules; every rule has its own file. It tests that the demonstration
  is still *reachable*: the account still has the data, the screen still has
  the control. A script nobody checks rots, and it rots silently — the reader
  finds out in front of an audience.

This is the phase-1 retro's fourth action in its sharpest form. The seed stayed
coherent for three sprints while the hirer's side of Mode A was unreachable
from four of the five accounts, and every coherence test passed throughout.

### 0.14.2 — Two more promises nothing was holding up

The sweep from 0.14.1, widened from 23 promises to 34. Two more survived, and
both were the same shape as the first two: a rule the code enforces, a comment
explaining why it matters, and no test that would notice its removal.

#### Fixed

- **A bystander was one deleted line from being offered somebody else's Mode B
  booking.** `JobLifecycle.actionsFor` answers the direct-booking case *before*
  the role switch, and that branch reads "the hirer, or else the worker" — so
  without the bystander guard above it, anyone looking at a booking between two
  other people would be shown Accept and Decline. The existing bystander test
  loops over every status but only ever with an ordinary job, which is the one
  shape that branch does not cover.
- **An admin correction could have counted as an unpaid job.** `unpaidJobs`
  counts commissions that left the wallet short, and nothing else — a
  cancellation penalty or a staff adjustment is not work somebody took and
  failed to pay for. Dropping the `kind` check pushed a corrected account
  toward a lockout, and no test said so.

#### Added

- Eleven more mutations: the fare ceiling and the positive-fare floor, a
  withdrawn offer leaving the hirer's list, the worker's inability to mark a
  job complete, a finished job taking no further action, the balance being a
  replay of the ledger, the premium lapse, the audio-only label, and saved jobs
  being per account.

### 0.14.1 — Do the tests test anything?

No new functionality. The schema sweep found two SQL checks that had been green
since they were written and could never have failed; this asks the same
question of the 553-test Dart suite.

#### Added

- **`code/frontend/tool/sweep_tests.py`** — breaks each of 23 load-bearing
  promises in turn and reports any the suite does not notice. Aimed rather than
  exhaustive: mutating every operator would take an hour and report mostly
  noise, so each mutation names a promise the product actually makes.
- **Two tests for promises that had none.** Both were found by the sweep, and
  neither would ever have failed:
  - **General work cannot be switched off.** The whole of Section 8 rests on
    it — a worker with no tags has an empty feed forever and no screen would
    explain why — and nothing tested it.
  - **A change that fails still leaves the line saying it was tried.**
    `AdminController._perform` writes the log *then* applies the change, so a
    failure leaves something a human can investigate rather than nothing. Every
    other test of the log was a happy path, where both orders look identical.
    The new one uses a store that refuses one key.

#### What the sweep also settled

`WorkerProfile.withoutTag`'s early return for the default tag is
belt-and-braces: deleting it changes nothing observable, because the
constructor puts the tag back. The mutation is aimed at the constructor now,
which is where the rule actually lives — the same distinction the schema sweep
had to make for `bids_one_accepted_per_job`.

#### Noted, not fixed

`AdminController` updates its in-memory review before attempting the write, so
a failed write leaves the screen and the disk disagreeing until the next load.
Out of scope for a run that added no functionality, and the honest fix trades
it for a UI that does not update until storage confirms. The new test asserts
against storage and says why in a comment beside it.

### 0.14.0 — P1-9, verification

#### Added

- **A verification screen**, from the profile: submit a CNIC, confirm a phone,
  and see the CNIC-SIM name comparison once both exist. Nothing here is a gate
  — a worker who does none of it keeps a working app, and the screen says so
  before it asks for anything.
- **CNIC submission**, with the automated plausibility check Section 2
  describes: thirteen digits in the right shape, a name, and a date of birth
  that belongs to a living adult. Accepted with or without dashes.
- **Phone confirmation by code**, with a five-minute expiry, five attempts, and
  a thirty-second wait before a resend to the same number. The attempt count is
  stored, so closing the app is not a way to get a fresh set of guesses.
- **The CNIC-SIM name check**, as a real comparison: case, spacing, the several
  spellings of Muhammad, honorifics, and a middle name present on one document
  and not the other. A mismatch moves the account up the admin queue and
  changes nothing else.
- **`SmsSender`**, the seam a real provider goes behind.

#### Changed

- **The verification signals are one record now, not four loose booleans.**
  `AccountReview` carries a `Verification` — the same row the worker's own
  screen writes — so the panel cannot end up deciding on a submission that has
  since been replaced. The stored JSON is unchanged, so no seed migration was
  needed.
- **A CNIC number is accepted without its dashes.** The admin panel's shape
  check used to refuse thirteen correct digits over punctuation; both sides now
  delegate to one rule that normalises first. A keypad has no dash, and that
  refusal is how somebody gets stuck on the first screen of verification.
- **The seeded reviews carry phone numbers and real dates**, generated in one
  place with the CNIC beside them. A test now fails if the two files disagree
  — they did, for accounts created by the dispute fallback, which wrote a
  masked number into one file and not the other.

#### What is not real, and says so on screen

Section 2 asks for a real SMS, and is right to: a code that never leaves the
device confirms nothing about the phone. **Delivery is the one part that is
simulated**, because there is no provider to send through until P1-8b. The demo
shows the message it would have sent, under a line saying that is what it is
doing. Everything else — expiry, attempts, the resend wait, the normalisation
that makes four spellings of a number one number — is real. Record this as a
partial conformance, in the same shape as the WCAG 1.2.1 transcript decision.

#### Notes on the design

- **The whole CNIC number never reaches storage.** The mask is the only thing
  that produces a stored number and it returns null for anything it cannot
  parse, so there is no path where a malformed number is kept whole. A test
  asserts that nothing in storage holds a run of five digits once timestamps
  are removed; it was checked by breaking the mask and watching the test fail.
- **A new number drops the tick the old one earned.** A confirmed mark beside a
  number nobody has sent anything to is the one outcome this step must not
  produce.
- **A late correct code is reported as expired, not wrong.** A screen that
  cannot tell those apart teaches people to distrust the message that *is*
  their own fault.
- **A check that did not run gets no verdict.** The device account has no name
  to compare against, and not running is not a mismatch — reporting one would
  fire the fraud flag on the single account that has done nothing at all.

#### Added to the record

- [`documents/agile/retrospectives/p1-8a-p1-9-retro.md`](documents/agile/retrospectives/p1-8a-p1-9-retro.md)
  — written the day both sprints landed, which is the first retro's own top
  action. It carries the six earlier actions forward with what became of each:
  the GitHub Pages setup is done, and "make one structure derive from the
  other" caught a live disagreement about whether a CNIC needs its dashes.

### P1-8a — The schema, and the tests that try to break it

**Version 0.13.1+17 — the build number moves, the name does not.** Nothing
under `code/frontend/` was touched, so the deployed app is byte-identical and
claiming a new `0.14.0` would promise something to look at that is not there.
The build number still increments, because it is what tells a redeploy of the
same app apart from a deploy that failed. This sprint is `code/backend/` going
from an empty folder to the schema the Phase 1 rules will run on; nothing is
hosted, and the POC still runs entirely on-device.

#### Added

- **Four migrations** under `code/backend/migrations/`, for PostgreSQL 16 as
  Supabase runs it. Identity and the tag vocabulary; jobs, their media and the
  fare lock; bids, ratings, the wallet and the directory; disputes and the
  audit log.
- **Nine app rules restated as constraints, triggers and a view.** The agreed
  fare is written once at acceptance and the chosen worker cannot be swapped
  afterwards; one winning bid per job, and it must name the fare the job
  records; the wallet ledger and the audit log refuse `update` and `delete`;
  commission and the cancellation penalty are charged once per job and the
  first-job credit once ever; only a completed job can be rated, once per side;
  a CNIC opens only while a dispute names that person; an override without a
  reason is refused. Each held in the app because one class was the only
  writer — a promise one client keeps. They now hold for every client.
- **`worker_standing`**, the view a public screen reads. It cannot expose a
  hirer's rating because it never selects one, which makes Section 10's
  asymmetry a property of the query rather than a rule each screen remembers.
- **`code/backend/test/schema_test.sql`** — 55 statements the schema must
  refuse, eleven it must allow, and five assertions about what the data then
  says. Run against a throwaway database by `tool/verify_schema.sh`; every
  result quoted here was observed rather than reasoned about.
- **`code/backend/tool/sweep_schema.sh`**, which drops each of the 50 rules in
  turn and re-runs the suite. A rule whose removal goes unnoticed is reported
  and fails the sweep.

#### Fixed

Two tests that had been green since they were written, both found by the sweep
rather than by anything failing:

- **The star-range check was never reaching the star range.** Aimed at a job
  that already had a worker rating, it was refused by the once-per-side rule
  first, and would have gone on passing with `stars between 1 and 5` deleted.
  It now uses a job with no rating on it, and there is a second check for zero.
- **The tag-count check was being deferred past its own assertion.** The rule
  is a deferred constraint trigger, so it fired at commit — after the block
  that was supposed to catch it had already returned and reported a pass. The
  test helpers now force pending constraints immediate before deciding.

`must_fail` also no longer counts *any* error as a refusal: an error the server
raised because it could not parse the statement is re-raised rather than
recorded, so renaming a column cannot quietly turn every check that mentions it
into a pass.

#### Known gap

`bids_one_accepted_per_job` has no behavioural test and cannot have one — every
row it would refuse is refused earlier by the fare-agreement trigger. It stays
because a trigger can be switched off and a unique index cannot, so the suite
asserts the index still exists and the sweep carries the reason in an
allow-list. Recorded rather than left silent, which is the whole point of
having swept.

### 0.13.1 — Fixes, a cull, and a look back

No new functionality. A pass over what the last four sprints left behind.

#### Fixed

- **A map that stayed blank until the first pan or zoom.** The opening camera
  was applied with `fitCamera` from a post-frame callback, so the map laid
  itself out at one position and arrived at its real one a frame later — and a
  tile layer that has already chosen its tiles does not reliably notice. It is
  now handed to flutter_map as `initialCameraFit` and resolved during the
  map's own first layout, so there is no second position to miss.
- **The demo accounts' own postings had no offers on them.** The history
  generator drew from jobs posted by *other* people, so switching to a demo
  account and opening "Posted" showed bare open jobs with nothing to decide —
  the hirer's side of Mode A was unreachable from four of the five accounts.
  Each persona now gets the four states by hand: something to choose between,
  something finished and rated, something under way, and something called off.
- **Wallets are now built from every completion**, not from the one loop that
  happened to create it. A persona who finished another persona's job was
  never charged for it.
- **Restoring the seed left the directory and admin panel stale.** Both are
  seeded now and neither was reloaded.
- **A direct booking never said it was one.** The status panel showed "open"
  and nothing else, leaving both sides waiting for a bidding screen that was
  never going to appear.
- **The service-radius chips could show nothing selected** while a radius was
  set — the default was not among the presets, and no seeded listing was.

#### Changed

- Three near-identical status pills across three files became one
  `StatusPill`. They had already diverged by two pixels of padding, which is
  the shape a brand change goes wrong in.
- Twenty dead strings removed from both catalogues. An unused string is a
  promise the catalogue makes and the app does not keep — and one more line
  for the native reviewer who has not read the Urdu yet.

#### Added to the record

- [`documents/agile/retrospectives/phase-1-retro.md`](documents/agile/retrospectives/phase-1-retro.md)
  — the first retrospective, covering P1-1 to P1-7 with six actions and named
  owners. Its first finding is that it should have been seven documents.

### 0.13.0 — P1-7, the admin panel

#### Added

- **An admin panel**, in four tabs: an approval queue, disputes, every job on
  the platform with its offers, and the audit log.
- **The audit log.** Every admin action — what it was, who it was about, why,
  and when — with wallet adjustments carrying their amount. Nothing in it can
  be edited or removed.
- **Approvals**, showing Section 2's verification signals: a CNIC on file, an
  automated shape check on the number, a confirmed phone, and the SIM-name
  match. Flagged accounts sort to the top of the queue.
- **Wallet overrides.** Adjust a balance by hand, or unlock somebody the debt
  rule has stopped, both of which land as ordinary entries in that worker's
  own ledger.
- **CNIC dispute lookup**, and **disputes** to justify it.
- A seventh demo account, **Trust Hire staff** — the only one with the panel.
  Its profile drops the role picker, trades, wallet and directory listing,
  because the platform's own account is neither looking for work nor hiring.

#### Notes on the design

**Nothing changes without a line in the log.** Every mutating method on
`AdminController` goes through one private `_perform`, which records the entry
and *then* applies the change. There is no second path, so Section 12's
requirement that "manual overrides remain traceable rather than being a black
box" is structural rather than remembered — the same move the wallet's ledger
makes, and for the same reason: a record that depends on somebody choosing to
write it has holes exactly where somebody had a reason not to.

The order is deliberate. If the change fails, the log carries a line for
something that did not happen, which a human can investigate. The other order
loses the line for something that did, which nobody can investigate.

**An override with no reason does not happen at all.** Suspensions and wallet
adjustments are refused without a note — an entry reading "adjusted balance by
-4,000" with nothing beside it is the black box the log exists to prevent. A
word is enough; the check stops an empty field, not bad writing.

**A CNIC opens on an open dispute naming that person, or not at all.** Section
2 says the photo "sits unreviewed unless a dispute is raised later". That is an
access rule about a national identity document, so it lives in
`AdminRules.mayOpenCnic` rather than in a screen that could be rebuilt without
it. A dispute about somebody else does not open it; a settled one closes it
again. A refusal writes nothing — logging one would put a line in the record
saying somebody looked at a document they never saw. Numbers are stored masked;
the app has no use for a full CNIC and Section 13 rules out looking one up.

**A SIM-name mismatch is a flag, never a rejection**, and the panel says so
next to it. Section 2 is explicit that false positives are expected — a worker
on a family member's SIM is the ordinary case.

**Job oversight is read-only.** An admin who could edit a job could change an
agreed fare after the fact, and that number is the one the commission depends
on.

**The audit log is not seeded.** It records what staff did, and inventing
entries for actions nobody took would be the one place in the demo where the
data is a lie about a person rather than a plausible example of one.

### 0.12.0 — P1-6, Mode B: the directory and premium

#### Added

- **A directory**, as a destination of its own. Section 9's second discovery
  mode: the map answers *where is there work*, the directory answers *who can
  do this and what do they charge*. Filter by kind of work, read somebody's
  record and their menu, book a fixed price.
- **Premium listings.** A worker subscribes monthly or yearly (simulated, and
  the screen says so), then builds a service menu at fixed prices, sets how far
  they will travel — or marks themselves remote-only — writes a headline, and
  adds qualifications.
- **Direct booking.** A booking creates a job addressed to one worker and to
  nobody else, at the price already shown. The worker accepts or declines;
  from there it runs the same lifecycle as any other job.
- Ten seeded listings across nine kinds of work — a lawyer, a GP, a tutor, a
  makeup artist, a night guard and others — **one of them deliberately
  lapsed**, so the lapse state is reachable without waiting a month.

#### Changed

- The bottom bar and the side rail now build from **one** destination list.
  They used to hold two hand-written copies, which drifted the moment a fifth
  destination arrived: the rail kept showing four, and tapping "Profile" on a
  desktop opened Activity.

#### Notes on the design

**The 2.5% discount, and a contradiction in the spec.** Section 9 says the
platform "keeps 2.5% and passes the other 2.5% back to the hirer", that "the
worker's cost is unaffected", and that workers "still pay the standard 5%
commission regardless of mode". Those three cannot all be true. On a Rs. 3,000
service:

| | Hirer pays | Worker charged | Worker nets |
| --- | --- | --- | --- |
| Mode A | 3,000 | 150 | **2,850** |
| Mode B at 5% | 2,925 | 150 | 2,775 |
| Mode B at 2.5% | 2,925 | 75 | **2,850** |

Only the third leaves the worker unaffected and has the platform splitting
*its own* take, which is what the leakage argument needs — booking in the app
must be cheaper than booking the same worker outside it, and it cannot be the
worker who funds that or they will simply raise their listed price. So a Mode B
commission is half the usual rate. The reasoning and the arithmetic are in
`PremiumRules.hirerDiscountTenthsPercent`, tested in `premium_test.dart`, and
the literal-5% reading is one constant away if it is ever wanted.

**A direct request is not broadcast.** `JobVisibility` sends a booked job to
its worker whatever their tags say and however far away it is — they set their
own radius when they listed — and to nobody else at all. A declined booking is
cancelled rather than reopened: the hirer chose one person, and putting it back
on the map would broadcast what they asked not to broadcast.

**Declining is not walking away.** No cancellation penalty: nothing was agreed,
nobody was left waiting on the day, and Section 9 makes availability the
worker's call. Charging for it would make being available something a worker
has to pay to have. A booking also never expires on the map's seven-day clock.

**Credentials are self-declared, and every screen showing them says so.**
Section 2 verifies a CNIC and a phone number; it does not verify a degree.

### 0.11.0 — The demo gets a past

#### Added

- **The seed now has history.** Offers on the open jobs, winners and
  passed-over offers on the finished ones, ratings on completed work, and a
  role, trades and wallet for each of the five demo accounts. Jobs arrive in
  every state — open, accepted, in progress, finished, called off — so no
  screen in Phase 1 is unreachable from a fresh install.
- The five accounts are deliberately unlike each other: a hirer with postings
  in three states, a busy worker paid up and well rated, a worker **locked out
  by debt** so Section 11's lockout can be seen rather than read about, a
  nearly-new worker whose first-job credit is still visible in the ledger, and
  a generalist with the widest feed of the five.
- An **Offers** tab in Activity. A worker's own list is mostly the jobs they
  did not get, and until now a passed-over offer could only be found by
  remembering which job it was on.

#### Changed

- **General work leads the worker's trade list.** It is the one they already
  hold and the one that cannot be switched off; eighteenth in the list, the
  tile answering "will I still see general jobs?" was the last one anybody
  found. The hirer's tag picker keeps the declared order on purpose — there,
  general work first would make it the path of least resistance and quietly
  undo the rule Section 8 rests on.
- The map's "add a trade" notice can be dismissed, per account. Closing it
  changes nothing about the rule, but the notice sits over the map, and
  somebody happy on general work should not read it on every launch.
- Trade tiles shrink long labels to fit instead of breaking them mid-word.

#### Fixed

- **A race that emptied the new data.** Seeding used to happen inside
  `JobController.load()`, which was fine while the only seeded keys were the
  ones that controller read back itself. It stopped being fine the moment the
  seed grew offers, ratings and wallets: four other controllers read their
  keys as they are constructed, and raced the write. Seeding now happens in
  `bootstrap()` before the first frame, and the tests that pump the whole app
  go through the same function.
- The dismiss button on a map notice was a 40px target; Section 29 asks for
  48.

#### Notes on the design

The history is generated by a **second phase** on its own random seed, so
regenerating adds a past to the same jobs, in the same places, posted by the
same people. The jobs file gained three keys and changed no existing value.

**A demo has to be coherent or it teaches the wrong thing.** The generator
keeps a persona's offers to work Section 8 would actually have shown them — an
electrician holding an offer on a bricklaying job contradicts the rule the
whole feed rests on — and `test/demo_history_test.dart` checks the agreements
rather than the numbers: that an accepted job's fare matches the bid behind it,
that nobody bids on their own job, that ratings only attach to finished work,
and that every seeded commission is 5% of a real agreed fare.

**No loyalty bonus is seeded.** It triggers at Rs. 100,000 of lifetime top-up,
which at 5% implies around Rs. 2,000,000 of completed work — volumes this seed
does not have, and a ledger faked to reach it would be visibly incoherent on
the wallet screen, which shows every entry. The rule stays covered by tests.

### 0.10.0 — P1-5, ratings; and demo accounts

#### Added

- **Demo accounts.** The device can now be any of six people — the account it
  started on, plus five from the seed data, one per city and each with jobs
  already posted. Switching changes who owns which job, whose bids are yours,
  whose wallet is charged and which trades filter the feed. A switcher lives
  in the map header, in the app bar of every other destination, and at the top
  of the profile screen.
- Mutual rating, per Section 10. Either side of a finished job can score the
  other one to five with an optional note. **The two sides are not
  symmetric**: the worker's average is shown on their profile and next to
  their offer, the hirer's is collected and never displayed.
- A worker's record — average stars, jobs finished, and an **aggregated** fare
  average — under every offer in a hirer's list, and on the worker's own
  profile.

#### Changed

- Ownership of a job is now `postedBy == the active account`, not "posted on
  this device". The badge that said "On this device" says "Your posting".
- Role, trades, saved jobs and the wallet are stored per account. The account
  the app started on keeps the unsuffixed storage keys, so anything already in
  somebody's browser is still theirs after this update.
- `LocalStore.clear()` sweeps by key prefix rather than walking a list, because
  neither the media blobs nor the per-account keys are enumerable.

#### Notes on the design

**Demo accounts are not accounts.** No password, no verification, no privacy
between them; everything is in the same browser storage and switching is a
menu item. They exist because every rule Phase 1 added — who may bid, who may
edit, who is charged commission, who may rate whom — is a rule about *two*
people, and a device that could only ever be one of them left half the
behaviour unreachable. P1-8 replaces the whole idea with real accounts.

The five personas duplicate their names out of `assets/seed/users.json` so the
switcher can be drawn before the seed has loaded. `test/account_test.dart`
fails if the copies ever drift, and also fails if a persona has no jobs —
landing on an empty "my postings" list looks like a failed switch.

**A cancelled job cannot be rated.** Nobody did any work, and a one-star for a
job that never happened is a weapon rather than a signal; cancelling already
has its own consequence in the wallet. An unrated worker shows no stars rather
than a zero, because new is not bad and a zero says the opposite of the truth.

The hirer's ratings are reachable only through `internalHirerRatings`, named
explicitly so that the admin panel in P1-7 has to ask for them and nothing
else can leak them by accident.

### 0.9.0 — P1-4, the wallet

#### Added

- A token wallet with the full Section 11 rules: 5% commission on completion,
  the Rs. 500 first-job credit, a 1,000-token loyalty bonus at every
  Rs. 100,000 of lifetime top-up, one unpaid job tolerated and a second one
  locking the account, and a cancellation charge when a worker walks away from
  a job they accepted. Top-up is simulated and says so plainly on the screen —
  a page that looks like a payment form without being one is the shape of a
  scam, and a product about trust cannot teach people that Trust Hire asks for
  card numbers.
- The wallet screen shows the ledger, not a summary. A worker being charged 5%
  of their earnings should be able to see every charge without asking anybody,
  and it is the same list the balance is computed from.
- A locked worker cannot bid, and is told why rather than shown a dead button.

#### Notes on the design

**The ledger is the only stored state.** Balance, lifetime top-up, debt and the
lock are all derived by replaying it. The sprint's definition of done — "the
wallet cannot reach an inconsistent state" — is therefore structural rather
than defended: there is no balance field to disagree with the entries that
produced it, no repair routine, and no reconciliation bug to have.

Four things Section 11 left open are decided and recorded in the sprint plan:
the penalty is Rs. 200 flat, commission rounds down in the worker's favour, the
first-job credit is capped at the commission owed rather than granted outright,
and "a second job goes unpaid on top of that" is read literally — a commission
charged while already short locks the account, and clearing the balance clears
the count.


### 0.8.0 — P1-3, the job's life and the location reveal

#### Added

- **Statuses**: taking offers, worker chosen, under way, finished, called off,
  no longer listed. The hirer confirms arrival and completion — Section 7 gives
  those to the hirer because the hirer is the one who can see whether anybody
  turned up. The worker's only power is to walk away; letting them mark a job
  complete would let them claim a fare the hirer has not agreed was earned.
- **The mutual location reveal.** While offers are open, both sides see a
  general area and a distance and neither sees the other's exact point. Once a
  worker is chosen, both see it. A bystander never does, at any status. The map
  preview drops the approximation circle and shows the point instead — drawing
  both would leave the old circle on screen beside an address it no longer
  protects.
- Bidding now follows the status, so a cancelled or expired job stops taking
  offers without anybody having been accepted.

#### Changed

- **The privacy copy, in the same commit as the behaviour.** The POC promised,
  on the posting form, on every job, and in the onboarding, that an exact
  location is never shown. Phase 1 shows it. The new wording says when it is
  shared and with whom, and `lifecycle_test.dart` reads the catalogue and fails
  if the old promise comes back — or if the replacement stops saying *when*.
  A privacy promise that quietly stops being true is the failure this sprint
  existed to prevent, so it is guarded rather than remembered.

#### Deferred

- Before/after proof photos move to **P1-8**. They are media, and the
  compression and retention rules that govern media are already scheduled
  there; keeping them on-device with no retention policy would be the one
  place the app stores a picture of someone's home indefinitely.


### 0.7.0 — Jobs across Pakistan, and what that broke

The seed went from sixteen jobs around the twin cities to **183 across 25
cities** — every province and both territories, real neighbourhoods, and fares
scaled to the local cost of living. It is generated by
`tool/generate_seed_jobs.py` from a fixed random seed, so the demo is identical
on every machine and a diff to that file is the only thing that changes it.

Most of this entry is what the bigger dataset exposed.

#### Fixed

- **Widget tests hung the moment the seed passed 50 KB.** `rootBundle.loadString`
  hands anything larger to a background isolate via `compute()`, and that
  isolate's result never arrives inside `testWidgets` — its fake-async zone
  never runs it. The suite went from 30 seconds to over 13 minutes and then
  died with "Cannot close sink while adding stream", which names nothing
  useful. `SeedLoader` now reads bytes and decodes them itself, and a test in
  `job_repository_test.dart` guards the trap — including asserting the asset
  is still over the threshold, so it cannot start passing vacuously.
- **The details sheet opened every seeded job**, one at a time, to check none
  of them crashed it. Fine at sixteen; seven minutes at 183. It now opens one
  job per distinct *shape* — the combination of fields present and absent,
  derived from the data rather than listed — which is what it was ever really
  checking.
- **Long area names painted overflow stripes** over a job row in the 380px
  results rail. A `Wrap` gives a child the full line and lets it overflow past
  it; the meta chips are now capped and ellipsised.
- Tests that named `seed-001` and expected "Kitchen tap leaking" now select by
  property. With a generated seed, naming an id is testing the generator.

#### Added

- **Every job says where it is** — "Korangi, Karachi" — on the row and in the
  details. A row reading only "Help needed for a day" is unusable once the
  jobs are eight hundred kilometres apart, and a worker who has not shared
  their location has nothing else to go on. Neighbourhood and city, never an
  address, which is the promise the map already makes.
- `test/seed_scale_test.dart`: the data spans over 1,000 km, no two jobs share
  a point, titles do not repeat enough to look like a bug, and a worker in
  Karachi is never shown work in Lahore.

#### Changed

- The map opens on the work **near the starting point** rather than on all of
  it. Fitting everything zooms out to the whole country, where every pin is a
  dot and none is near anybody; "Show all jobs" is right there for whoever
  wants that view, and it should be a choice rather than what happens on
  launch.


### 0.6.0 — P1-2, bidding

A hirer can now take a job from posted to accepted at an agreed fare.

#### Added

- A **starting fare** on a job — optional, and explicitly an opening point
  rather than a price. A hirer with no idea what the work is worth should not
  be blocked from asking.
- **Offers.** A worker names their price, with an optional message; a hirer
  sees every offer on their own job and chooses one. Cheapest is listed first
  because a list needs an order, but Section 4 forbids auto-selection, so
  nothing marks a row as the one to take.
- **The fare locks at acceptance.** `Job.withAcceptedBid` is the only writer
  of `agreedFare` and refuses to run twice, and editing a job cannot reach it.
  Section 11's commission is trustworthy only while that number is the one
  both sides agreed to, so a second write is not a cosmetic bug — it is the
  platform charging against a figure nobody agreed.
- Bidding is closed to a worker the job never reached. That is the point of
  the P1-1 visibility rule: not "shown but should not be bid on".
- A loose ceiling on offers — ten times the opening ask — that exists only to
  catch a mistyped zero. A worker who knows the job is worth more is never
  stopped.
- Seeded jobs carry plausible opening fares, two of them deliberately without,
  so the demo shows both.


### 0.5.0 — The jobs beside the map

#### Added

- On a desktop-width window, discovery becomes two panes: the map keeps
  showing *where*, and a rail beside it answers *what* without covering it.
  One list, not two views of one — the rail renders exactly the jobs the pins
  come from, and selecting in either place selects in both.
- `JobRow` gained a selected state and an optional "Open details" action. The
  rail needs both halves of that: opening a sheet on every click would make
  the list unbrowsable, and no way through to the details would make it
  useless.
- The preview card stands down in the split view. It exists because a handset
  has nowhere else to put "what is this pin?", and beside a rail it would only
  cover the map to repeat what the rail already says.


### 0.4.0 — A layout for the screen it is on

The same build runs on a handset, a tablet and a desktop browser, and it only
ever laid out for the first: a bottom navigation bar stranded at the foot of a
1440px window, and job rows stretched into bands of white holding forty
characters.

#### Added

- `LayoutSize` in `core/layout.dart` — compact, medium, expanded — named for
  what the app does at each rather than for the device that usually has it. A
  phone in landscape gets the medium treatment because it has the room.
- A navigation rail from the medium breakpoint upward, with labels once there
  is space for them. A bottom bar on a desktop browser puts the app's main
  controls as far from the pointer as the window allows.
- `ReadableWidth`, and a `readableWidth` token, applied to the job list,
  Activity, Profile and the map's floating overlays. The map still takes the
  whole canvas; the cards over it no longer do.
- `test/support/surface.dart`. Flutter's default test window is 800x600, which
  under these breakpoints is a *tablet* — so every shell test written so far
  had been quietly asserting tablet behaviour without saying so. Tests that
  care now name the screen they mean.


### 0.3.1 — Saying when a job cannot be read

#### Added

- A job described only by a voice note now says so — in the list, and beside
  the player in the details sheet. WCAG 1.2.1 asks for a text alternative to
  prerecorded audio and there is none: the poster spoke because writing is
  hard, which is the product's whole premise, so requiring a summary would
  shut out the people it exists for. The honest middle is to name the gap
  rather than show a player and leave someone who cannot hear it to work out
  that they have missed something. Tags, area and time are still readable, so
  a job is never entirely opaque. Recorded as partial conformance in the Phase
  1 plan; real transcripts need speech recognition and arrive with the backend
  in P1-8.
- The posting form asks for a few words once a voice note is the only
  description, naming who they would help. It never blocks the save.

#### Fixed

- The tag field still carried the POC's copy — "Optional. Choosing one makes
  your job easier to spot on the map" — hard-coded in English and wrong since
  P1-1 made tags required. The localisation guard had missed it twice: it
  looked for a capital letter followed by a space, and this string opens with
  "Optional." It now counts words instead, which has no such blind spot, and
  is verified against all three strings that previously slipped past it.


### 0.3.0 — Activity and Profile

Two navigation labels described the code rather than what a person would find
behind them.

#### Changed

- **"Saved" is now "Activity".** The screen behind it has always held two tabs,
  Saved *and* Posted, so naming it after one of them sent anyone looking for
  their own postings to the wrong place.
- **"Settings" is now "Profile"**, with role and trades leading and the
  appearance, language and local-data controls grouped underneath as Settings.
  Role and trades are not preferences: since P1-1 they decide which jobs the
  rest of the app shows at all. A marketplace also needs somewhere to put a
  rating, a completed-jobs count and a fare average, and P1-5 now has it
  rather than bolting a marketplace identity onto a preferences screen.
- `settings_screen.dart` moved to `features/profile/`, next to the trades
  screen it links to.


### 0.2.1 — The web shell

Everything a person sees before the app loads was still Flutter's default,
thirteen sprints in, because nothing in the project ever looked at it.

#### Changed

- The app icon, the maskable variants and the favicon are the brand's map pin
  in white on Trust Burgundy, drawn by `tool/generate_app_icons.py` from the
  same tangent construction `job_marker.dart` uses, so the installed icon and
  the pins on the map are the same mark. They were the Flutter logo.
- `index.html` and `manifest.json` name the product, describe it, carry Open
  Graph and Twitter cards, and use Trust Burgundy rather than Flutter blue.
  They said `trust_hire` and "A new Flutter project." The manifest is no
  longer locked to `portrait-primary`, which the same build ignores on a
  desktop browser anyway.
- The page is no longer blank until the engine loads. A branded boot screen —
  mark, product line, indeterminate bar — hands over on `flutter-first-frame`
  rather than on a timer, so it never uncovers an unpainted canvas or lingers
  over a usable app. It stops animating under `prefers-reduced-motion`, and it
  carries the only description of the product a crawler that does not run
  JavaScript will ever see.
- The deploy injects a canonical URL, which is only knowable there: the repo
  can be forked or renamed, and a canonical pointing at the wrong origin is
  worse than none.

#### Added

- `test/web_shell_test.dart`, which fails on each of those defaults
  specifically. Re-running `flutter create` over the project restores every
  one of them silently.


### 0.2.0 — Versioning, and a map that stops flickering

#### Added

- An app version, in `pubspec.yaml` and mirrored in `lib/core/app_version.dart`,
  shown at the foot of settings and at the bottom of the post/edit job form.
  The deployed web app is served from a URL with no commit in it, so without a
  visible version a stale cache and a failed deploy look identical.
  `test/version_test.dart` fails the build if the two ever disagree, since a
  drifted mirror is worse than no version — it names the wrong build with
  confidence. README, `AGENTS.md`, `CLAUDE.md` and the Copilot instructions all
  now require raising it on every push.

#### Fixed

- Markers regrouped on every camera frame, so pins visibly merged and split
  apart mid-drag — one job appearing to arrive and leave several times in a
  single pan. Clustering works in screen space, which is why panning changed
  it at all. The grouping is now held for the duration of a movement and
  recomputed once the camera settles. Markers are positioned by latitude and
  longitude, so a held grouping still pans and zooms; only the decision about
  what is grouped waits. A changed job list — a filter, a trade added — never
  waits, or a removed job would linger on the map.


### P1-1 — Roles, tags and visibility

The first Phase 1 sprint. It replaces the POC's optional job type with the
mechanism the marketplace rests on: a job reaches a worker only when a job tag
overlaps a worker tag **and** the job is within reach.

#### Added

- `JobVisibility` (`lib/features/feed/`) — the Section 8 rule, as pure
  functions over plain data so it can be checked without a widget, a database
  or a network. `explain()` returns *why* a job did not reach someone, because
  "why can't I see this job?" is otherwise unanswerable from the outside and a
  worker losing income will reasonably ask.
- `WorkerProfile` and `UserRole`. A worker starts on general work with no
  selection screen; adding a trade only ever widens the feed, and the default
  cannot be removed — a worker with no tags would have an empty feed forever.
- A "My trades" screen, and a role switch in settings. Switching role leaves
  the tag list alone: someone who hires a painter today and looks for work
  tomorrow should not have to pick their trades again.
- `TagTile`, shared by the hirer tagging a job and the worker picking trades —
  the same decision from two sides, so it should not be two controls.
- A trades prompt on the map and an "add a trade" empty state in the job list,
  both naming the rule. The rule is not a filter the user can clear, so
  offering "clear filters" there would be a dead end.

#### Changed

- `JobType` is now `JobTag`: 19 values, with legal, medical and beauty added.
  A job carries **1 to 3, required** — the one thing the posting form insists
  on, because a job with no tag would be posted into silence. The save bar
  says which of the two rules is unmet rather than marking a field with an
  asterisk.
- The seed data carries tags, including a specialty job a general worker
  cannot see and one that needs no travel. Without those the demo would never
  exercise the rule it is meant to show.
- The map frames its first load around the jobs the viewer can actually see.
  The fixed opening camera worked only because the old seed surrounded it; a
  worker now sees a subset, and an empty map on first launch reads as no work
  available.

#### Fixed

- A dozen user-facing English strings had never been swapped for their
  catalogue entries — the map's job count, its notices, the photo-gallery and
  cluster labels, the microphone and area help, and three settings panels. The
  app looked translated because the screens opened first were. The guard test
  now catches both `'Posted ${...}'` and `'$count jobs'`; it previously caught
  neither.
- `JobController` and `JobDraftController` wrote English error text that then
  won over the screens' localised fallbacks. Both now report *that* something
  failed and let the screen supply the words.
- A job whose heading fell back to its tag printed that tag twice — once as
  the heading, once as "kind of work". `Job.supportingTags` excludes it, in
  the same way `supportingDescription` already did for the description.
- Three map notices could print on top of each other: two were positioned
  absolutely at the same offset, next to a comment claiming they could not.


### Documentation — Phase 1 specification added

#### Added

- `documents/product/phase-1-system-logic.md` — a full system specification
  for a two-sided marketplace: worker verification, bidding, wallets and
  commission, premium accounts, ratings, and an admin panel, on a Supabase
  backend.
- `documents/product/poc-vs-phase-1.md`, reconciling it with the POC that
  Sprints 0–12 built. **They are not the same product**, and eight decisions
  contradict outright — framework (Flutter vs React Native), backend,
  accounts, money, categories, location privacy, pricing, and target
  platforms.

Two contradictions are about the product rather than the plumbing, and matter
most:

- The brand guidelines say users should never choose a category; Phase 1 makes
  1–3 tags mandatory and builds visibility on them.
- The POC promises, in copy the user would rely on, that an exact location is
  never shown; Phase 1 reveals exact addresses after acceptance.

No code changed. The note sets out what carries over either way — the brand
implementation, the Urdu catalogue, the seed data, and the recorded reasoning
behind each product decision.

### Sprint 12 — Onboarding and permission priming

199 tests pass, the analyzer is clean.

#### Added

- **A first run** — three skippable panels covering what the app is, that you
  post by speaking rather than typing, and what location is for. The central
  idea is unusual enough that an audience used to forms will not discover it
  by poking around.
- **"Show Intro Again"** in settings, for demos and for anyone who skipped too
  fast.

#### Changed

- **Location is no longer requested at launch.** The app used to ask the
  moment it opened, before saying what for — precisely what section 19 warns
  against. It is now asked only on the last intro panel, after explaining
  what it buys and that refusing costs nothing, with "Not Now" offered as
  plainly as accepting. Afterwards only "Near Me" asks.

### Sprint 11 — Saved jobs and my postings

187 tests pass, the analyzer is clean.

#### Added

- **Saving a job**, from a bookmark beside the heading on the details sheet.
  It sits there rather than at the bottom because deciding to keep a job
  happens while reading it, not after scrolling past the map.
- **A "Saved" destination** with two tabs: work you kept, and work you posted.
  Both answer the same gap — the app had nowhere to come back to. A worker who
  found a job had to find it again; a poster had no home for what they offered.
- `JobRow`, extracted so the browse list and both new lists cannot drift apart.
- 13 tests covering toggling, ordering, persistence, resolution against live
  jobs, pruning, and both tabs.

#### Notes

**Ids are stored, not copies of the job.** A saved job that has since been
edited shows the edit, and one that has been deleted disappears rather than
lingering as a stale duplicate. When something saved has gone, the list says
so once instead of quietly shrinking.

### Sprint 10 — Contacting the poster

174 tests pass, the analyzer is clean.

#### Added

- **A phone number on each job, and the two ways people actually use one** —
  the dialler and WhatsApp, plus copy to clipboard. The POC stopped at
  *finding* work, which made it impossible to test whether anyone would act on
  it; handing off to apps people already have closes that loop with no
  backend, account or messaging system.
- The number is **hidden until asked for**. The product promises approximate
  locations and says so on every job; showing a phone number unprompted
  alongside that would undercut it. A deliberate tap is also a small brake on
  casual scraping — not real protection, and the copy says as much rather than
  implying otherwise.
- An optional phone field when posting, with copy explaining it is shown only
  to people who tap to see it.
- Seed data gains numbers, with two jobs deliberately left without so the
  "no contact details" path stays exercised.
- 16 tests covering number normalising, the WhatsApp country-code rules,
  reveal-on-tap, both hand-offs, clipboard copy, and failure.

#### Notes

**The country code is where this breaks.** A Pakistani number written the local
way — `0300 4471902` — is meaningless to WhatsApp, which wants `92300…`. The
launcher swaps a leading zero for the country code, leaves an international
number alone, and refuses to double a code that is already there; each of
those is a test.

**Every hand-off can fail** — no dialler, no WhatsApp, a browser blocking the
scheme. When one does, the number stays on screen and the message says you can
use it yourself, rather than the tap appearing to do nothing.

### Sprint 9 — Urdu and right-to-left support

158 tests pass, the analyzer is clean.

#### Added

- **The full interface in Urdu**, with right-to-left layout. The brand
  guidelines call for mixed English and Urdu interfaces and section 29 lists
  them among the accessibility requirements; for this audience it is closer to
  a requirement than a feature.
- A language control in Settings — English, Urdu, or follow the device, saved
  locally. Each language names itself, so someone who cannot read the current
  one can still find their own.
- Noto Sans Arabic and Noto Nastaliq Urdu bundled alongside Inter. Section 10
  warns that Nastaliq should not be set small and suggests Noto Sans Arabic
  for dense labels, so Noto Sans Arabic carries the interface at every size.
- 15 tests covering catalogue coverage, RTL layout, the persisted preference,
  translated job types, headings and formatting.

#### Notes

**Translation is more than the chrome.** Job types, the headings a job falls
back to when it has no title, distances, and relative times all had to move
into the catalogue — a card reading "2 km away · Plumbing" inside an otherwise
Urdu screen was the most visible thing left in English. Search takes the
catalogue too, since it reaches a job's *shown* words: searching Urdu text
against English labels would quietly have found nothing.

**Two tests guard the seams.** One fails the build if a key exists in English
but not Urdu, or if an Urdu value was left as its English original. The other
catches interpolated English (`'${count} photos'`), which the bulk replacement
could not see and which had in fact been missed in two places.

**The Urdu needs a native reviewer.** The translations are careful and follow
section 20's plain vocabulary, but they have not been checked by a native
speaker, and the register matters for an audience the product describes as
avoiding formal language.

#### Fixed

- Formatting a date in any non-default locale threw, because
  `initializeDateFormatting` was never called. It threw inside a build, so it
  would have surfaced as a blank screen rather than an error.

### Sprint 8 — Map at scale

143 tests pass, the analyzer is clean.

#### Added

- **Marker clustering.** Listed as optional in Sprint 1 and left undone; now
  necessary, because the seed data spans Islamabad to Muzaffarabad and at any
  zoom showing the whole picture the twin-cities pins piled on top of each
  other with none of them tappable. Tapping a cluster zooms to fit the jobs
  inside it, capped at zoom 16 so a tight group does not drop to street level
  and lose all context.
- A cluster keeps its kind's glyph when every job in it is the same kind — a
  group of five plumbing jobs says more than five anonymous ones.
- **"Show all jobs"**, which fits the camera to every visible job. Without it a
  job in Kashmir sat off-screen with nothing hinting it existed.
- 14 tests covering grouping, separation as zoom increases, every job landing
  in exactly one group, cluster centres, uniformity, bounds, and the rendered
  markers.

#### Notes on the approach

Clustering works in **screen space, not degrees**. Grouping by degrees would
behave differently at the equator than at 34° north, and the problem being
solved is pins overlapping on screen — a pixel problem, not a geographic one.
The grid cell is roughly one marker wide, so two jobs merge only once their
pins would actually collide.

### Sprint 7 — Job types and Pakistan-wide seed data

129 tests pass, the analyzer is clean.

#### Added

- **Job type, chosen by the poster, driving the marker icon.** Sixteen kinds of
  work, each with its own glyph, so a plumbing pin and a driving pin read
  differently at a glance where a microphone on both did not.
- Type filter chips in the filter sheet, and type labels are searchable — so
  "plumbing" finds a plumbing job that never used the word.
- `documents/product/roadmap.md`, covering what the POC delivered, the next
  four sprints, what to validate before building a backend, and what is
  deliberately deferred and why.
- `test/support/seed_facts.dart`, which reads counts from the seed file so
  tests assert behaviour rather than how many examples happen to ship.

#### Changed

- **Seed data moved to Islamabad, Rawalpindi and Kashmir** — 15 jobs across
  the twin cities, Muzaffarabad and Mirpur, with posters' areas to match. The
  map's fallback centre moved from Lahore to between Islamabad and Rawalpindi.
- Job markers are now 48px rather than 44px. Section 29 names 48 as the
  *preferred* target and Android's guideline requires it; a pin is also harder
  to hit than a rectangle, since its lower half tapers to a point. Caught by
  the accessibility audit added in Sprint 6.

#### Notes on the type being optional

The brand guidelines are explicit that users should never have to choose a
category — "Smart Categories" says they are generated, and design principle 2
lists categories under what not to require. So the type is offered, never
demanded: there is no "please select", tapping the chosen tile again clears
it, and a job with no type falls back to showing what it carries. Some seeded
jobs stay untyped on purpose, and a test enforces that so the fallback keeps
being exercised.

One filter behaves differently from the rest and the sheet says so: filtering
by kind *does* hide untyped jobs, because asking for "plumbing" is a question
a job that never said its kind cannot answer.

#### Fixed

- `Job.toJson` never wrote the type, so seeding silently dropped every type on
  the way into local storage. `hasContent` did not count a type either, so a
  job described only by its kind counted as empty.

### Sprint 6 — Polish

Definition of done: feels like a production mobile application. Met — 110 tests
pass, including Flutter's tap-target, semantic-label and text-contrast audits
run against the live app.

#### Added

- Reduced-motion support throughout. Animations go through `Motion`, which
  collapses durations to zero when the platform asks for less movement, so no
  screen has to remember. Nothing is removed — only the movement.
- Loading placeholders in the shape of the content instead of a spinner, so
  the layout does not jump when data lands. Section 28 rules out decorative
  loading animations, so the shimmer is slow and low-contrast, and stops
  entirely under reduced motion.
- A short stagger as list items settle in — 8 logical pixels of movement, not
  a parallax sweep.
- An accessibility test suite that holds the app to the numbers in section 29
  rather than to a glance: Flutter's `androidTapTargetGuideline`,
  `iOSTapTargetGuideline`, `labeledTapTargetGuideline` and
  `textContrastGuideline` against the running app, plus WCAG contrast maths
  over every text pairing the app actually uses, the 12px type floor, the
  documented motion bands, and rendering at 2× text scale.

#### Fixed

- **A crash under reduced motion.** `LoadingBlock` held its `AnimationController`
  in a `late final` field, which `build` never read when animations were
  disabled — so `dispose()` constructed the controller for the first time and
  looked up `TickerMode` on a deactivated element. Both animation controllers
  now initialise in `initState`.
- **The map had no accessible name.** It is one large tappable surface with no
  text of its own, so a screen reader announced an unnamed button covering the
  screen. Caught by `labeledTapTargetGuideline`, not by eye.
- The Pages workflow still carried a fallback that published
  `deployment/pages/`, which no longer exists now that the app itself is the
  deployment. Removed, along with the branch that chose between them.
- Tile caching pulled in `path_provider`, which threw on platforms without it.
  All three maps — the main one, the details preview and the area picker — now
  build their tile layer through one `MapTheme.tileLayer` factory with disk
  caching off, so they cannot drift apart either.

### Sprint 5 — Discovery

Definition of done: jobs easily discoverable. Met — 97 tests pass, 20 of them
covering the filter's behaviour directly.

#### Added

- Search across titles and messages. Every word must match, so extra words
  narrow rather than widen, and a voice-only job stays findable through its
  fallback heading.
- Quick filters as one-tap chips — "Today's Jobs" and "Near Me" from the
  sprint plan, plus voice note and photos — with a sheet holding the fuller
  set (tomorrow, this week; 2 km, 5 km, 10 km). Tapping an active chip clears
  it, and selection shows a tick as well as a fill so colour is not the only
  signal.
- One filter shared by the map and the list, so switching tabs does not
  silently change what you are looking at. The map header reads "4 of 12" when
  filtering is on, so a short list never looks like a bug.
- Empty states that distinguish "nothing posted yet" from "nothing matches" —
  they need different next steps — with a way back out of the filter.

#### Notes on behaviour

Two decisions worth recording, both about not punishing the user for how this
product actually works:

- **A job with no scheduled time is never hidden by a time filter.** "Any
  time" is a normal state here, not missing data, and such a job could well be
  wanted today. Filtering it out would lose real work.
- **The distance filter stands down when there is no position.** Emptying the
  list because location was refused would punish a permission choice the
  product elsewhere treats as fine.

### Sprint 4 — Editing

Definition of done: CRUD completed. Met — 77 tests pass, covering update and
delete alongside the create path from Sprint 3.

#### Added

- Edit and delete on the job details sheet, for jobs created on this device.
  Seeded jobs stand in for other people's postings, so they offer neither.
- Editing reuses `JobDraftController` rather than duplicating the form: it
  opens on the job as it stands, keeps the id and original posting time, and
  leaves untouched photos alone. Photos can be dropped or added and the voice
  note re-recorded.
- Deleting asks first, with the destructive choice labelled "Delete Job" and
  the safe one "Keep Job" — never "Confirm" or "Yes", per section 22.
- The details sheet refreshes itself after an edit because it watches by job
  id, and says the job is gone rather than showing a stale copy after a delete.
- 10 tests covering in-place update, persistence across reload, deletion,
  media pruning, and the sheet's actions.

#### Fixed

- Saving an edit left orphaned media in storage. Dropping a photo or replacing
  a recording now prunes the bytes nothing references, which previously only
  happened on delete. Media still used by another job is left alone.

### Sprint 3 — Create job

Definition of done: new jobs appear immediately and persist. Met — 67 tests
pass, including the full save path from capture to stored job.

#### Added

- Posting a job. Voice first, then photos, then the optional words — the order
  design principle 3 asks for, since every extra field costs adoption.
- Area picker: the pin stays fixed at the centre and the map moves under it,
  which is one-handed and impossible to mis-tap, with a radius slider from
  250 m to 5 km and the work area drawn as you change it. The copy says the
  exact location will not be shown, because it will not be.
- Voice recording with the section 26 states — copper to start, Error Red
  while recording with a running timer, then "Voice Note Added" with
  "Record Again" and a discard action.
- Photos via camera or gallery, as large tiles with a remove control. No
  captions are ever requested.
- Optional date and time, clearable back to "Any time".
- `JobDraftController`, which holds a draft for both posting and editing, and
  `CaptureService`, which returns bytes rather than paths — a path captured on
  web is a blob URL that stops resolving after a reload.
- **No required fields and no asterisks.** The only rule is that a job say
  something; the save bar names what would satisfy that rather than refusing
  silently. Saving is blocked mid-recording so a note in progress is not lost.
- A refused microphone or a cancelled camera leaves the rest of the form
  working and explains itself.
- 16 tests covering each single-input path (voice alone, photo alone, title
  alone), whitespace not counting as content, capture refusals, and the shape
  of the job that comes out.

### Sprint 2 — Job details

Definition of done: every seeded job opens correctly. Met — 51 tests pass,
including one that opens all 12 seeded jobs and asserts none throws.

#### Added

- Job details bottom sheet (section 25): draggable, map preserved behind it,
  media first. Photos, then the voice note, then the written detail — the
  order the product expects work to be described in.
- Swipeable photo gallery with page indicators and a full-screen pinch-zoom
  viewer. Captions are never required.
- Voice note player (section 26): Warm Sand surface, burgundy play button, and
  a copper waveform that fills as it plays. The waveform is derived
  deterministically from the recording reference — decoding real audio is
  beyond a POC — so it is stable per recording and different between them.
- `MediaStore`, which resolves a media reference to either a bundled asset
  (seed data) or bytes in local storage (captured on device). Bytes are held
  as base64 rather than files because a file path recorded on web is a blob
  URL that dies on reload, which would break the requirement that locally
  created jobs persist.
- Map preview of the job's approximate area, with copy saying so explicitly.
- Deleting a job now prunes any photos and recordings nothing else references,
  and restoring the seed clears captured media rather than orphaning it.
- The sheet watches by job id, so an edit or delete elsewhere is reflected
  live; if the job disappears it says so instead of showing a stale copy.

#### Changed

- **Map theming.** Each brightness now gets a purpose-built basemap — CARTO
  Positron in light, Dark Matter in dark — instead of a colour filter over a
  single OpenStreetMap raster. Darkening that raster produced muddy greens and
  hurt label legibility, satisfying neither section 15's low-noise light map
  nor section 30's warm dark mode. A low-opacity brand tint over the tiles
  ties the surface to the palette without touching contrast, and the tile
  style is now the only thing that changes between themes.
- Attribution updated to credit both OpenStreetMap and CARTO, as required.

### Sprint 1 — Map screen

Definition of done: user can browse seeded jobs. Met — 38 tests pass, the
analyzer is clean, and the built app renders pins, selection and previews.

#### Added

- The map, built on `flutter_map` with OpenStreetMap tiles. No API key is
  needed, so the app runs from a fresh checkout with no setup.
- Job markers styled per section 15 — Trust Burgundy by default, Deep Burgundy
  with a Copper outline when selected, Copper for jobs created on this device.
  The marker icon reflects the job's content (voice, photo, or neither), and
  selection also enlarges the pin so colour is never the only cue.
- Tapping a marker selects it, centres the map, draws the job's approximate
  work area as a translucent circle, and raises a preview card with the
  schedule, distance, area and media it carries.
- Current location with a "Near Me" control, shown in Information Blue rather
  than green. A refusal is a normal state, not an error: the map centres on
  Lahore, hides distances, and explains what the user can still do.
- Graceful degradation when map tiles cannot be fetched — markers stay
  correctly positioned over the warm background and a notice explains it.
- OpenStreetMap attribution, as its licence requires.
- 15 further tests covering marker rendering, tap reporting, the work-area
  circle, user-location display, and every location-refusal path against a
  fake service.

#### Fixed

- The map rendered at zero height. Its `Stack` sized itself to the collapsed
  preview switcher, its only non-positioned child. Widget tests had passed
  because `find.text` locates widgets regardless of size, so the suite now
  asserts the map's rendered dimensions too.
- Job pins drew at glyph size rather than marker size — `CustomPaint` sizes to
  its child when given one, so the pin and icon are now stacked instead of
  nested.
- The pin's head and point were separate subpaths, leaving the outline stroke
  cutting a seam across the join. Now one continuous path.
- Cards printed the same sentence twice for jobs with no typed title, where
  the heading falls back to the description. `Job.supportingDescription`
  returns the description only when it is genuinely additional.

### Sprint 0 — Repository setup

Definition of done: application launches. Met — 23 tests pass, the analyzer is
clean, and the web build renders the shell with seeded data.

#### Added

- Flutter application at `code/frontend/` (Flutter 3.44.8, Dart 3.12.2),
  targeting Android and iOS with web enabled so the POC can be demonstrated in
  a browser.
- Folder structure from the sprint plan: `lib/{app,core,features,models,services,widgets}`
  with feature folders for `map`, `jobs`, `create_job` and `settings`, plus
  `assets/{seed,images,audio,fonts}`.
- Brand theme in `lib/core/tokens.dart` and `lib/core/theme.dart` — the Dart
  equivalent of the CSS tokens in section 31 of the brand guidelines, covering
  the palette, radii, touch targets, type scale, motion timings, and light and
  dark themes. Component styling follows sections 22–25.
- Inter bundled as a font asset rather than fetched at runtime, so typography
  survives with no internet connection.
- Seed data at `assets/seed/{jobs,users}.json` — 12 jobs and 9 posters around
  Lahore. Jobs deliberately vary in completeness (voice only, photos only,
  title only) to exercise the flexible-posting principle. Times are stored as
  day offsets so the demo data stays plausibly current.
- Local persistence: a JSON document store over `shared_preferences`
  (`LocalStore`), behind `JobRepository` so the engine can be swapped for Isar
  or SQLite post-POC. Seeds on first run, then reads and writes the local copy
  only, with no network calls anywhere.
- Navigation scaffold — Map, Jobs and Settings destinations with posting always
  one tap away. Settings carries the theme control and a "Restore Seed Data"
  action.
- Shared loading, empty, error and notice views with recovery-oriented copy.
- 23 tests covering flexible posting, title fallbacks, JSON round-tripping,
  haversine distance, repository seeding and CRUD, and app launch.
- `tool/generate_placeholder_assets.py` — stdlib-only generator for the
  placeholder job photos and voice notes.

#### Changed

- GitHub Pages workflow now builds the Flutter web release, gated on
  `flutter analyze` and `flutter test`. It passes `--no-web-resources-cdn` so
  CanvasKit is served from the deployment rather than gstatic, keeping the app
  loadable without third-party network access.

### Added

- Project folder structure: `documents/` for all non-code documentation
  (agile with sprint-planning, backlog and retrospectives; brand-guidelines;
  product; design; research; meeting-notes) and `code/` for application source,
  split into `backend/` and `frontend/`.
- `README.md` documenting the folder structure, the Claude Code plugins, and
  the available commands, agents, hooks, and skills.
- This changelog.
- Claude Code configuration in `.claude/settings.json`: registers the
  `anthropics/claude-code` plugin marketplace and enables the `feature-dev`,
  `code-review`, `commit-commands`, and `security-guidance` plugins.
- `AGENTS.md` with instructions for AI coding agents, requiring them to read
  the README before starting work and to keep it up to date as part of any
  change. `CLAUDE.md` and `.github/copilot-instructions.md` are short entry
  points that restate those two rules and defer to it.
- `deployment/` for deployment configuration, holding a placeholder static
  site in `deployment/pages/`.
- GitHub Pages deployment via `.github/workflows/deploy-pages.yml`, running on
  every push to `main` and manually dispatchable. It publishes
  `deployment/pages/` until `code/frontend/package.json` exists, after which it
  builds the frontend and publishes its output instead.

- POC sprint plan at `documents/agile/sprint-planning/poc-sprint-plan.md` —
  vision, POC goals and exclusions, technical constraints (no backend, seed
  JSON copied into local storage), the core job model, design and UX
  principles, Sprints 0–6, stretch goals, and success criteria.

- Brand guidelines at `documents/brand-guidelines/brand-guidelines.md` —
  positioning, the burgundy/copper/warm-sand palette with functional colours,
  typography and type scale, logo direction and usage, iconography, map
  styling, photography and illustration direction, voice and tone,
  terminology, component and form specs, motion, accessibility requirements,
  dark mode, and example CSS and Tailwind design tokens. Section 35 is
  incomplete in the source and is marked as awaiting text.

### Changed

- Folder documentation consolidated into the top-level `README.md`; the
  per-folder `README.md` files were removed and their conventions folded in.
  Empty directories are now held by `.gitkeep`.
