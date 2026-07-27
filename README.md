# Trust-Hire

Proof of concept for Trust Hire.

This repository holds both the product documentation and the application code.
Documentation lives under [`documents/`](#documents), code lives under
[`code/`](#code), and every notable change is recorded in
[`CHANGELOG.md`](CHANGELOG.md).

---

## Project structure

```
Trust-Hire/
├── README.md                     ← you are here
├── CHANGELOG.md                  ← running log of notable changes
├── .claude/
│   └── settings.json             ← Claude Code marketplace + enabled plugins
│
├── documents/                    ← all non-code project documentation
│   ├── agile/
│   │   ├── sprint-planning/      ← sprint goals, capacity, sprint boards
│   │   ├── backlog/              ← epics, user stories, acceptance criteria
│   │   └── retrospectives/       ← retro notes and follow-up actions
│   ├── brand-guidelines/         ← logo, colour, typography, tone of voice
│   ├── product/                  ← PRDs, requirements, roadmap, personas
│   ├── design/                   ← wireframes, UX flows, design-system notes
│   ├── research/                 ← market/user research, competitor analysis
│   └── meeting-notes/            ← dated notes and decisions
│
└── code/                         ← all application source
    ├── backend/                  ← API, services, data layer
    └── frontend/                 ← web client / UI
```

Each folder carries its own `README.md` describing what belongs in it and the
naming convention to follow. Read the local `README.md` before adding files.

### Documents

`documents/` is the single home for everything that is not source code. It is
split by *purpose* rather than by author or date, so a document's location tells
you what it is for.

| Folder | Contents |
| --- | --- |
| `agile/sprint-planning/` | Sprint goals, capacity plans, sprint boards, definitions of done |
| `agile/backlog/` | Epics, user stories, acceptance criteria, prioritisation |
| `agile/retrospectives/` | Retrospective notes and the actions arising from them |
| `brand-guidelines/` | Logo usage, colour palette, typography, tone of voice, asset library |
| `product/` | PRDs, requirement specs, roadmap, personas, success metrics |
| `design/` | Wireframes, mockups, UX flows, design-system decisions |
| `research/` | Market research, user interviews, competitor analysis |
| `meeting-notes/` | Dated meeting notes and the decisions that came out of them |

Convention: Markdown for anything text-based, so it reviews cleanly in a diff.
Binary assets (images, PDFs, Figma exports) sit alongside the Markdown that
references them.

### Code

`code/` holds the application itself, separated into two independently
runnable halves.

| Folder | Contents |
| --- | --- |
| `code/backend/` | API layer, business logic, data access, migrations, backend tests |
| `code/frontend/` | Web client, components, styling, frontend tests |

Each half owns its own dependency manifest, configuration, and test suite —
they are not expected to share a build. Stack choices are recorded in
`CHANGELOG.md` as they are made.

---

## Claude Code setup

The repository is configured for [Claude Code](https://claude.com/claude-code).
`.claude/settings.json` registers the `anthropics/claude-code` plugin
marketplace and enables the plugins below, so anyone who clones the repo picks
up the same tooling automatically.

### Enabled plugins

| Plugin | Version | What it provides |
| --- | --- | --- |
| `feature-dev` | 1.0.0 | Guided feature development — explore, clarify, design, implement |
| `code-review` | 1.0.0 | Multi-agent review of a pull request with confidence-based filtering |
| `commit-commands` | 1.0.0 | Git commit, push, and PR workflows |
| `security-guidance` | 2.0.0 | Security warnings while editing, plus a diff-based review pass |

### Slash commands

| Command | Plugin | Purpose |
| --- | --- | --- |
| `/feature-dev [description]` | feature-dev | Systematic feature build: understand the codebase, ask about ambiguities, design the architecture, then implement |
| `/code-review` | code-review | Review a pull request and post findings |
| `/commit` | commit-commands | Stage and create a well-formed commit |
| `/commit-push-pr` | commit-commands | Commit, push the branch, and open a PR |
| `/clean_gone` | commit-commands | Delete local branches whose remote is gone, and their worktrees |

### Agents

Provided by `feature-dev`, and invoked by the `/feature-dev` workflow or
directly by name:

| Agent | Role |
| --- | --- |
| `code-explorer` | Traces how an existing feature works — execution paths, architecture layers, dependencies |
| `code-architect` | Produces an implementation blueprint: files to create/modify, component design, data flow, build order |
| `code-reviewer` | Reviews for bugs, logic errors, security issues, and convention drift; filters by confidence to cut false positives |

### Hooks

`security-guidance` runs automatically — no command needed. It warns about
likely security problems as files are edited (`PostToolUse`), reinforces
security context on each prompt (`UserPromptSubmit`), and runs a git-diff-based
review when a turn ends.

### Skills

Skills load on demand when a task matches them. Document-handling skills
(`docx`, `pdf`, `pptx`, `xlsx`) are the ones most relevant to `documents/` —
they let Claude read and produce Word, PDF, PowerPoint, and Excel files
directly. `dataviz` covers charts and dashboards; `artifact-design` covers
shareable HTML pages.

> **Note:** plugin commands and hooks register at session start. After changing
> `.claude/settings.json`, restart the Claude Code session before the new
> commands become available.

---

## Contributing

1. Work on a branch, not directly on `main`.
2. Put documentation in the matching `documents/` subfolder — check that
   folder's `README.md` for the naming convention.
3. Put code under `code/backend/` or `code/frontend/`.
4. Add an entry to `CHANGELOG.md` under `[Unreleased]` for anything notable.
5. Run `/code-review` before opening a pull request.
