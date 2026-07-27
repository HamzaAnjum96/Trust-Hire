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
- Per-folder `README.md` files describing what belongs in each directory and
  the naming convention to use.
- Claude Code configuration in `.claude/settings.json`: registers the
  `anthropics/claude-code` plugin marketplace and enables the `feature-dev`,
  `code-review`, `commit-commands`, and `security-guidance` plugins.
