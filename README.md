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
    └── pages/                    ← static site published to GitHub Pages
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
| `agile/sprint-planning/` | [`poc-sprint-plan.md`](documents/agile/sprint-planning/poc-sprint-plan.md) is the master plan for the POC — vision, goals, constraints, and Sprints 0–6. Alongside it, one document per sprint as it is planned in detail: sprint goal, committed scope, team capacity, risks and dependencies, definition of done. Name those `sprint-NN-planning.md`, zero-padded. |
| `agile/backlog/` | Epics (`epic-<slug>.md`) and user stories (`story-<slug>.md`) with testable acceptance criteria. A story is *ready* when its criteria are testable and its open questions are resolved — only ready stories get pulled into planning. |
| `agile/retrospectives/` | `sprint-NN-retro.md`, matching the sprint number. What went well, what did not, and **actions with named owners**. Carry unfinished actions forward explicitly. |
| `brand-guidelines/` | [`brand-guidelines.md`](documents/brand-guidelines/brand-guidelines.md) is the source of truth: positioning, the burgundy/copper/sand palette, typography, logo direction, iconography, map styling, voice and tone, component specs, motion, accessibility, dark mode, and design tokens. Anything user-facing should be traceable back to it. Add new colours with their hex value *and* intended use; keep source assets next to exports. |
| `product/` | Vision, roadmap, PRDs (`prd-<slug>.md`), personas, success metrics. State non-goals as clearly as goals, and number requirements so backlog stories can reference them. |
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
halves. Neither has a stack chosen yet — record the decision in
[`CHANGELOG.md`](CHANGELOG.md) when it is made, and document setup and run
steps here.

| Folder | What belongs in it |
| --- | --- |
| `code/backend/` | API layer, business logic, data access, migrations, backend tests. Keep business logic out of route handlers — handlers parse, delegate, and serialise, while services hold the decisions. Migrations are ordered, reversible, and never edited once merged. |
| `code/frontend/` | Web client, components, styling, frontend tests. All backend calls go through one API module, not `fetch` scattered through components. Design tokens implement `documents/brand-guidelines/` rather than restating it. |

### Code conventions

- **Each half owns its own dependency manifest, configuration, and test suite.**
  They are not expected to share a build or a lockfile.
- **The contract between them is the API.** The frontend consumes it; it does
  not reach into backend internals.
- **No secrets in the repository.** Commit a `.env.example` listing required
  variables, and supply real values at runtime. Anything shipped to the browser
  is public.
- **Validate every input at the boundary.** This product handles candidate and
  employer data — treat all of it as sensitive, and never log it.
- **Accessibility is a requirement, not a polish step** — semantic markup,
  keyboard reachability, and the contrast ratios in the brand guidelines.

Requirements driving the code live in `documents/product/`; the stories
implementing them live in `documents/agile/backlog/`.

---

## Deployment

`deployment/` holds deployment configuration and any assets that ship with a
deployment but are not application source.

| Path | Purpose |
| --- | --- |
| `deployment/pages/` | Static site published to GitHub Pages. Currently a placeholder page, served until a frontend exists. |

The workflow itself lives at `.github/workflows/deploy-pages.yml` — GitHub only
runs workflows from `.github/workflows/`, so it cannot sit inside `deployment/`.

### GitHub Pages

Every push to `main` deploys the site (and it can be run manually from the
Actions tab). The workflow adapts to the state of the project:

- **No `code/frontend/package.json`** → publishes `deployment/pages/` as-is.
- **Frontend present** → runs `npm ci` (or `npm install` without a lockfile)
  and `npm run build` in `code/frontend/`, then publishes the first build
  directory it finds among `dist`, `build`, `out`, `public`.

So the placeholder is served today and the real frontend takes over
automatically once one exists — no workflow edit needed, provided the frontend
has a `build` script.

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
