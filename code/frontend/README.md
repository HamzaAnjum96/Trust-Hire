# Frontend

Web client for Trust-Hire.

> Stack not yet chosen. Record the decision in the top-level
> [`CHANGELOG.md`](../../CHANGELOG.md) when it is, and replace this note with
> setup and run instructions.

## Expected layout

Adjust to whatever the chosen framework expects, but keep the separation:

```
frontend/
├── src/
│   ├── components/   ← reusable UI components
│   ├── pages/        ← routed views
│   ├── styles/       ← design tokens and global styling
│   ├── api/          ← backend client, typed
│   └── lib/          ← shared helpers
├── public/           ← static assets
├── tests/
└── .env.example      ← required variables, no real values
```

## Conventions

- **Design tokens come from the brand guidelines.** Colour, type, and spacing
  in `src/styles/` should implement
  [`../../documents/brand-guidelines/`](../../documents/brand-guidelines/)
  rather than restate it — one source of truth, referenced here.
- **All backend calls go through `src/api/`.** No `fetch` scattered through
  components.
- **Accessibility is a requirement, not a polish step** — semantic markup,
  keyboard reachability, and the contrast ratios recorded in the brand
  guidelines.
- **No secrets in frontend code.** Anything shipped to the browser is public;
  only non-sensitive configuration belongs in `.env.example`.
