# Plan: applying the site design playbook to the app

Date: 2026-11-17 · Status: **plan only.** Nothing here is built, and nothing
is pushed until the owner says so.

Source: "Site design playbook: skills, lessons and patterns" (Hamza, Nov 2026),
written for a static marketing site. This plan keeps what transfers to a
Flutter app that people use for tasks, and drops the rest. It builds on the
0.23 redesign (`2026-11-04-redesign.md`).

## What transfers, and what does not

| Playbook idea | Here | Why |
| --- | --- | --- |
| Turn every rule into a token, a class or a test | **Yes** | The 0.23 rules (rows, not cards; one loud status; 12px floor; tracking 0) live in prose. One already broke: the map attribution is set at 10px (`job_map.dart:366`) |
| Three surfaces, hairline ring plus soft depth, radius by role | **Yes** | Matches the 0.23 ground, white and sheet. Needs tokens for it, not more style |
| The accent is rare: one accent button per screenful | **Yes** | A hirer's offer list has a filled "Choose" on every offer |
| Switch or table | **Yes** | Choosing an offer sets a value, which is the radio-group job. Short parallel facts (a worker's record, the ledger) suit a table or fact bar |
| One motion curve | **Yes** | Two curves today, one of them a bounce (`easeOutBack`) |
| Claims register | **Yes, adapted** | Here the claims are promises in the interface ("The fare is fixed once you choose"), each kept true by a rule the sweep already tests |
| Product context file before copy | **Yes** | It also closes the review's PRODUCT.md finding, in this repo's place for it |
| Helper scripts for looking; check at 1440, 980, 768, 390 | **Yes** | The semantics-driven Playwright driver from 0.23 lives in a scratch folder; 980 is Chrome's "Desktop site" width on a phone |
| Fail on console and page errors; pin the CI runner | **Yes** | The deploy runs on `ubuntu-latest` |
| Vendor skills with licence and version | **Yes** | Two of the four skills have no licence file beside them |
| Respect the owner's push rules, whatever a hook asks | **Yes** | It has already come up once in this repository |
| Hero, fact-led editorial layout, motif, scroll reveals, word-by-word tagline, view transitions | No | Marketing-page devices. An app loads into a task |
| Works without JavaScript; no storage, cookies or third-party requests | No | Flutter needs script, and the app stores everything in the browser by design. Its network use is documented in the README |
| Tracked referral links, legal notice, 404, brochure | No | Nothing like them in this product |

## Ground rules for every package

1. A rule that can be code becomes code: a token, a shared widget or a test.
2. Content before pixels: the context file and the claims register come first.
3. Look at the rendered app at 390, 768, 980 and 1440 after each package,
   light and dark, English and Urdu, and record what was seen.
4. Assert words and roles in tests, not widget types, wherever a person would
   notice the difference.
5. Each package that changes the app raises the version in `pubspec.yaml` and
   `app_version.dart`, adds a CHANGELOG entry and keeps the README true.
6. `flutter analyze`, `flutter test` and `tool/sweep_tests.py` stay green.
7. Commit locally; push only on the owner's word.

## Decisions for the owner before copy work starts

1. **Casing of buttons.** Brand guidelines §21 lists Title Case calls to action
   ("Post a Job", "Save Job", "Edit Job"). The playbook asks for sentence
   case, and the menus already mix the two ("Edit Job" beside "Call this
   off"). Pick one; WP8 applies it.
2. **Em dashes in copy.** 22 English strings use them; the playbook bans them.
   Urdu strings follow their own punctuation either way.
3. **Choosing an offer.** WP3 turns the offers into a radio group with one
   pinned "Choose" button, the same shape as the worker's "Offer a fare" bar.
   It changes Stop 3 of the demo script.

## Work packages

In order. S is under an hour of work, M a few hours, L most of a day.

**WP1 · Vendor the skills properly (S).** Add the upstream licence files for
`ui-ux-pro-max` and `web-design-guidelines`, record each skill's version, and
add a credits line per skill in the README. *Done when* every skill folder
holds its licence.

**WP2 · Design rules as a test (M).** A `design_rules_test.dart` that scans
`lib/` and fails on:

- a `fontSize` below 12 or a `letterSpacing` set outside `tokens.dart`;
- `Colors.*` outside an allow-list;
- a `Card` or bordered box wrapping a `JobRow` or `InboxRow`;
- a curve other than `BrandMotion.curve`;
- `colorScheme.primary` used as a text colour instead of `accentText`.

Fix what it finds first: the attribution goes to 12px, or gets an exemption
that is written down with its reason. *Done when* each rule has been proven by
breaking it once (the sweep's discipline).

**WP3 · Accent discipline (M).** Audit every screen for more than one filled
burgundy control per screenful, the Post slot included. Known cases: the
offers list (a filled "Choose" per offer), and the map preview's "Open
details" beside the Post slot. Offers become a radio group: tap a row to
select it, then one pinned "Choose Rs. 2,500" bar. *Done when* each screen has
one accent action, and bidding and demo tests still pass.

**WP4 · Surfaces and depth as tokens (S).** Rename the shadows by role:
`card` is a hairline ring plus a soft drop, `lift` a ring plus a deeper drop,
for hover and press. Write the nesting rule down (inner radius = outer minus
the gap) and check the sheet's inner blocks against it. No raised surface on a
raised surface. *Done when* the depth styles come from these two tokens.

**WP5 · Tables and fact bars for short facts (M).** A worker's record
(rating, jobs finished, usual fare) becomes one fact bar: one card, three
cells, hairlines between them. The wallet ledger becomes a data table with
tabular figures and right-aligned amounts. Offers line their fares and
records up in columns (with WP3). *Done when* parallel facts read across, at
320px too.

**WP6 · One motion curve (S).** Replace `easeOutBack` and the other curves with
one, `Cubic(0.22, 1, 0.36, 1)`, and keep the three durations. Press feedback
(scale 0.98) and hover lift (with `lift`) apply on pointer devices only.
Reduced motion stays a fade or nothing. *Done when* WP2's curve rule passes.

**WP7 · Claims register (M).** `documents/product/claims.md` lists every
promise the interface makes, such as "The fare is fixed once you choose",
"Nothing is uploaded" and "The exact spot is shared once a worker is chosen".
Each entry gives its string key and the rule or sweep id that keeps it true.
A test fails if a listed key disappears or its rule id is not in the sweep.
*Done when* every promise sentence in `app_en.arb` is either in the register
or deliberately left out.

**WP8 · Product context file, then a copy pass (M).** Write
`documents/product/product-context.md`: users, situations, voice, allowed
claims (pointing to WP7) and banned phrases. Then run the `copy-editing`
approach over `app_en.arb` with the owner's decisions 1 and 2. Keep a before
and after audit file. Urdu changes go through a fluent reviewer, never a
machine rewrite. *Done when* the localisation tests pass and the audit is
committed.

**WP9 · Tools for looking (S).** Commit the semantics-driven Playwright driver
as `tool/look_web.js`, with presets for 1440, 980, 768 and 390, dark mode and
Urdu. Replace the README's "click by coordinates" advice with it. At 980,
check the layout Chrome on Android uses in "Desktop site" mode: a rail at
roughly 40% scale. *Done when* one command captures the standard set.

**WP10 · A web smoke test in CI (M).** After the build, load the site, wait
for the first frame, turn on semantics, visit each destination and open a
job. Fail on page errors, console errors and failed local requests. Pin the
runner from `ubuntu-latest` to a named release. *Done when* the deploy
workflow runs it before publishing.

**WP11 · Keyboard and focus (M).** Walk the web build by keyboard only. Check
for: a visible focus ring on the custom controls (the Post slot, the view
switch, the profile header, rows), arrow keys across tabs and segments, and
Escape on sheets and menus. Focus should return where it was. *Done when*
every control can be reached and seen with the keyboard, and a test pins the
custom ones.

**WP12 · Keep the brand file in step (S).** Add a "Design language" section to
the brand guidelines: surfaces, rows not cards, one loud status, accent text in
dark mode, the motion curve and the switch-or-table rule, each pointing to the
token or test that enforces it. *Done when* the guidelines describe the app as
built.

## Out of scope for now

- A visual reskin. The brand stays.
- Marketing-site devices (see the table above).
- Real backend work. None of this touches `code/backend/`.
