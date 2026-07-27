# Copilot instructions

**Read [`../README.md`](../README.md) in full before starting any work.** It
documents the folder structure, what belongs in each folder, the naming
conventions, and the available tooling.

**Keep the README up to date as part of your change** — if you add, remove, or
repurpose a folder, change a convention, or pick a stack, update `README.md` in
the same commit.

**Log notable changes in [`../CHANGELOG.md`](../CHANGELOG.md)** under
`[Unreleased]`.

**Raise the app version on every push that changes the app** — `version:` in
`code/frontend/pubspec.yaml` *and* the constant in
`code/frontend/lib/core/app_version.dart`. They must agree; a test fails the
build if they do not.

Full instructions and conventions are in [`../AGENTS.md`](../AGENTS.md).
