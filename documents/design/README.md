# Design

Wireframes, mockups, UX flows, and design-system decisions.

## What belongs here

| Topic | Typical file |
| --- | --- |
| User flows and journeys | `flow-<slug>.md` |
| Wireframes and mockups | `wireframes/` + exported images |
| Design-system decisions — components, spacing, states | `design-system.md` |
| Accessibility decisions and targets | `accessibility.md` |

## Conventions

- Link out to the live design tool (Figma or equivalent) **and** commit a dated
  export. Links rot; exports are what future readers will actually have.
- Name exports with the date they were taken:
  `wireframes/2026-07-27-candidate-onboarding.png`.
- Record the *decision and its reasoning*, not only the picture. A mockup shows
  what was chosen; the Markdown should say why.

Visual identity — colour, type, logo — belongs in
[`../brand-guidelines/`](../brand-guidelines/), not here. This folder is about
structure, interaction, and behaviour.
