# Changelog

All notable changes to Trust-Hire are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it reaches a first release.

Group entries under `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, or
`Security`. New work goes under `[Unreleased]`; when a version ships, rename
that heading to the version and date, and open a fresh `[Unreleased]`.

## [Unreleased]

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
