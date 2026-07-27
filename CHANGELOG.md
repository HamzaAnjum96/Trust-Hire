# Changelog

All notable changes to Trust-Hire are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it reaches a first release.

Group entries under `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, or
`Security`. New work goes under `[Unreleased]`; when a version ships, rename
that heading to the version and date, and open a fresh `[Unreleased]`.

## [Unreleased]

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
