---
name: Trust Hire
description: Ink and turmeric on lime-wash. A sunlit instrument for finding, offering and arranging local work.
colors:
  lime-wash: "#F3F5F7"
  white: "#FFFFFF"
  line: "#DCE1E6"
  line-strong: "#7D8893"
  mist: "#E7EBEF"
  ink: "#16202A"
  ink-muted: "#56616C"
  slate-blue: "#3B4A5A"
  shadow-ink: "#0B1219"
  shell-muted: "#B8C2CC"
  turmeric: "#F2A900"
  turmeric-wash: "#FFF0C2"
  turmeric-text: "#8A5300"
  peacock: "#0B6E6B"
  brick: "#B8321E"
  night: "#0E141A"
  night-surface: "#16202A"
  night-raised: "#1F2B37"
  night-line: "#263241"
  night-line-strong: "#6B7A8B"
  night-text: "#EEF2F5"
  night-text-muted: "#9BA7B2"
  night-turmeric: "#F5B629"
  night-turmeric-wash: "#33321F"
  night-peacock: "#5BBDB7"
  night-brick: "#F07A63"
  night-pin: "#C9D2DA"
  night-own-pin: "#D9B38C"
typography:
  display:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.1875
    letterSpacing: "0em"
  headline:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0em"
  title:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3333
    letterSpacing: "0em"
  body:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0em"
  body-supporting:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4286
    letterSpacing: "0em"
  label:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.3333
    letterSpacing: "0em"
  button:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.5
    letterSpacing: "0em"
  fare:
    fontFamily: "Atkinson Hyperlegible Next, Noto Sans Arabic, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.3333
    letterSpacing: "0em"
    fontFeature: "tnum"
  display-urdu:
    fontFamily: "Atkinson Hyperlegible Next, Noto Nastaliq Urdu, Noto Sans Arabic, serif"
    lineHeight: 1.9
rounded:
  small: "8px"
  medium: "12px"
  large: "16px"
  sheet: "24px"
  pill: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "40px"
  3xl: "56px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "52px"
  button-primary-pressed:
    backgroundColor: "{colors.slate-blue}"
    textColor: "{colors.white}"
  button-primary-disabled:
    backgroundColor: "{colors.mist}"
    textColor: "{colors.ink-muted}"
  button-primary-dark:
    backgroundColor: "{colors.night-turmeric}"
    textColor: "{colors.night}"
    rounded: "{rounded.pill}"
    height: "52px"
  button-secondary:
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "52px"
  button-text:
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    height: "44px"
  input:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.medium}"
    padding: "14px 16px"
    height: "48px"
  search-bar:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.medium}"
    height: "52px"
  filter-chip:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    typography: "{typography.body-supporting}"
    rounded: "{rounded.medium}"
    padding: "0 12px"
    height: "44px"
  filter-chip-selected:
    backgroundColor: "{colors.turmeric}"
    textColor: "{colors.ink}"
  nav-shell:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    height: "68px"
  nav-shell-unselected:
    textColor: "{colors.shell-muted}"
  nav-indicator:
    backgroundColor: "{colors.turmeric}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
  nav-post-slot:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.medium}"
  view-switch:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
    typography: "{typography.body-supporting}"
    rounded: "{rounded.pill}"
    padding: "0 16px"
    height: "44px"
  job-row:
    textColor: "{colors.ink}"
    padding: "14px 16px 16px"
  job-row-selected:
    backgroundColor: "{colors.turmeric-wash}"
    textColor: "{colors.turmeric-text}"
  fare-flag:
    backgroundColor: "{colors.turmeric}"
    textColor: "{colors.ink}"
    rounded: "{rounded.small}"
    height: "28px"
    width: "120px"
  card:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.large}"
    padding: "16px"
  notice:
    backgroundColor: "{colors.mist}"
    textColor: "{colors.ink}"
    typography: "{typography.body-supporting}"
    rounded: "{rounded.medium}"
    padding: "16px"
  status-pill:
    backgroundColor: "{colors.mist}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    rounded: "{rounded.small}"
    padding: "4px 10px"
  status-pill-emphasised:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
  status-pill-bad:
    backgroundColor: "{colors.brick}"
    textColor: "{colors.white}"
  sheet:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sheet}"
  snackbar:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.white}"
    typography: "{typography.body-supporting}"
    rounded: "{rounded.medium}"
---

# Design System: Trust Hire

## Overview

**Creative North Star: "The Sunlit Street Board"**

Ink and turmeric on lime-wash. The colours of a working street in Pakistan: walls washed with lime, lettering in near-black ink, and turmeric for the one thing that matters now. The palette is used with the discipline of an instrument read in bright sun, one-handed, on an inexpensive Android phone, not as decoration. A person knows where everything is before they notice the world; what they read first is work: where it is, what it pays, whether it is theirs.

Density is that of a departure board: rows, not cards; fares and times in fixed, right-aligned tabular columns that read down the list. At rest everything is ink and cool neutrals. Selection is the only saturated thing on a screen, so the job in hand, its pin, its area, its fare flag and its row, glows turmeric wherever it appears. Voice notes keep a colour, peacock, that nothing else may use. Brick is loss and only loss.

The app's own controls live on one committed band of ink: the navigation bar on a handset, the rail on a tablet or desktop, in both themes. Dark mode is night slate, not black, and there turmeric becomes the action fill under dark text. The system rejects the category default of a white screen with one brand accent, and the generated defaults of cream with terracotta, neon on black, and tech blue.

**Key Characteristics:**
- Cool lime-wash page, white surfaces, hairline lines; no cream.
- Ink for text and for every filled action in light mode; turmeric for the action fill in dark mode.
- Turmeric only for what is selected, new or waiting (and the brand mark on the rail).
- Four hues in total: ink, turmeric, peacock, brick. Success, information and the person's own location are ink, said in words and shapes.
- Atkinson Hyperlegible Next at tracking 0, tabular figures on every fare; Nastaliq for Urdu display.
- Chunky 52px pill buttons, 16px cards, 24px sheets, filled rounded Material icons.
- An ink shell in both themes, with a turmeric indicator for "you are here".

## Colors

A near-monochrome of ink on cool lime-wash, punctuated by one warm signal (turmeric) and two reserved hues (peacock for voice, brick for loss). Screens never name these colours directly: they ask for a role (page, surface, line, text, action, accentText, highlight, selection, voice, bad, shell, pin...), and a reskin changes only the role map.

### Primary
- **Street Ink** (ink): Body and heading text (15:1 on the page), every filled action in light mode, the shell (navigation bar and rail) in both themes, pins at rest, the view switch, the snack bar, and every "good" or "information" signal. The pressed state of an ink fill steps to **Slate Blue** (slate-blue).
- **Night Turmeric** (night-turmeric): The action fill in dark mode, always under night text (10.2:1), and the accent as words in the dark.

### Secondary
- **Turmeric** (turmeric): The signature. What is selected, new or waiting: the selected pin, its fare flag, the navigation indicator, a selected filter chip, an offer count waiting, the rail's brand mark. Always carries ink on top of it (8.2:1); never text on white (1.8:1).
- **Turmeric Wash** (turmeric-wash): The fill of a selected row, in the job list and in the offer radio group alike, so selection reads one way across the app. The selected pin's area on the map is turmeric at about 22% opacity with a darker turmeric edge.
- **Turmeric Text** (turmeric-text): Turmeric as words, 6.3:1 on white: a selected tab's label and indicator, a selected row's title, a warning. Never a general link colour.

### Tertiary
- **Peacock** (peacock / night-peacock): Voice notes and nothing else: the play button, waveform, microphone, the "Voice note" marker on a row.
- **Brick** (brick / night-brick): Loss: errors, destructive actions, a debt, a negative balance, an error border.

### Neutral
- **Lime-Wash** (lime-wash): The page and the app bar, which sits on the ground rather than on white. Cool, never cream.
- **Sheet White** (white): Surfaces raised off the page: sheets, cards, search bar, chips, inputs, dialogs; and the Post slot on the shell.
- **Hairline** (line): Row dividers, the hairline ring in card shadows, chip borders at rest, the unplayed part of a waveform.
- **Strong Line** (line-strong): Input borders, the sheet drag handle; anything a line must be seen against (3.6:1 on white).
- **Mist** (mist): A quiet filled area: an information notice, a status pill at rest, a disabled button, a tile.
- **Muted Ink** (ink-muted): Secondary text (5.8:1 on the page), captions, avatars.
- **Shell Muted** (shell-muted): Unselected destinations on the ink shell (9.1:1 on ink).
- **Shadow Ink** (shadow-ink): What every shadow is made from.
- **Night family** (night, night-surface, night-raised, night-line, night-line-strong, night-text, night-text-muted, night-turmeric-wash): The dark theme's page, surfaces, one raised level, lines and text. Night slate, not black. Pins at rest are **Night Pin** (night-pin) and the viewer's own pins **Warm Sand** (night-own-pin) in the dark.

### Named Rules
**The Burning Line Rule.** Selection is the only saturated thing on a screen. Turmeric marks the job in hand and what is waiting for the person; everything at rest is ink and neutrals. A secondary button, a link or a text button is ink, never turmeric.

**The Four Hues Rule.** Ink, turmeric, peacock, brick, and no others. Success, information and the person's own location are ink, said in words and shapes, never in green or blue.

**The Voice Keeps Its Colour Rule.** Peacock belongs to voice notes. Nothing else may use it, so a voice note is never confused with anything else.

**The Roles Not Hues Rule.** Screens take colours from roles, never from the palette or raw values; `design_rules_test.dart` fails the build otherwise, and every text role pair is contrast-tested to AA in both themes.

## Typography

**Display Font:** Atkinson Hyperlegible Next (with Noto Sans Arabic for Arabic script)
**Body Font:** Atkinson Hyperlegible Next (with Noto Sans Arabic)
**Urdu Display:** Noto Nastaliq Urdu, for display, headline and title roles, app bar and dialog titles under the Urdu theme

**Character:** One face, drawn for readers with low vision so I, l and 1 differ and 0 and O differ, chosen because many readers here read slowly, on small screens, outdoors. Hierarchy comes from size and weight alone; tracking stays at the face's own.

### Hierarchy
- **Display** (700, 32px, 38px line): The largest statement on a screen; rare.
- **Headline** (700, 24px, 30px line): Page headings and the app bar title ("Inbox", "Wallet").
- **Title** (600, 18px, 24px line): Section headings, a job's title in a row or card, dialog titles.
- **Body** (400, 16px, 24px line): Running text and inputs; never smaller. Columns of text and rows stop at a 720px readable width.
- **Supporting** (400, 14px, 20px line): Secondary lines, meta (place, time, trade), chip and tab labels, notices.
- **Label** (500, 12px, 16px line): Captions, the fare's kind ("Starting fare", "Agreed fare"), shell labels, status pills, ledger column headings. Nothing in the app is smaller than 12px.
- **Button** (600, 16px, 24px line): Every button label.
- **Fare** (700, 18px, 24px line, tabular figures): Every amount of money, so figures line up down a list.

### Named Rules
**The Fare Leads Rule.** A fare is bold, tabular and sits opposite the title at the end edge, with what kind of number it is underneath. Columns of money are right-aligned and read down like a board.

**The Zero Tracking Rule.** Every style sets letter-spacing to 0, and tracking is set in the type scale and nowhere else (test-enforced).

**The Nastaliq Height Rule.** Urdu display text runs at a 1.9 line height; Nastaliq's descenders clip under anything tighter. Urdu body text stays in Noto Sans Arabic, which reads better small.

## Layout

Material window size classes, named for what the app does: compact under 600px (bottom navigation bar, one column, sheets), medium from 600px (navigation moves to the side rail, content stops stretching), expanded from 1024px (two panes: the map with a list of the same results beside it). The rail also needs 520px of height; below that the bottom bar stays, so no destination falls below the fold.

Spacing runs on a 4 / 8 / 16 / 24 / 32 rhythm drawn for a handset, with 40 and 56 for wide-screen gutters that must separate a rail from a canvas. Rows pad 14px top and 16px on the other sides; notices and cards pad 16px. Touch targets are 48px preferred, 44px absolute minimum; buttons are 52px tall.

Lists are rows, not cards: full-bleed, separated by hairlines, with the title leading and the fare opposite. Over the map, controls float: the search bar and filter chips at the top, the view switch bottom centre under the thumb, map controls bottom end, the selected job's preview card above the shell. Full Urdu right to left mirrors all of this.

## Elevation & Depth

A hybrid: the page and rows are flat and tonal, and things that sit on the page or float over the map take a hairline ring drawn as a shadow (so it never shifts layout) plus a soft drop. The app bar is flat on the ground and gains a hairline shadow only when content scrolls under it. The shell is separated by colour, not shadow.

### Shadow Vocabulary
- **Card** (`0 0 0 1px line, 0 4px 16px shadow-ink at 8%`): Cards on the page, the offer group, the fare flag, an over-map notice.
- **Lift** (`0 0 0 1px line, 0 8px 24px shadow-ink at 16%`): Hover and press, and anything floating over the map: the search bar, the selected job's preview card.
- **Material elevation 2-3** (shadow-ink at 20-30%): Floating chips over the map, the view switch, menus, the FAB.

### Named Rules
**The Flat Floor Rule.** Rows, the page and the shell carry no shadow. Depth is reserved for what sits on the page or floats over the map; in dark mode shadows are pure black and the raised surface tone does the work.

## Shapes

Soft, rounded rectangles in four steps and a pill. Actions are pills: every button, the view switch, the navigation indicator. Fields and controls that hold content are 12px: inputs, the search bar, filter chips over the map, notices, menus, the snack bar, and the Post slot on the shell. Small tags are 8px: status pills, the fare flag, the brand mark. Cards are 16px; sheets and dialogs are 24px (sheets on their top corners only). Map pins are a circular head tapering to a point; a selected pin is larger as well as turmeric, so colour never carries state alone.

## Components

### Buttons
Chunky and plain, easy to hit one-handed.
- **Shape:** full pill, 52px tall, 24px side padding.
- **Primary:** ink fill with white label in light mode; night-turmeric fill with night label in dark. Pressed steps to slate blue. Disabled is mist with muted text. One primary per screen.
- **Secondary:** transparent with an ink border and ink label, same pill and height.
- **Text:** ink label, 44px minimum.
- **Focus:** a 2px ring just outside the control in the action colour; around a filled button the ring is turmeric in light mode (near-white in dark), since ink beside ink only looks bigger. The outlined button's focused border thickens to 3px.

### Chips
- **Filter chips (over the map and list):** white, 12px corners, hairline border, 44px tall, supporting-size label with a leading icon. Selected is a turmeric fill and border with an ink label and a tick, so colour is never the only signal. Over the map they float at elevation 2.
- **Choice chips (directory, listing):** white with a hairline, selected takes the turmeric wash.

### Cards / Containers
- **Corner Style:** 16px.
- **Background:** white (night-surface in dark).
- **Shadow Strategy:** Card shadow at rest, Lift when floating over the map.
- **Border:** hairline.
- **Internal Padding:** 16px.

### Inputs / Fields
- **Style:** white fill (night-raised in dark), strong-line border, 12px corners, 48px minimum, labels always visible above.
- **Focus:** 2px border in the action colour.
- **Error:** 2px brick border.

### Navigation
- **Shell:** an ink bar 68px tall on a handset, an ink rail on wider screens, in both themes. Unselected destinations are shell-muted icons and 12px labels; the selected one sits on a turmeric pill indicator with an ink icon and a bold white label.
- **Post slot:** the action, never a destination. On the bar it keeps a destination's footprint but is a white 12px pill with an ink plus, so it is never mistaken for the selected tab; on the rail it is a white "Post a job" button. Keyboard focus on the shell rings in turmeric.
- **Tabs:** selected label and indicator in turmeric text, unselected muted, over a hairline.

### Job Row (signature)
The fare leads. Title at the start, bold tabular fare opposite with its kind beneath, then a wrapping line of meta (place, time, trade, voice) in muted supporting text with filled rounded icons. Rows never hold a card inside them (test-enforced). The row whose pin is selected takes the turmeric wash and a turmeric-text title.

### Map Pins and Fare Flag (signature)
Pins at rest are ink with white glyphs and a white outline (night-pin in dark); your own posts are inverted. The selected pin is turmeric, larger, with an ink outline and glyph, its area washed in turmeric, and a turmeric fare flag (8px corners, ink hairline, Card shadow, tabular fare) above it. Clusters are ink circles with a count. The person's own location is an ink dot with a soft ring.

### View Switch
An ink pill, 44px tall, floating bottom centre, carrying the result count in tabular figures ("16 jobs") on the map and "Map" on the list.

### Fact Bar and Ledger
A worker's standing is three facts in one bar (rating, jobs finished, usual fare) split by vertical hairlines: value large, label small beneath; numbers shrink rather than wrap. The wallet ledger is a data table inside a card: column headings, every amount in one right-aligned tabular column, the running balance beneath its amount; credits in ink, debits in ink, a negative balance in brick.

### Notices and Status Pills
Notices are 12px boxes with 16px padding and a leading icon: information and success are ink on mist with a hairline; a warning is turmeric text on turmeric at 10% with a 35% edge. Status pills are 8px tags, always labelled: muted (mist), emphasised (ink), finished (ink), stopped (brick).

## Do's and Don'ts

### Do:
- **Do** ask for a role (`context.colours.action`, `.highlight`, `.voice`), never a palette constant or a raw value.
- **Do** keep turmeric for the job in hand and what is waiting for the person; put ink on top of it.
- **Do** use turmeric text (#8A5300 role) when turmeric must be words.
- **Do** set every fare in the fare style with tabular figures, right-aligned in its column.
- **Do** make every button a 52px pill and every touch target at least 48px (44px absolute).
- **Do** draw a 2px focus ring on every custom control, only after keyboard input.
- **Do** move with one curve (cubic-bezier(0.22, 1, 0.36, 1)) at 160 / 240 / 340ms, and fade forward between routes.
- **Do** use Material's filled rounded icon family only.

### Don't:
- **Don't** use turmeric as text on white, or as a link, secondary-button or general accent colour.
- **Don't** add a green, blue or any fifth hue; success, information and location are ink.
- **Don't** use peacock for anything but voice notes, or brick for anything but loss.
- **Don't** put a card inside a job or inbox row.
- **Don't** set anything smaller than 12px, or body text smaller than 16px.
- **Don't** set tracking outside the type scale, or use a bouncing or overshooting curve.
- **Don't** make the Post slot turmeric; it is white with an ink plus so it never reads as the selected tab.
- **Don't** let colour carry state alone: a selected pin also grows, a selected chip carries a tick, a status is always a word.
