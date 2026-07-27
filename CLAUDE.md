# CLAUDE.md

**Read [`README.md`](README.md) in full before starting any work.** It documents
the folder structure, what belongs in each folder, the naming conventions, and
the available tooling. Do not create files or choose a location until you have.

**Keep `README.md` up to date as part of your change.** If you add, remove, or
repurpose a folder, change a convention, add or remove a plugin or command, or
pick a stack — update the README in the same commit. A change that leaves the
README describing the old structure is incomplete.

**Log notable changes in [`CHANGELOG.md`](CHANGELOG.md)** under `[Unreleased]`.
It is a separate top-level file; do not fold it into the README.

**Raise the app version on every push that changes the app** — `version:` in
`code/frontend/pubspec.yaml` *and* the constant in
`code/frontend/lib/core/app_version.dart`. They must agree; a test fails the
build if they do not. Without it, a stale cache and a failed deploy are
indistinguishable in the browser.

Full instructions, conventions, and the end-of-work checklist are in
[`AGENTS.md`](AGENTS.md) — read it alongside the README.
