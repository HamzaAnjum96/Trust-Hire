# Trust-Hire

Proof of concept for Trust Hire.

This repository holds the product documentation, the application code, and the
deployment configuration. Every notable change is recorded in
[`CHANGELOG.md`](CHANGELOG.md).

> **Working here — human or AI?** Read this README before you start. It is the
> single source of truth for what goes where. AI agents should also read
> [`AGENTS.md`](AGENTS.md); see [Working with AI agents](#working-with-ai-agents).

---

## Project structure

```
Trust-Hire/
├── README.md                     ← you are here; explains every folder below
├── CHANGELOG.md                  ← running log of notable changes
├── AGENTS.md                     ← instructions for AI coding agents
├── CLAUDE.md                     ← Claude Code entry point → AGENTS.md
│
├── .claude/
│   └── settings.json             ← Claude Code marketplace + enabled plugins
├── .github/
│   ├── copilot-instructions.md   ← Copilot entry point → AGENTS.md
│   └── workflows/
│       └── deploy-pages.yml      ← GitHub Pages deploy, on push to main
│
├── documents/                    ← all non-code project documentation
│   ├── agile/
│   │   ├── sprint-planning/
│   │   ├── backlog/
│   │   └── retrospectives/
│   ├── brand-guidelines/
│   ├── product/
│   ├── design/
│   ├── research/
│   └── meeting-notes/
│
├── code/                         ← all application source
│   ├── backend/
│   │   ├── migrations/           ← the PostgreSQL schema, applied in order
│   │   ├── test/                 ← what the schema refuses
│   │   └── tool/                 ← verify_schema.sh, sweep_schema.sh
│   └── frontend/
│
└── deployment/                   ← deployment configuration and assets
```

Empty folders carry a `.gitkeep` so git tracks them. Delete it once the folder
has real content.

---

## Documents

`documents/` is the home for everything that is not source code. It is split by
*purpose* rather than by author or date, so a document's location tells you what
it is for.

| Folder | What belongs in it |
| --- | --- |
| `agile/sprint-planning/` | [`poc-sprint-plan.md`](documents/agile/sprint-planning/poc-sprint-plan.md) is the master plan for the POC — vision, goals, constraints, and Sprints 0–6 as originally scoped — the build ran to Sprint 13. [`phase-1-sprint-plan.md`](documents/agile/sprint-planning/phase-1-sprint-plan.md) plans what follows it, P1-1 to P1-9. Alongside them, one document per sprint as it is planned in detail: sprint goal, committed scope, team capacity, risks and dependencies, definition of done. Name those `sprint-NN-planning.md`, zero-padded. |
| `agile/backlog/` | Epics (`epic-<slug>.md`) and user stories (`story-<slug>.md`) with testable acceptance criteria. A story is *ready* when its criteria are testable and its open questions are resolved — only ready stories get pulled into planning. |
| `agile/retrospectives/` | `sprint-NN-retro.md`, matching the sprint number, or `phase-N-retro.md` for a whole phase — [`phase-1-retro.md`](documents/agile/retrospectives/phase-1-retro.md) covers P1-1 to P1-7 and [`p1-8a-p1-9-retro.md`](documents/agile/retrospectives/p1-8a-p1-9-retro.md) the two after it, and [`0-15-x-retro.md`](documents/agile/retrospectives/0-15-x-retro.md) the three UI and refactor rounds after *that* — which is where the carried actions' current status lives. What went well, what did not, and **actions with named owners**. Carry unfinished actions forward explicitly. Write it at the end of the sprint; a retro covering seven of them at once is archaeology. |
| `brand-guidelines/` | [`brand-guidelines.md`](documents/brand-guidelines/brand-guidelines.md) is the source of truth: positioning, the burgundy/copper/sand palette, typography, logo direction, iconography, map styling, voice and tone, component specs, motion, accessibility, dark mode, and design tokens. Anything user-facing should be traceable back to it. Add new colours with their hex value *and* intended use; keep source assets next to exports. |
| `product/` | [`roadmap.md`](documents/product/roadmap.md) sets out what comes after the POC. [`phase-1-system-logic.md`](documents/product/phase-1-system-logic.md) specifies a fuller two-sided marketplace, and [`poc-vs-phase-1.md`](documents/product/poc-vs-phase-1.md) reconciles the two — **read that before building against either**. [`demo-script.md`](documents/product/demo-script.md) walks somebody through the built app in about fifteen minutes, stop by stop — and every stop is checked by `test/demo_walkthrough_test.dart`, so the script cannot rot quietly. [`ux-audit-response.md`](documents/product/ux-audit-response.md) answers the UI/UX audit finding by finding: done, scheduled, or declined with a reason. Alongside them: vision, PRDs (`prd-<slug>.md`), personas, success metrics. State non-goals as clearly as goals, and number requirements so backlog stories can reference them. |
| `design/` | User flows, wireframes, mockups, design-system and accessibility decisions. Link the live design tool **and** commit a dated export — links rot. Record the reasoning, not just the picture. |
| `research/` | User interviews, competitor analysis, market sizing, surveys. Separate observation from interpretation. **No personal data** — refer to participants by reference (`P3`), and keep names, CVs, and recordings out of the repository. |
| `meeting-notes/` | `YYYY-MM-DD-<topic>.md`. Decisions and owner-assigned actions are the part worth keeping; reflect anything structural into `product/` or `code/` too, because nobody will find it here later. |

### Document conventions

- **Markdown by default.** Reach for Word, PowerPoint, or Excel only when the
  format is the point — a client-facing deck, a financial model.
- **Lowercase, hyphenated filenames** — `sprint-04-goals.md`, not
  `Sprint 04 Goals.md`.
- **Date-prefix anything time-bound** as `YYYY-MM-DD-` so it sorts
  chronologically.
- **Keep assets next to the document that references them.**
- **One topic per file.** Several short documents beat one long one.

---

## Code

`code/` holds the application itself, split into two independently runnable
halves.

| Folder | What belongs in it |
| --- | --- |
| `code/frontend/` | The Flutter app — the whole POC lives here. Design tokens implement `documents/brand-guidelines/` rather than restating it. |
| `code/backend/` | The PostgreSQL schema, and the tests that try to break it. **Nothing is hosted.** The app talks to a mock that enforces the same rules — see [The backend that is not there](#the-backend-that-is-not-there) — so the POC still runs entirely on-device. |

### The schema (`code/backend/`)

PostgreSQL 16, written to run on Supabase. Four migrations, applied in filename
order, and no ORM: the file you read is the schema the server has.

```
code/backend/
├── migrations/
│   ├── 0001_identity.sql      ← tags, profiles, worker trades, verification
│   ├── 0002_jobs.sql          ← jobs, their tags, their media, the fare lock
│   ├── 0003_marketplace.sql   ← bids, ratings, the wallet, the directory
│   └── 0004_oversight.sql     ← disputes, the audit log, the CNIC door
├── test/
│   └── schema_test.sql        ← 55 statements it must refuse, 11 it must not
└── tool/
    ├── verify_schema.sh       ← build a throwaway database, apply, test, drop
    └── sweep_schema.sh        ← drop each rule in turn; does the suite notice?
```

**The rules live here, not only in Dart.** Nine of them decide what money moves
or who reads somebody's identity document — the fare is written once at
acceptance, one winning bid per job, the ledger is append-only, commission is
charged once, a CNIC opens only while a dispute names that person, an override
carries a reason. Those held in the app because `AdminController` and
`Job.withAcceptedBid` are the only writers, which is a promise *one client*
keeps. They are now constraints and triggers, which is the same promise kept
for every client there will ever be.

Two consequences worth knowing before changing anything here:

- **There is no balance column.** Balance, debt and the lockout are replays of
  `wallet_entries`, exactly as in the app. Nothing to drift, and nothing to
  correct except by appending — which is what the append-only trigger says.
- **`worker_standing` is the only thing a public screen should read.** It
  cannot expose a hirer's rating because it never selects one, which makes the
  ratings asymmetry a property of the query rather than a rule each screen has
  to remember.

**Running the checks** — needs a local PostgreSQL and permission to create a
database. Both build and drop their own; neither touches anything else.

```bash
code/backend/tool/verify_schema.sh    # seconds
code/backend/tool/sweep_schema.sh     # minutes — run it when the schema changes
```

**Why the second script exists.** `verify_schema.sh` proves the schema refuses
what it should. It cannot prove the *tests* are doing the refusing: a check
aimed at a row that also violates a neighbouring rule passes whether or not the
rule it names still exists. The sweep drops each of the 50 rules in turn and
re-runs the suite; anything whose removal goes unnoticed is reported and fails
the run. It found two such checks on its first pass, both of which had been
green from the moment they were written. If you add a rule, add a test that
provokes *only* it — and if nothing can, say so in the sweep's
`expected_uncovered` list with the reason, as `bids_one_accepted_per_job` does.

### The backend that is not there

There is no Supabase project and no credentials, so P1-8b delivered the **seam**
and a stand-in behind it. Swapping in a real client means implementing one
interface, `RemoteApi`, and nothing above it changes.

```
lib/services/backend/
├── remote_api.dart     ← what crosses the wire, and how a refusal is described
└── mock_backend.dart   ← in-memory, and it says no
lib/features/sync/
└── sync_rules.dart     ← the outbox, and who wins when two copies disagree
lib/app/sync_controller.dart
```

**The mock refuses what the schema refuses**, and that is the whole reason it is
worth having. A mock that accepts whatever it is handed is a dictionary with
latency: the sync layer above it looks correct while being unable to cope with
the one thing a server does, which is say no. `MockBackend.rulesEnforcedHere`
maps every refusal it can give to the migration that rule comes from, and a test
fails if a code is added without one.

Four things to know before changing anything here:

- **The app is offline-first, and that is not a concession to the mock.** A
  local write lands locally and immediately; the queue reconciles afterwards.
  The people this is for lose signal in the middle of a job.
- **A permanent refusal must leave the queue.** A write the server will refuse
  identically forever sits at the head of an ordered outbox and stops
  everything behind it — a queue that looks busy and delivers nothing. Only
  `unreachable` is retried.
- **And it is never dropped silently.** Somebody believes that change happened,
  so refusals surface on the profile with the reason.
- **The server assigns the time.** A device's clock is somebody's phone.
  `madeAt` orders the queue and never decides which write wins.

Turn the connection off from **Profile → Backend** to see all of it.

### The app (`code/frontend/`)

Flutter, targeting Android and iOS, with web enabled so the POC can be
demonstrated in a browser and deployed to GitHub Pages.

**POC: Sprints 0–13 complete.** A person can open the app, see nearby jobs on
a map, tap a marker, listen to a voice note, view photos, post a job, and see
it appear immediately — with no internet, no login and no backend. That is the
success criteria from
[`documents/agile/sprint-planning/poc-sprint-plan.md`](documents/agile/sprint-planning/poc-sprint-plan.md),
with the exception noted under *Map tiles* below.

**Phase 1: P1-1 to P1-7 complete, plus P1-8a and P1-9**, per
[`documents/agile/sprint-planning/phase-1-sprint-plan.md`](documents/agile/sprint-planning/phase-1-sprint-plan.md).
Roles, the fixed tag vocabulary, the visibility rule that decides which jobs
reach which worker, Mode A bidding — a starting fare, counter-offers, and a
fare locked when the hirer chooses — the job's life from posted to finished
including the mutual location reveal on acceptance, the token wallet that
takes the platform's 5%, mutual rating with the worker's record public and the
hirer's kept internal, and Mode B — a premium directory of workers at fixed
prices, booked directly rather than bid on, and an admin panel whose every
action lands in an audit log. P1-8a settles the PostgreSQL schema those rules
will run on — see [The schema](#the-schema-codebackend) — and P1-9 adds
verification: a CNIC stored masked, a phone confirmed by code, and the
CNIC-SIM name comparison. P1-8b moves the repositories onto the schema.

**Two ways to find work.** *Mode A* is the map: a hirer posts, workers offer,
the hirer chooses, and the fare locks. *Mode B* is the directory: a worker pays
to be listed, publishes a menu at fixed prices, and a hirer books one of them
directly — no bidding, and the booking reaches that one worker rather than
being broadcast. Booking in the app is 2.5% cheaper than the worker's own
price, funded out of the platform's commission rather than the worker's
earnings, so that using Trust Hire beats ringing somebody you found on it.

**Both modes are location-first.** The map only shows a worker jobs within
reach of them; the directory only shows a hirer workers who would travel to
them, measured from a base on each listing against the radius that worker set.
That second half is newer than it looks — the rule existed and was tested from
P1-6, but nothing recorded where a worker was, so for two sprints it excluded
nobody. A hirer can still ask to see everyone, and a hirer who has declined
location sees everyone by default: **declining a permission should cost you
sorting, not access.**

**The app tells you what happened.** Activity leads with a feed of everything
that concerns you — offers in and decided, work started and finished, ratings,
commission, the debt lockout, a listing about to lapse — and the navigation
destination carries a count. **It is derived, never recorded**: a pure function
over the jobs, bids, ratings and ledger already stored, rather than an event
table each controller has to remember to append to. A write nobody makes is
invisible, and this repository has been caught by that three times. The trade
is that there is no per-entry read state, only "seen up to here".

The filter deciding who hears about a job is the whole privacy boundary — the
feed is built from *every* job and bid on the device, because that is all a
local-first app has — so it carries a mutation in the sweep.

**Demo accounts.** There is no sign-in — Section 13a excludes authentication
from the POC — but the device can be any of seven people, switched from the map
header, the app bar or the profile screen. Switching changes who owns which
job, whose offers are yours, whose wallet is charged and which trades filter
the feed, which is the only way to see bidding, the job lifecycle and mutual
ratings work end to end on one device.

Five of the others come from the seed, one per city, and are deliberately
unlike each other so a demonstration can reach every state without editing
storage by hand. The last is the platform itself:

| Account | For showing |
| --- | --- |
| **Hina Butt**, Islamabad | The hirer's side. Postings with offers waiting, one finished, one called off. |
| **Usman Raza**, Lahore | A busy worker: paid up, well rated, offers won and lost. |
| **Bilal Awan**, Karachi | **Locked out** by debt — two unpaid commissions, so bidding refuses and says why. |
| **Shahid Siddiqui**, Peshawar | Nearly new. One job done, the first-job credit still in the ledger. |
| **Sadia Iqbal**, Mardan | The generalist, with the widest feed of the five. |
| **Trust Hire staff** | The admin panel. Not a person in the seed, and the only account that has it. |

They are not accounts: no password, no verification, no privacy between them,
and everything shares one browser's storage. The device account is left clean
on purpose — it is what a first-time user sees.

**Verification, and what it does not mean.** From the profile, a worker can
submit a CNIC and confirm a phone. Three things about it are worth knowing
before changing anything there, because all three are easy to undo by accident:

- **The whole CNIC number never reaches storage.** `VerificationRules.mask` is
  the only thing that produces a stored number, and it returns null rather than
  falling back for anything it cannot parse — so there is no path that keeps a
  complete national identity number. `verification_test.dart` fails if one ever
  reaches `shared_preferences`.
- **Delivery is the only simulated part, and the screen says so.** There is no
  SMS provider until P1-8b, so `DemoSmsSender` shows the message it would have
  sent under a line explaining that. The expiry, the five attempts, the resend
  wait and the normalisation are all real. **Do not remove that line without
  removing the simulation.**
- **Every claim is shown with what it does not establish.** `describeLimits`
  returns the caveats a screen has to be displaying, so they travel with the
  signal rather than being layout somebody can delete. "Verified" over a check
  that only confirms a number is thirteen digits long is the most misleading
  thing this app could say.

```
code/frontend/
├── lib/
│   ├── app/          ← app root, shell, controllers
│   ├── core/         ← brand tokens, theme, breakpoints, formatters
│   ├── features/
│   │   ├── map/          ← the map — the primary surface, and its overlays
│   │   ├── jobs/         ← job list, details, saved and posted
│   │   ├── create_job/   ← posting and editing
│   │   ├── feed/         ← the visibility rule: which jobs reach whom
│   │   ├── bidding/      ← offers, and the hirer's choice
│   │   ├── lifecycle/    ← a job's statuses and the location reveal
│   │   ├── ratings/      ← mutual rating, and a worker's public record
│   │   ├── directory/    ← Mode B: listings, service menus, direct booking
│   │   ├── premium/      ← subscriptions and the hirer discount, as rules
│   │   ├── admin/        ← approvals, disputes, overrides and the audit log
│   │   ├── verification/ ← Section 2: the CNIC, the phone, the name check
│   │   ├── notifications/← the derived feed: what happened, to whom
│   │   ├── sync/         ← the outbox, and who wins when copies disagree
│   │   ├── wallet/       ← tokens, commission, top-up
│   │   ├── account/      ← the demo account switcher
│   │   ├── profile/      ← role, trades, and the app's settings
│   │   └── onboarding/   ← first-run intro and permission priming
│   ├── l10n/         ← app_en.arb, app_ur.arb (generated AppStrings)
│   ├── models/       ← Job, JobTag, Bid, Wallet, Rating, DemoAccount,
│   │                    listings, Verification
│   ├── services/     ← local storage, seed loading, repositories
│   │   └── backend/  ← the RemoteApi seam, and the mock behind it
│   └── widgets/      ← shared UI (status pills, skeletons, empty states,
│                        meta chips, fading scroll rows)
├── assets/
│   ├── seed/         ← jobs, users, offers, ratings, accounts, directory, admin
│   ├── images/       ← placeholder job photos
│   ├── audio/        ← placeholder voice notes
│   └── fonts/        ← Inter, Noto Sans Arabic, Noto Nastaliq Urdu
├── web/              ← the web shell: metadata, manifest, boot screen, icons
├── test/
└── tool/             ← dev scripts (seed data, assets, icons, the test sweep)
```

**The seed data.** `assets/seed/` holds 183 jobs across 25 Pakistani cities and
the past that goes with them — offers, winners, passed-over offers, ratings,
and a role, trades and wallet for each demo account. All of it is generated by
`python3 tool/generate_seed_jobs.py` from fixed random seeds, so the demo is
identical on every machine and a diff to that script is the only thing that
changes it. **Edit the script, not the JSON.**

The script runs in two phases on two seeds. The first builds the jobs and the
people; the second gives them a history. Keeping them apart means regenerating
the history leaves every job where it was, posted by the same person — so the
five names pinned in `DemoAccounts.roster` stay correct.

Five things to know if you grow it further:

- **Read it through `SeedLoader`**, which decodes the bytes itself.
  `rootBundle.loadString` sends anything over 50 KB to a background isolate
  that never returns inside `testWidgets`, and the seed is well past that.
- **Seeding happens in `bootstrap()`, before the first frame.** Not inside a
  controller: four controllers read their keys the moment they are
  constructed, and they will race a seed that lands later. Tests that pump the
  whole app call the same function.
- **Select jobs by property, not by id.** `seed-001` is whatever the generator
  put there this time.
- **Keep it coherent.** A demo that contradicts its own rules teaches the
  wrong thing, so the generator only gives a persona offers on work Section 8
  would have shown them, and `test/demo_history_test.dart` checks the
  agreements — accepted fare against the bid behind it, ratings only on
  finished work, every commission 5% of a real agreed fare.
- **Ask whether it can be *reached*, not only whether it is coherent.** The
  history pass draws from jobs posted by other people, so for three sprints
  the demo accounts' own postings had no offers on them at all — the hirer's
  side of Mode A was unreachable from four of the five accounts while every
  coherence test passed. There is now a test per persona for offers, a
  finished-and-rated posting, and more than one state.

**Restoring the seed reloads eight controllers.** Everything `DemoSeed` writes
is already held in memory somewhere, so the reset handler in `profile_screen.dart`
has to re-read all of it — otherwise the app shows a restored map beside stale
balances, and the next write puts the stale ones back. `demo_history_test.dart`
fails if the seed grows a key that list does not cover.

**The web shell.** `web/index.html` and `web/manifest.json` are the product's
only presence outside the app — the browser tab, the shared link, the installed
icon, and everything a crawler that does not run JavaScript can see. They are
deliberately not Flutter's defaults, and `test/web_shell_test.dart` fails if
they drift back. Regenerate the icons with `python3 tool/generate_app_icons.py`
after any change to the mark.

**Running it**

```bash
cd code/frontend
flutter pub get
flutter run                    # device or emulator
flutter run -d chrome          # browser
```

**Versioning.** The app version lives in `pubspec.yaml` (`version:`) and is
mirrored in `lib/core/app_version.dart`, which is what the app displays — at
the foot of the settings screen and at the bottom of the post/edit job form.
**Raise both on every push that changes the app**: patch for a fix, minor for
a completed sprint, and the build number after the `+` every time. The
deployed web app is served from a URL with no commit in it, so without a
visible version a stale cache and a failed deploy look identical.
`test/version_test.dart` fails the build if the two ever disagree.

**Layout.** Navigation follows Material's window size classes, with one
departure: **a rail needs height as well as width.** Below 520px the bottom bar
is used however wide the window is, because five labelled destinations plus the
posting action is about 450px of rail — and on a phone held sideways the last
destination fell below the fold with nothing on screen to say the rail
scrolled. `LayoutSize.fromSize` is where that lives.

**Checks**

```bash
flutter analyze
flutter test
python3 tool/sweep_tests.py     # minutes — run it when a rule changes
```

The first two gate the deploy.

**`sweep_tests.py` asks whether the tests test anything.** `flutter test`
proves the app behaves as the suite describes; it cannot prove the suite
describes anything, because a check aimed at a case that also violates a
neighbouring rule passes whether or not the rule it names still exists. The
sweep breaks each of the 34 load-bearing promises in turn — the fare lock, the
5% commission, the debt lockout, the ratings asymmetry, the visibility rule,
the location reveal, the CNIC mask, the audit log's write-first ordering — and
reports any the suite does not notice. Four survived — two on the first run and
two more when the list was widened — and every one was a real gap rather than
noise.

Its sibling for the schema is `code/backend/tool/sweep_schema.sh`, which found
two vacuous SQL checks the same way. **If you add a rule that decides money,
visibility, or who sees somebody's identity document, add a mutation for it.**
A promise nothing can break is a promise nothing is holding up. **And run the
mutation before believing the test** — one written to protect the meta chip's
width cap asserted the chip was no wider than the constant being mutated, so it
passed with the cap set to infinity. A test whose subject is also its expected
value measures nothing.

The suite includes an accessibility audit
(`test/accessibility_test.dart`) that runs Flutter's tap-target, semantic-label
and text-contrast guidelines against the live app, and checks the palette's
contrast ratios against WCAG AA — so a regression there fails the build rather
than shipping.

**`test/surfaces_test.dart` runs every screen at six window shapes, in both
themes and both languages.** It asserts almost nothing about what is on screen
— that is each feature's own test file's job — only that every combination
renders without throwing, which in a debug build means without overflowing, and
that every navigation destination can still be reached. It exists because four
bugs shipped while the suite was green: every test ran at one of two sizes, in
one theme, in one language, and the bugs were in between. **If a screen only
works at 390×844 in English, this is the file that says so.**

**Building for the web** — CanvasKit must be bundled rather than fetched from a
CDN, or the app will not load without third-party network access:

```bash
flutter build web --release --no-web-resources-cdn --base-href /Trust-Hire/
```

**Looking at the running app.** Every integration bug in Phase 1 was found by
looking at the app rather than by a failing test, so this is worth doing before
closing a sprint — and worth not re-deriving each time, because four things
about it are counter-intuitive:

```bash
# 1. --base-href means the build must be served *under that path*, not at /.
#    Serving build/web at the root gives a boot screen that never advances and
#    a 404 for flutter_bootstrap.js, which looks exactly like a broken build.
mkdir -p /tmp/serve && ln -sfn "$PWD/build/web" /tmp/serve/Trust-Hire
python3 -m http.server 8099 --directory /tmp/serve
# → http://localhost:8099/Trust-Hire/
```

- **Give it 10–15 seconds.** CanvasKit is bundled rather than fetched, and the
  boot screen sits there for a long time before the first frame.
- **Flutter renders to a canvas, so there is no text to select.** Playwright's
  `getByText` finds nothing and clicks silently do nothing — drive it with
  `page.mouse.click(x, y)` read off a screenshot, and re-screenshot after each
  step rather than assuming a click landed.
- **Tiles never render in a sandbox** that blocks outbound image requests. The
  map still positions its pins correctly over a plain background; a blank
  basemap in a screenshot is the network, not the app.

**Map tiles.** The map uses CARTO's Positron and Dark Matter basemaps — one
purpose-built style per brightness rather than a filter over a shared raster,
since darkening a standard map produces muddy greens and hurts label
legibility. Neither needs an API key, so the app runs from a fresh checkout
with no setup. That is fine for a POC but not for production traffic; a real
deployment needs a paid or self-hosted tile provider. Tiles are the one
part of the app that needs a network: everything else works offline, and when
tiles cannot be fetched the map still positions jobs correctly over a plain
background and says so.

**Placeholder assets.** The bundled job photos and voice notes are generated,
not real: `python3 tool/generate_placeholder_assets.py` rebuilds them. Photos
are brand-palette graphics rather than stock photography, which section 16 of
the brand guidelines rules out; voice notes are amplitude-modulated tones, not
speech, and exist so playback and the waveform can be demonstrated.

### Code conventions

- **Reference the brand tokens, never hard-coded values.** `lib/core/tokens.dart`
  is the Dart equivalent of section 31 of the brand guidelines and is the only
  place colour, radius, type and motion values are written down.
- **Missing information is acceptable.** A job is postable with a voice note
  alone, a photo alone, or a title alone — do not add required fields.
- **No network calls in the POC.** Everything runs against local storage;
  seed data is copied in on first run and edited locally from then on.
- **No secrets in the repository.** Commit a `.env.example` listing required
  variables when a backend arrives. Anything shipped to a client is public.
- **Treat candidate and employer data as sensitive** — never log it.
- **Accessibility is a requirement, not a polish step** — 44px minimum touch
  targets, 16px body text, and the contrast ratios in the brand guidelines.
  Colour is never the only indicator of state.

Requirements driving the code live in `documents/product/`; the stories
implementing them live in `documents/agile/backlog/`.

---

## Deployment

`deployment/` holds deployment configuration and any assets that ship with a
deployment but are not application source. It is currently empty: the Flutter
app is the deployment, and the placeholder site it used to hold was removed
once that app existed.

The workflow itself lives at `.github/workflows/deploy-pages.yml` — GitHub only
runs workflows from `.github/workflows/`, so it cannot sit inside `deployment/`.

### GitHub Pages

Every push to `main` deploys the app (and it can be run manually from the
Actions tab). The workflow sets up Flutter, runs `flutter analyze` and
`flutter test` as gates, then builds the web release and publishes it — so a
failing analyzer or test blocks the deploy rather than shipping past it.

The build passes `--no-web-resources-cdn` so CanvasKit is served from the
deployment itself rather than gstatic, and `--base-href /Trust-Hire/` because
project Pages sites are served from `/<repo>/`, not the domain root.

**One-time setup:** in **Settings → Pages**, set **Source** to **GitHub
Actions**. Until that is done the workflow builds but the deploy step fails.

---

## Working with AI agents

Three entry-point files are read automatically by AI coding tools. They all say
the same two things — *read this README before starting, and keep it up to date*
— and point at [`AGENTS.md`](AGENTS.md), which holds the full instructions.

| File | Read by |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | The canonical instructions; the cross-tool standard |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code, automatically at session start |
| [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | GitHub Copilot |

Keep them in sync: `AGENTS.md` carries the detail, the other two stay short
pointers.

### Claude Code setup

`.claude/settings.json` registers the `anthropics/claude-code` plugin
marketplace and enables the plugins below, so anyone who clones the repo picks
up the same tooling.

| Plugin | Version | What it provides |
| --- | --- | --- |
| `feature-dev` | 1.0.0 | Guided feature development — explore, clarify, design, implement |
| `code-review` | 1.0.0 | Multi-agent review of a pull request with confidence-based filtering |
| `commit-commands` | 1.0.0 | Git commit, push, and PR workflows |
| `security-guidance` | 2.0.0 | Security warnings while editing, plus a diff-based review pass |

**Slash commands**

| Command | Plugin | Purpose |
| --- | --- | --- |
| `/feature-dev [description]` | feature-dev | Systematic feature build: understand the codebase, ask about ambiguities, design the architecture, then implement |
| `/code-review` | code-review | Review a pull request and post findings |
| `/commit` | commit-commands | Stage and create a well-formed commit |
| `/commit-push-pr` | commit-commands | Commit, push the branch, and open a PR |
| `/clean_gone` | commit-commands | Delete local branches whose remote is gone, and their worktrees |

**Agents** — from `feature-dev`, used by `/feature-dev` or invoked by name:

| Agent | Role |
| --- | --- |
| `code-explorer` | Traces how an existing feature works — execution paths, architecture layers, dependencies |
| `code-architect` | Produces an implementation blueprint: files to create/modify, component design, data flow, build order |
| `code-reviewer` | Reviews for bugs, logic errors, security issues, and convention drift; filters by confidence to cut false positives |

**Hooks** — `security-guidance` runs automatically, no command needed. It warns
about likely security problems as files are edited, reinforces security context
on each prompt, and runs a git-diff-based review when a turn ends.

**Skills** load on demand when a task matches. `docx`, `pdf`, `pptx`, and `xlsx`
are the ones most relevant to `documents/` — they let Claude read and produce
Word, PDF, PowerPoint, and Excel files directly. `dataviz` covers charts and
dashboards; `artifact-design` covers shareable HTML pages.

> Plugin commands and hooks register at session start. After changing
> `.claude/settings.json`, restart the session before new commands appear.

---

## Contributing

1. Work on a branch, not directly on `main`.
2. Put documentation in the matching `documents/` subfolder, code under
   `code/backend/` or `code/frontend/`, deployment config under `deployment/`.
3. **Update this README in the same change** if you add, remove, or repurpose a
   folder, change a convention, or choose a stack.
4. Add an entry to [`CHANGELOG.md`](CHANGELOG.md) under `[Unreleased]`.
5. Run `/code-review` before opening a pull request.
