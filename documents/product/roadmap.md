# Roadmap

Themes and rough sequencing, not dated commitments. Sprints 0–6 delivered the
POC defined in
[`../agile/sprint-planning/poc-sprint-plan.md`](../agile/sprint-planning/poc-sprint-plan.md);
everything below is what comes after, in the order it is worth doing.

## Where we are

The POC succeeds against its own success criteria: a person can open the app,
see nearby jobs on a map, tap a marker, listen to a voice note, view photos,
post a job, and see it appear immediately — with no internet, no login and no
backend.

| Sprint | Delivered |
| --- | --- |
| 0 | Repository, brand theme, seed data, navigation |
| 1 | Map with job markers and current location |
| 2 | Job details — gallery, voice playback, area preview |
| 3 | Posting, with no required fields |
| 4 | Editing and deleting |
| 5 | Search and filters |
| 6 | Motion, loading states, accessibility audit |

## Next — still no backend

These extend the POC without breaking its constraint that everything runs
on-device. They are worth doing before a backend because each sharpens the
concept being validated, and none of them is wasted work once one exists.

**Sprint 7 — Job types.** A type on each job, chosen by the poster, driving
the marker icon. Kept optional: the brand guidelines want categories inferred
rather than demanded, so skipping it falls back to inferring from content.
Seed data moves to Islamabad, Rawalpindi and Kashmir.

**Sprint 8 — Map at scale.** Clustering, deferred as optional in Sprint 1 and
now needed: with jobs spread from Islamabad to Muzaffarabad, a single pin per
job stops being readable. Adds fit-to-jobs so nothing is stranded off-screen.

**Sprint 9 — Urdu and RTL.** The brand guidelines specify Noto Nastaliq Urdu
and call for mixed English/Urdu interfaces; section 29 lists them among the
accessibility requirements. For this audience it is closer to a requirement
than a feature, and it is the largest remaining gap between the POC and
something testable with real users.

**Sprint 10 — Contacting the poster.** The POC stops at *finding* work, which
makes it impossible to test whether anyone would act on it. A phone-call or
WhatsApp hand-off needs no backend and closes the loop end to end.

## Then — validate before building the backend

The sprint plan's post-POC list is long, and most of it presumes the concept
is proven. It is not yet. The cheapest next step is user testing on the POC —
particularly whether voice-first posting works for people who do not fill in
forms, which is the whole premise.

Order the backend work by what testing shows, but the likely sequence is:

1. **Cloud backend and sync** — jobs shared between devices. Nothing else on
   this list works without it.
2. **Accounts** — the minimum needed to attribute a posting, not full profiles.
3. **Messaging or call hand-off at scale**, replacing the direct hand-off.
4. **Moderation** — before any open posting, not after. A hiring product with
   unmoderated free text is a liability.
5. **Ratings and profiles** for workers and employers.
6. **Payments.**

## Deliberately deferred

- **AI-assisted posting** (voice transcription, summaries, smart categories).
  Compelling in a demo, but it needs real recordings in the target languages
  and accents to be worth anything, and those only exist after user testing.
- **Push notifications and real-time updates.** Both presume a backend and an
  audience that returns to the app; neither is true yet.
- **Analytics.** Worth adding with the backend, not before — there is nothing
  to measure while every install is isolated.

## Constraints that carry forward

- **Map tiles are the one thing needing a network.** Fine for a POC; a real
  deployment needs a paid or self-hosted tile provider rather than CARTO's
  public basemaps.
- **Local storage holds media as base64.** It works identically everywhere,
  which is why it was chosen, but it will not survive real photo volumes. A
  backend replaces it.
- **`code/backend/` is empty and stays that way** until the cloud work starts.
