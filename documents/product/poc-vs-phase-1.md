# The POC and the Phase 1 spec — what agrees and what does not

Two documents now describe Trust Hire, and they are not describing the same
product:

- [`../agile/sprint-planning/poc-sprint-plan.md`](../agile/sprint-planning/poc-sprint-plan.md)
  — the POC that Sprints 0–12 actually built.
- [`phase-1-system-logic.md`](phase-1-system-logic.md) — a full system
  specification for an 8-week solo build.

This note reconciles them. It is written so that whoever decides what happens
next is deciding with the conflicts in front of them, rather than discovering
them halfway through a rebuild.

## The short version

The POC is a **demand-side discovery prototype**: see nearby work on a map,
understand it from voice and photos, post work without filling in a form. It
runs entirely on one device.

Phase 1 describes a **two-sided marketplace**: worker verification, bidding,
wallets, commission, premium subscriptions, ratings, and an admin panel, on a
Postgres backend.

The POC is closer to a *piece* of Phase 1 — roughly the hirer's posting flow
and the worker's discovery feed — than to a smaller version of it.

## Where they contradict each other

These are not gaps to fill in. They are decisions where the two documents say
different things, and only one can be true.

| Topic | POC plan (built) | Phase 1 spec |
| --- | --- | --- |
| **Framework** | Flutter | React Native |
| **Backend** | None, by design | Supabase / Postgres |
| **Accounts** | Explicitly excluded | Required — CNIC, SMS OTP, sign-up |
| **Money** | Out of scope | Wallet, 5% commission, subscriptions |
| **Categories** | *"Users never choose categories"* (brand guidelines) | Every job carries 1–3 tags from a fixed list; tags drive visibility |
| **Location** | Approximate area, always, both before and after | Distance only before acceptance; **exact address revealed after** |
| **Price** | Not modelled at all | Starting fare, bidding, locked on acceptance |
| **Platforms** | Android, iOS, web | Android only |

The framework line is the expensive one. Roughly 200 tests and thirteen
sprints of Flutter exist; none of it ports to React Native. Everything else in
the table is additive or a change of rule — that one is a rewrite.

Two others are worth pausing on because they are *product* contradictions, not
technical ones:

- **Categories.** The brand guidelines say users should never choose a
  category, and design principle 2 lists categories under what not to require.
  Phase 1 makes 1–3 tags mandatory on every job and builds the entire
  visibility model on them. The POC currently splits the difference — a type
  is offered and never demanded — but that compromise cannot survive if tags
  become the filtering mechanism.
- **Location privacy.** The POC tells the user, on every job and in the
  onboarding, that their exact location is never shown. Phase 1 reveals exact
  addresses to both parties after acceptance. That is a defensible design, but
  it makes the current copy untrue, and the copy is the thing users would have
  relied on.

## Where they agree

Worth noting, because it is most of the interesting part:

- Low literacy is a first-class constraint, and jobs are described by voice,
  photo or text.
- Location is central to discovery.
- Hyper-local, Pakistan-focused, trust-oriented.
- Media compression and retention matter for cost — the POC's base64 media
  store is already flagged as something a backend must replace.

The brand guidelines, the seed data, the Urdu translation, the accessibility
work and the copy carry over to either product. So does the domain thinking.

## What can be reused if Phase 1 proceeds as written

Even in a React Native rebuild, the following are not wasted:

- **The brand implementation.** `lib/core/tokens.dart` is a direct translation
  of section 31 and maps one-to-one onto the Tailwind theme in section 32.
- **The Urdu catalogue.** `lib/l10n/app_ur.arb` is ~190 translated strings,
  reusable as JSON with no Flutter dependency.
- **Every product decision recorded in `CHANGELOG.md`** — why untyped jobs are
  not hidden by a time filter, why the distance filter stands down without a
  position, why the contact number is hidden until asked for, why clustering
  works in screen space. Those are conclusions, not code.
- **The seed data** — 15 jobs across Islamabad, Rawalpindi and Kashmir.

## The open question

Nobody should rebuild in React Native, or keep extending the Flutter POC, on
an assumption. The choice is:

1. **Keep the POC as a POC.** It is finished and demonstrable; use it to test
   the voice-first premise with real users, and build Phase 1 separately.
2. **Treat Phase 1 as the real product** and stop investing in the POC.
3. **Bring Phase 1 to Flutter** — everything in the spec is buildable in
   Flutter, and it keeps thirteen sprints of work. The spec's React Native
   choice appears to be about cross-platform readiness, which Flutter also
   provides.

Option 3 deserves an explicit answer rather than a silent assumption, because
the spec names React Native specifically and may have reasons this note cannot
see.
