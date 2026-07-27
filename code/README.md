# Code

All application source, split into two independently runnable halves.

| Folder | Contents |
| --- | --- |
| [`backend/`](backend/) | API layer, business logic, data access, migrations, backend tests |
| [`frontend/`](frontend/) | Web client, components, styling, frontend tests |

## Conventions

- **Each half owns its own dependency manifest, configuration, and test
  suite.** They are not expected to share a build or a lockfile.
- **The contract between them is the API.** Keep it documented in
  `backend/`, and have the frontend consume it rather than reaching into
  backend internals.
- **No secrets in the repository.** Commit a `.env.example` listing the
  variables each half needs; keep real values out of git.
- **Record stack decisions.** When a framework, database, or major dependency
  is chosen, note it in the top-level [`CHANGELOG.md`](../CHANGELOG.md) with
  the reasoning.

Requirements that drive the code live in
[`../documents/product/`](../documents/product/); the stories implementing them
live in [`../documents/agile/backlog/`](../documents/agile/backlog/).
