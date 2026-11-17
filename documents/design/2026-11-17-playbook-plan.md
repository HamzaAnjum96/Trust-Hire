# Plan: the site design playbook, applied, and a reskin

Date: 2026-11-17 · Status: **plan only.** Nothing here is built, and nothing
is pushed until the owner says so.

Source: "Site design playbook: skills, lessons and patterns" (Hamza, Nov 2026),
written for a static marketing site. This plan keeps what transfers to a
Flutter app that people use for tasks, and drops the rest. It builds on the
0.23 redesign (`2026-11-04-redesign.md`).

Two parts:

- **Part 1** applies the playbook's rules to the app as it looks now
  (WP1–WP12).
- **Part 2** is a **reskin**: a new visual world over the 0.23 structure
  (RS1–RS9).

Part 1 lays the ground Part 2 needs. Rules become tests, depth and motion
become tokens, and the product context gets written down. Part 2 then changes
the look without touching the structure.

## What transfers, and what does not

| Playbook idea | Here | Why |
| --- | --- | --- |
| Turn every rule into a token, a class or a test | **Yes** | The 0.23 rules (rows, not cards; one loud status; 12px floor; tracking 0) live in prose. One already broke: the map attribution is set at 10px (`job_map.dart:366`) |
| Three surfaces, hairline ring plus soft depth, radius by role | **Yes** | Matches the 0.23 ground, white and sheet. Needs tokens for it, not more style |
| The accent is rare: one accent button per screenful | **Yes** | A hirer's offer list has a filled "Choose" on every offer |
| Switch or table | **Yes** | Choosing an offer sets a value, which is the radio-group job. Short parallel facts (a worker's record, the ledger) suit a table or fact bar |
| One motion curve | **Yes** | Two curves today, one of them a bounce (`easeOutBack`) |
| Theme-neutral tokens named by role (page, raised surface, card, line, muted text, accent) | **Yes** | It makes a reskin a token swap. Today it is not one: features and shared widgets name brand colours directly 123 times, in 32 files |
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

## Decisions for the owner

Before the copy work (Part 1):

1. **Casing of buttons.** Brand guidelines §21 lists Title Case calls to action
   ("Post a Job", "Save Job", "Edit Job"). The playbook asks for sentence
   case, and the menus already mix the two ("Edit Job" beside "Call this
   off"). Pick one; WP8 applies it.
2. **Em dashes in copy.** 22 English strings use them; the playbook bans them.
   Urdu strings follow their own punctuation either way.
3. **Choosing an offer.** WP3 turns the offers into a radio group with one
   pinned "Choose" button, the same shape as the worker's "Offer a fare" bar.
   It changes Stop 3 of the demo script.

Before the reskin (Part 2):

4. **Evolve or replace.** Evolve keeps burgundy as the one recognisable
   colour and changes everything around it: neutrals, type, shape, depth,
   icons. Replace starts the palette over. Evolve keeps what evaluators and
   the app icon already carry; replace is the bigger visual gain and the
   bigger risk to recognition.
5. **What must not change.** Suggested fixed points:
   - the brand guidelines' "should not look like" list (§1);
   - no green-and-white "Pakistan-themed" look;
   - a voice note that looks different from everything else;
   - Urdu set in a face made for it.
   Confirm, add or remove.
6. **Picking the direction.** RS3 shows three directions and the plain "evolve
   what is there" option on Impeccable's decision page. The owner picks one,
   or steers and re-rolls. Nothing is built before that choice.

## Part 1: the playbook's rules

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

## Part 2: the reskin

**What it changes:**

- palette;
- type;
- depth and shape;
- iconography;
- map styling;
- illustration;
- the app icon and web shell.

**What it keeps:**

- the 0.23 structure: four destinations and one action, the map/list switch,
  rows not cards, one loud status style, the job sheet's order;
- every behaviour and rule;
- the accessibility floors: 44–48px targets, 16px body text, 12px minimum,
  AA contrast;
- full Urdu, right to left.

It is a brand change, so `documents/brand-guidelines/` moves to version 0.2 in
the same work. Release 0.24.0.

Impeccable runs this as a replacement world:

1. Product context first.
2. A concept roll and direction round.
3. A recorded direction contract.
4. A code-led build. An app screen is an *Operate* surface, so it is built in
   code rather than from an image comp.
5. A finish review.
6. DESIGN.md (here, the design-language section of the brand file) written
   from what shipped.

**RS1 · Role tokens, with no visual change (L).** Prerequisite for everything
below.

- Add a `ThemeExtension` of roles:
  - page, surface, raised, card, line;
  - strong and muted text;
  - accent, on-accent and accent text;
  - the status set: quiet, active, good, bad;
  - voice;
  - the map roles: pin, selected pin, own pin, radius, user.
- Move the 123 direct `BrandColours.*` uses in features and widgets onto those
  roles.
- Extend WP2 so a feature or widget that names a brand colour fails the build.

*Done when* the app looks identical, screenshot for screenshot, and a palette
change touches one file.

**RS2 · Brief and anti-references (S).**
- Use WP8's product context, adding the scene: outdoors, one-handed, cheap
  screens, bright sun, weak signal.
- Record the owner's answers to decisions 4 and 5.
- Collect anti-references: §1's "should not look like" list, the generic AI
  looks Impeccable names, and competitors' screens.

*Done when* the brief fits on a page and the owner agrees with it.

**RS3 · Direction round (M).**
- Run Impeccable's concept roll (`concept-seed --scope direction --mode
  operate`), then weigh its challengers against the brief.
- Show three directions plus "evolve what is there" on the decision page.
- Each card shows the palette, the type pairing (Latin and Urdu), the depth
  and corner language, icons, map styling, and one screen sketched (Jobs on a
  phone), with its honest risk.

*Done when* the owner has picked, and the direction contract is recorded with
its seed reference. That also closes the reviewer's process finding from
0.23.

**RS4 · Type (M).**
- Choose the Latin face for the chosen direction. It must have:
  - an open (OFL) licence;
  - files bundled for offline use;
  - tabular figures, because fares line up;
  - real weights from 400 to 700;
  - a pairing with Noto Sans Arabic, and Nastaliq for display Urdu.
- Re-tune the scale with tracking 0, and check how much it adds to the web
  bundle.
- Run `surfaces_test.dart`, since new font metrics are where Urdu overflows
  come from.

*Done when* both languages pass the six-shape matrix.

**RS5 · Palette, depth and shape (M).**
- Fill the RS1 roles for light and dark, including the dark-mode text tint for
  the accent.
- Retune the `card` and `lift` shadows from WP4, and the radius-by-role scale.
- Turn the contrast gate in `accessibility_test.dart` from a list of pairs into
  every role pair the app draws.

*Done when* the gate passes in both themes.

**RS6 · Icons (S–M).**
- Pick one family, decided in RS3. Options are Material Symbols Rounded, which
  the brand's §14 already describes, or another drawn set.
- Use one weight, one stroke and one size scale: 24px standard, 20px compact.
- Remove any glyph standing in for an icon.

*Done when* WP2 finds no mixed families.

**RS7 · The map (M).**
- Choose tile styles for both themes from the keyless options, or note the
  paid one the README describes.
- Redraw the pin, the selected pin with its fare label, own pins, clusters,
  the radius and the user's position from the roles.
- Check every pin against its basemap in both themes. The review found
  burgundy pins faint on the dark tiles.

*Done when* pins read in both themes at a glance.

**RS8 · Assets outside the app (S).** Regenerate from the new roles:
- the app and PWA icons (`tool/generate_app_icons.py`);
- the placeholder job images (`tool/generate_placeholder_assets.py`, which
  hard-codes burgundy, deep burgundy and copper);
- the onboarding pictures.

Update the boot screen colours and `theme-color` in `web/index.html` and
`manifest.json`, and `web_shell_test.dart`, which pins `#7A263A`.

*Done when* nothing outside the app shows the old palette.

**RS9 · Review, document, release (M).**
- Capture the full set from WP9: phone, tablet, desktop, light and dark,
  English and Urdu, before and after.
- Run Impeccable's finish reviewer against the direction contract and the
  quality-bar card, then a verdict pass on the fixes.
- Write the brand file's design-language section (WP12) from the built
  result.
- Bump to 0.24.0, update the CHANGELOG, the README's design notes and the demo
  script's screen descriptions.

*Done when* the reviewer says ship, or the owner accepts what remains.

**Order.** Run RS1 straight after WP2, so WP3–WP6 are written against roles
rather than colours. RS2 and RS3 can run in parallel with the rest of Part 1.
RS4–RS9 start once WP2, WP4, WP6 and WP8 are in.

**Risks.**

| Risk | Mitigation |
| --- | --- |
| Recognition: evaluators and the app icon know burgundy | Decision 4, chosen deliberately |
| New font metrics overflow Urdu at large text | `surfaces_test.dart` plus the large-text accessibility test |
| Contrast regressions in dark mode | The full role-pair gate from RS5 |
| A bigger web bundle from new fonts or an icon font | Measure it in RS4 and RS6, and keep tree-shaking on |
| Scope creep into structure | The structure is fixed in this part. Any structural idea goes back to Part 1 as a new package |

## Out of scope for now

- Marketing-site devices (see the table above).
- Real backend work. None of this touches `code/backend/`.

## Built (0.24.0)

Everything above was built on 2026-11-17, unattended at the owner's word ("Do
everything up to RS9. Don't ask me."). Decisions taken on the way:

- **The Post slot is white, not turmeric.** Built as the direction said, a
  turmeric Post pill beside the turmeric "you are here" indicator read as a
  second selected tab. The finish reviewer agreed: the signature move (turmeric
  only for selection and what is waiting) outranks the first-viewport detail.
- **Sentence case everywhere**, buttons included, and no em dashes in strings.
- **Offers are a radio group with one button that names the fare**, rather than
  a filled button per offer (WP3). The light-mode radio stays ink for contrast;
  the selected row's turmeric wash carries the selection.
- **The ledger shows the balance under each amount**, not in a second column:
  two money columns do not fit beside a description at 320px (WP5).
- **Focus rings follow `:focus-visible`**, showing only after a key press:
  Flutter treats a mouse as keyboard mode, and clicking the map ringed it
  (WP11).
- **Section numbers in the brand file were kept** wherever a topic carried
  over, because code comments cite them (WP12).
- **The finish review returned *fix*** with eight findings: blue and green
  signal hues, turmeric used as a link colour, a white fare flag, Urdu headings
  not in Nastaliq, "7:30 a" in Urdu, the view switch hidden with a job
  selected, four different selection treatments, and colour fields used as
  decoration (the turmeric intro, the ink wallet slab). All eight were fixed;
  the verdict passes scored them resolved and returned *ship*. Still open, as
  a ceiling note only: the dark basemap is a neutral grey, not tinted to
  night slate.

Before and after: [`2026-11-17-reskin-before-after.jpg`](2026-11-17-reskin-before-after.jpg)
(0.23.3 above, 0.24.0 below: map, selected pin, list, job, profile, dark, Urdu).
