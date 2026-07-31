# Retrospective — 0.15.1 … 0.15.3

Three rounds of the same shape: a UI pass, a bugfix pass, a refactor pass. No
new features. The reason to write this one down is that all four rounds this
month have now turned up the same failure, and it is worth naming.

## What the rounds actually found

| Round | Where I looked | What was wrong |
| --- | --- | --- |
| 0.15.1–0.15.2 | The built app, opened by hand at five window shapes | Profile unreachable on a phone held sideways; a notice on top of a button; the map attribution clipped to "© CART"; the posting action an unlabelled "+" |
| 0.15.3 bugfix | The same, but automated — six shapes × two themes × two languages | An empty state overflowing by 4px; a rating label overflowing by 8px in Urdu; and a bug in my own new test |
| 0.15.3 refactor | Two near-identical widgets, side by side | The map's preview card had no width cap where the job row did |
| 0.15.3 verify | The built app again, at 740×380 | The intro's opening sentence below an invisible fold — the matrix had been skipping the intro |

Ten defects. The suite was green for all ten.

## The thing that keeps happening

**Every one of them was invisible to a green suite, and for the same reason:
the tests named a condition that was never varied.**

- The four in 0.15.2: every widget test ran at one of two window sizes, in one
  theme, in one language. The bugs were all in between.
- The two in the 0.15.3 bugfix round: same, until `surfaces_test.dart` made the
  matrix explicit.
- The one in the refactor round: two copies of a widget, one of which carried
  the protection and one of which did not. Nothing compared them, because
  nothing could — they were different classes.
- The one in the verify round: the matrix marked the intro as seen in every
  case, so it covered every screen *except the first one anybody meets*. A
  matrix is only as good as the thing it is a matrix over.
- And earlier this month, in P1-8a and P1-10: two vacuous SQL checks, four Dart
  promises nothing held up, and a sync layer with a full test file that nothing
  in `lib/` ever called.

The pattern is not "we need more tests". It is that **a test asserts something
about the conditions it was run in, and says nothing whatsoever about the
conditions it was not.** A suite of 640 passing tests at 390×844 in English is
evidence about 390×844 in English.

## The two that are worth being embarrassed about

Two of the three tests written this round were vacuous on the first attempt.

**One.** The refactor produced a shared `MetaChip` with a width cap, and a test
to protect the cap:

```dart
expect(chip.width, lessThanOrEqualTo(MetaChip.maxWidth));
```

True for every value `maxWidth` could possibly hold. Setting the cap to
`double.infinity` left it green — the test's subject was also its expected
value, so it measured nothing.

**Two.** The intro fix got a check that the opening sentence was on screen:

```dart
expect(text.bottom, lessThanOrEqualTo(windowHeight));
```

Also green with the fix removed, because the sentence was never falling off the
*display* — it was falling out of the scrolling panel, underneath the dots and
the Next button. The window was not the thing doing the constraining.

**The same mistake twice in one afternoon, by the person who had just written
the tool that catches it.** Both were caught only because running the mutation
before believing the test has become a habit. Without that habit both would
have shipped, and both would have looked like coverage — 640 green tests, two
of them measuring nothing.

The generalisation, which is now in the README: **measure against the thing
that is actually constraining, not against the thing you are testing.**

## What changed as a result

- **`test/surfaces_test.dart`** — the matrix, 24 rendering cases plus a
  reachability check and an intro-legibility check per shape. Deliberately
  assertion-light: its value is in the number of combinations, not the depth of
  any one.
- **`LayoutSize` asks for height as well as width.** A departure from Material's
  window size classes, which are width-only — but a navigation rail is a
  vertical thing and 380px does not hold five destinations.
- **Three duplications collapsed**: the posting button (three copies), the map's
  floating controls (two), the meta chip (two). In each case the copies had
  already drifted, and in each case the drift was the bug.
- **`map_screen.dart` down from 1086 lines to 808**, with the overlays in their
  own file.
- **42 mutations in the sweep**, up from 40.

## What to carry forward

1. **When you fix a bug found by looking, add the axis you were varying**, not
   the case you happened to land on. The fix for "broken at 740×380" is a test
   that runs at six shapes, not one that runs at 740×380.
2. **Run the mutation before believing the test.** Every time — it caught two
   worthless tests here, in the same afternoon, and cost about three minutes.
   And when the mutation does not fail the test, the usual reason is that the
   assertion is measured against the wrong box.
3. **Two copies of a widget that must look identical is a latent bug**, not a
   style issue. All three collapsed this round had already drifted.
4. Still open, and still owned by Hamza: **the Urdu catalogue needs a native
   reviewer.** The matrix now proves the Urdu strings *fit*; it says nothing
   about whether they are good Urdu, and I cannot check that.
