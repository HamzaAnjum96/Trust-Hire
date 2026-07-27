# Changelog

All notable changes to Trust-Hire are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once it reaches a first release.

Group entries under `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, or
`Security`. New work goes under `[Unreleased]`; when a version ships, rename
that heading to the version and date, and open a fresh `[Unreleased]`.

## [Unreleased]

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
