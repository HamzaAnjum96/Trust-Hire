# Brand guidelines

The single source of truth for how Trust-Hire looks and sounds. Anything
user-facing — the product UI, the marketing site, a pitch deck — should be
traceable back to this folder.

## What belongs here

| Topic | Typical file |
| --- | --- |
| Logo usage — clear space, minimum size, what not to do | `logo.md` + asset files |
| Colour palette — hex, RGB, usage rules, accessible pairings | `colour-palette.md` |
| Typography — typefaces, weights, type scale | `typography.md` |
| Tone of voice — how we write, words we use and avoid | `tone-of-voice.md` |
| Imagery and iconography | `imagery.md` |
| Asset library — logo files, icons, templates | `assets/` |

## Conventions

- Record colours with their **hex value and intended use** ("primary action",
  "error state"), not just a swatch. Note the contrast ratio for any pairing
  used for text.
- Keep source assets (`.svg`, layered files) alongside exports so they can be
  regenerated.
- When a guideline changes, note it in the top-level
  [`CHANGELOG.md`](../../CHANGELOG.md) — downstream work depends on these.

The implementation of these guidelines in code (design tokens, theme files)
lives in [`../../code/frontend/`](../../code/frontend/) and should reference
this folder rather than restating it.
