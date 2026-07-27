# Agent instructions

Instructions for any AI coding agent working in this repository. This is the
canonical file; `CLAUDE.md` and `.github/copilot-instructions.md` point here.

## Read the README first

**Before doing any work, read [`README.md`](README.md) in full.** It documents
the folder structure, what belongs where, the naming conventions, and the
Claude Code tooling available. Do not create files, choose a location, or start
implementing until you have read it — putting work in the wrong place is the
most common and most expensive mistake in this repository.

If the README contradicts these instructions, the README wins for anything
about structure and conventions. Say so rather than silently picking one.

## Keep the README up to date

**The README is part of the deliverable, not documentation written afterwards.**
Update it in the same change that makes it stale. Specifically, update
`README.md` whenever you:

- add, remove, rename, or repurpose a folder;
- change a naming or file-placement convention;
- add or remove a Claude Code plugin, command, agent, hook, or skill;
- choose a stack, framework, or major dependency for `code/backend` or
  `code/frontend`;
- change how the project is built, run, or deployed.

A change that alters the structure but leaves the README describing the old one
is an incomplete change. Treat it the same as leaving a test failing.

## Keep the changelog up to date

Notable changes go in [`CHANGELOG.md`](CHANGELOG.md) under `[Unreleased]`, in
the matching group (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`,
`Security`). The changelog lives in its own file — do not fold it into the
README.

## Bump the app version on every push

The frontend version lives in two places that must agree:

- `code/frontend/pubspec.yaml` — the `version:` line, the source of truth.
- `code/frontend/lib/core/app_version.dart` — the constant the app displays.

Raise both before pushing any change to the app. `code/frontend/test/version_test.dart`
fails if they disagree, so a mismatch stops the build rather than shipping a
number that names the wrong build.

- Patch (`0.2.1`) — fixes and small changes within a sprint.
- Minor (`0.3.0`) — a completed sprint.
- Major (`1.0.0`) — reserved for a first real release.

The build number after the `+` increments on every push and never resets.

This matters because the deployed web app is served from a URL with no commit
in it: without a visible version, a stale cache and a failed deploy look
identical. The number is shown at the foot of the settings screen and at the
bottom of the post/edit job form.

## Working conventions

- **Put things where the README says.** Documentation under `documents/`, in
  the subfolder matching its purpose; application source under `code/backend/`
  or `code/frontend/`; deployment configuration under `deployment/`.
- **Markdown by default** for documents, so they review cleanly in a diff.
- **Lowercase, hyphenated filenames.** Date-prefix anything time-bound as
  `YYYY-MM-DD-`.
- **No secrets in the repository.** Commit a `.env.example` listing required
  variables; never real values. Anything shipped to the browser is public.
- **Treat candidate and employer data as sensitive.** This is a hiring
  product — do not commit personal data, and do not log it.
- **Work on a branch** unless explicitly told otherwise, and run `/code-review`
  before opening a pull request.

## Before you finish

Check each of these:

1. Is the work in the folder the README says it belongs in?
2. Does `README.md` still describe the repository accurately?
3. Is there a `CHANGELOG.md` entry under `[Unreleased]`?
4. Has the app version been raised in **both** `pubspec.yaml` and
   `lib/core/app_version.dart`?
5. Are there any secrets, credentials, or personal data in the diff?
