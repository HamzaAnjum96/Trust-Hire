# Backend

API, business logic, and data layer for Trust-Hire.

> Stack not yet chosen. Record the decision in the top-level
> [`CHANGELOG.md`](../../CHANGELOG.md) when it is, and replace this note with
> setup and run instructions.

## Expected layout

Adjust to whatever the chosen framework expects, but keep the separation:

```
backend/
├── src/
│   ├── api/          ← route handlers / controllers
│   ├── services/     ← business logic
│   ├── models/       ← data models
│   └── lib/          ← shared helpers
├── migrations/       ← schema changes, ordered and reversible
├── tests/
└── .env.example      ← required variables, no real values
```

## Conventions

- **Business logic stays out of route handlers.** Handlers parse, delegate,
  and serialise; `services/` holds the decisions.
- **Migrations are ordered and reversible**, and never edited once merged.
- **Validate every input at the boundary.** This product handles candidate and
  employer data — treat all of it as sensitive, and never log it.
- **Secrets come from the environment**, listed in `.env.example` and supplied
  at runtime.
- Tests live in `tests/`, mirroring the `src/` layout.
