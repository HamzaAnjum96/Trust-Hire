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
| `agile/retrospectives/` | `sprint-NN-retro.md`, matching the sprint number. What went well, what did not, and **actions with named owners**. Carry unfinished actions forward explicitly. |
| `brand-guidelines/` | [`brand-guidelines.md`](documents/brand-guidelines/brand-guidelines.md) is the source of truth: positioning, the burgundy/copper/sand palette, typography, logo direction, iconography, map styling, voice and tone, component specs, motion, accessibility, dark mode, and design tokens. Anything user-facing should be traceable back to it. Add new colours with their hex value *and* intended use; keep source assets next to exports. |
| `product/` | [`roadmap.md`](documents/product/roadmap.md) sets out what comes after the POC. [`phase-1-system-logic.md`](documents/product/phase-1-system-logic.md) specifies a fuller two-sided marketplace, and [`poc-vs-phase-1.md`](documents/product/poc-vs-phase-1.md) reconciles the two — **read that before building against either**. [`ux-audit-response.md`](documents/product/ux-audit-response.md) answers the UI/UX audit finding by finding: done, scheduled, or declined with a reason. Alongside them: vision, PRDs (`prd-<slug>.md`), personas, success metrics. State non-goals as clearly as goals, and number requirements so backlog stories can reference them. |
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
| `code/backend/` | API layer, business logic, data access, migrations, backend tests. **Empty and out of scope for the POC**, which runs entirely on-device with no backend. Reserved for the post-POC cloud work. |

### The app (`code/frontend/`)

Flutter, targeting Android and iOS, with web enabled so the POC can be
demonstrated in a browser and deployed to GitHub Pages.

**POC: Sprints 0–13 complete.** A person can open the app, see nearby jobs on
a map, tap a marker, listen to a voice note, view photos, post a job, and see
it appear immediately — with no internet, no login and no backend. That is the
success criteria from
[`documents/agile/sprint-planning/poc-sprint-plan.md`](documents/agile/sprint-planning/poc-sprint-plan.md),
with the exception noted under *Map tiles* below.

**Phase 1: P1-1 and P1-2 complete**, per
[`documents/agile/sprint-planning/phase-1-sprint-plan.md`](documents/agile/sprint-planning/phase-1-sprint-plan.md).
Roles, the fixed tag vocabulary, the visibility rule that decides which jobs
reach which worker, and Mode A bidding — a starting fare, counter-offers, and
a fare locked when the hirer chooses. P1-3 onwards adds the job lifecycle,
wallets, ratings and the backend.

```
code/frontend/
├── lib/
│   ├── app/          ← app root, shell, controllers
│   ├── core/         ← brand tokens, theme, breakpoints, formatters
│   ├── features/
│   │   ├── map/          ← the map — the primary surface
│   │   ├── jobs/         ← job list, details, saved and posted
│   │   ├── create_job/   ← posting and editing
│   │   ├── feed/         ← the visibility rule: which jobs reach whom
│   │   ├── bidding/      ← offers, and the hirer's choice
│   │   ├── profile/      ← role, trades, and the app's settings
│   │   └── onboarding/   ← first-run intro and permission priming
│   ├── l10n/         ← app_en.arb, app_ur.arb (generated AppStrings)
│   ├── models/       ← Job, JobTag, Bid, WorkerProfile, AppUser
│   ├── services/     ← local storage, seed loading, repositories
│   └── widgets/      ← shared UI
├── assets/
│   ├── seed/         ← jobs.json, users.json — copied to local storage on first run
│   ├── images/       ← placeholder job photos
│   ├── audio/        ← placeholder voice notes
│   └── fonts/        ← Inter, Noto Sans Arabic, Noto Nastaliq Urdu
├── web/              ← the web shell: metadata, manifest, boot screen, icons
├── test/
└── tool/             ← dev scripts (seed data, placeholder assets, app icons)
```

**The seed data.** `assets/seed/` holds 183 jobs across 25 Pakistani cities,
generated by `python3 tool/generate_seed_jobs.py` from a fixed random seed —
the demo is identical on every machine, and a diff to that script is the only
thing that changes it. Edit the script, not the JSON.

Two things to know if you grow it further. Keep reading it through
`SeedLoader`, which decodes the bytes itself: `rootBundle.loadString` sends
anything over 50 KB to a background isolate that never returns inside
`testWidgets`, and the seed is well past that. And tests should select jobs by
property rather than by id — `seed-001` is whatever the generator put there
this time.

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

**Checks**

```bash
flutter analyze
flutter test
```

Both gate the deploy. The suite includes an accessibility audit
(`test/accessibility_test.dart`) that runs Flutter's tap-target, semantic-label
and text-contrast guidelines against the live app, and checks the palette's
contrast ratios against WCAG AA — so a regression there fails the build rather
than shipping.

**Building for the web** — CanvasKit must be bundled rather than fetched from a
CDN, or the app will not load without third-party network access:

```bash
flutter build web --release --no-web-resources-cdn --base-href /Trust-Hire/
```

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
