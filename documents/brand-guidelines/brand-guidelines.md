Trust Hire Brand Guidelines

Version: 0.2
Status: As built in app 0.24, after Impeccable's finish review

---

Section numbers match version 0.1 wherever a topic carried over, because
comments in the app's code cite them ("Section 28: motion"). Topics new in
0.2 are numbered from 32.

---

1. Brand Overview

Trust Hire is a location-first job platform designed for Pakistan’s everyday workforce.

It helps people post and discover nearby work without forcing them through complicated forms, formal CVs, or rigid job categories.

The experience should feel:

- Simple
- Local
- Human
- Practical
- Trustworthy
- Modern without looking corporate
- Accessible without looking cheap

Trust Hire should not look like:

- A traditional recruitment website
- A government portal
- A banking application
- A generic AI startup
- A social media clone
- A green-and-white “Pakistan-themed” product

---

2. Brand Positioning

Brand Promise

Nearby work, made simple.

Trust Hire makes it easy to describe work in the way people naturally communicate:

- Voice notes
- Photos
- Short messages
- Approximate locations
- Simple timing information

Core Idea

Trust Hire should feel closer to posting a WhatsApp voice note than completing an employment form.

Brand Attributes

Human

The product should feel conversational and forgiving.

Practical

Every screen should help the user complete a real task.

Trustworthy

The interface should be calm, predictable, and transparent.

Flexible

Users should not be forced into strict fields or formal language.

Local

The product should feel relevant to Pakistan without relying on flags, crescents, green colour schemes, or cultural clichés.

---

3. Brand Name

Primary Name

Trust Hire

Preferred Display

Trust Hire

Avoid

TrustHire
TRUST HIRE
trust hire
Trust-Hire

The words should usually remain separated.

Product Descriptor

Where additional context is required:

Trust Hire
Nearby work, made simple.

Alternative descriptor:

Trust Hire
Find work. Find help. Nearby.

---

---

4. Colour Direction

Ink and turmeric on lime-wash.

The colours come from a working street in Pakistan: walls washed with lime,
lettering in near-black ink, and turmeric for the one thing that matters now.
They are used with the discipline of an instrument read in bright sun, not as
decoration.

What this means in practice:

- Everything at rest is ink and neutrals.
- Turmeric means "selected" or "waiting for you". Nothing else is turmeric.
- Peacock means "voice note". Nothing else is peacock.
- Brick means loss: an error, a destructive action, a debt.
- There is no fourth hue. Success, information and a person's location are
  said in ink, in words and in shapes, never in green or blue.

It is a deliberate alternative to:

- Pakistan-themed green and white
- Generic technology blue
- AI-product purple gradients and neon on black
- The cream-and-terracotta palette AI tools now default to
- A white screen with one brand accent sprinkled on every link

Version 0.1 of these guidelines used burgundy, copper and sand. It was
replaced in 0.24 (November 2026); the reasoning is in
documents/design/2026-11-17-reskin-direction.md.

---

5. The Palette

Every value lives in code/frontend/lib/core/tokens.dart (BrandColours). Screens
never name these colours; they ask for a role (section 6).

Ground and neutrals (light)

Lime-wash          #F3F5F7   The page. Cool, never cream.
White              #FFFFFF   Sheets, rows, search bar, chips.
Mist               #E7EBEF   Neutral tint: notices, input fills, quiet panels.
Line               #DCE1E6   Hairlines between rows.
Line strong        #7D8893   A control's boundary. 3.6:1 on white.
Ink                #16202A   Text and every filled action. 16.5:1 on white.
Ink muted          #56616C   Supporting text. 6.3:1 on white, 5.8:1 on lime-wash.
Slate              #3B4A5A   The pressed state of an ink fill.

Signals (light)

Turmeric           #F2A900   Selection fill: the selected pin, its area, the
                             fare flag, the navigation indicator. Ink on it 8.2:1.
                             Never text on white (2.0:1).
Turmeric wash      #FFF0C2   A selected row, offer or choice. Ink on it 14.5:1.
Turmeric text      #8A5300   Turmeric as words: a selected tab, an offer waiting,
                             a warning. 6.3:1 on white. Never a link colour.
Peacock            #0B6E6B   Voice notes and nothing else. 6.1:1 on white.
Brick              #B8321E   Loss. 6.0:1 on white.

Night (dark theme)

Night              #0E141A   The page.
Night surface      #16202A   Sheets and the navigation shell.
Night raised       #1F2B37   Inputs, raised panels.
Night line         #263241   Hairlines.
Night line strong  #6B7A8B   A control's boundary. 3.8:1 on night surface.
Night text         #EEF2F5   Text. 16.5:1 on night.
Night text muted   #9BA7B2   Supporting text. 6.7:1 on night surface.
Night turmeric     #F5B629   The action fill in dark, and selection. Night text
                             on it 10.2:1.
Night turmeric wash #33321F  A selected row in dark.
Night peacock      #5BBDB7   Voice notes. 7.4:1 on night surface.
Night brick        #F07A63   Loss. 6.0:1 on night surface.
Night pin          #C9D2DA   A pin at rest on the dark map.

---

6. Colour Roles

The app's screens never use a palette colour directly. They ask
context.colours (code/frontend/lib/core/roles.dart) for a role, and each role
has a value in both themes. A reskin changes roles.dart and tokens.dart, not
the screens. test/design_rules_test.dart fails the build if a screen names a
palette colour, a raw colour value or a Material colour constant.

Role            Light            Dark              Job
page            lime-wash        night             The ground.
surface         white            night surface     Sheets, rows, cards.
text            ink              night text        Words.
textMuted       ink muted        night text muted  Supporting words.
action          ink              night turmeric    Every filled button.
onAction        white            night             Words on a filled button.
highlight       turmeric         night turmeric    Selection fill.
selection       turmeric wash    night turmeric wash  A selected row or choice.
accentText      turmeric text    night turmeric    Turmeric as words (selected
                                                   tab, waiting). Not links.
voice           peacock          night peacock     Voice notes.
bad             brick            night brick       Loss.
good, info      ink              night text        Said in words, not hue.
warn            turmeric text    night turmeric    Something waiting on you.
pin             ink              night pin         A pin at rest.
pinSelected     turmeric         night turmeric    The job in hand.
pinOwn          white            night             Your own pin, drawn inverted.
shell           ink              night surface     The navigation bar and rail.
onShell         white            night text        Labels on the shell.

The contrast test (test/accessibility_test.dart) checks every pair a role is
drawn on, in both themes: 4.5:1 for text, 3:1 for a control's boundary and for
the shell's selected mark.

---

7. Signals

Three signal hues, each with one meaning, and ink for the rest.

- Loss is brick (#B8321E; night brick #F07A63): an error, a destructive
  action, a debt, a balance below zero.
- Something waiting on the person is turmeric: an offer waiting, a warning
  (turmeric text on a tenth-strength turmeric wash). The words say what.
- A voice note is peacock.
- Success and information are ink, on the neutral tint with a hairline. A
  green "done" or a blue "note" would be a fourth and fifth hue; the words
  and the icon carry the meaning instead.
- A person's own location is an ink dot, not the usual blue.

---

8. Colour Ratio

Colour ratio, roughly: 70% ground and white, 25% ink, under 5% turmeric,
with peacock and brick only where they mean something.

---

9. Colour Combinations

Preferred

Ink on lime-wash or white
White on ink
Ink on turmeric
Ink on turmeric wash
White on peacock
Night text on night or night surface
Night on night turmeric

Avoid

Turmeric as text on white or lime-wash (2.0:1): use turmeric text instead
Turmeric text as a link or a general accent
Turmeric next to brick at the same size: loss must never look selected
Peacock on anything that is not a voice note
Grey text on the turmeric fill

---

10. Typography

Typeface

Atkinson Hyperlegible Next, for every Latin character.

It was designed for low-vision readers: letters that are easy to confuse
(I l 1, O 0, rn m) are drawn apart. That matters to somebody reading a fare
on a cheap phone in bright sun. It has tabular figures, so fares and times
line up in columns. The app bundles four static weights (400, 500, 600, 700),
about 190 KB, cut from the variable font.

Urdu

- Noto Sans Arabic for Urdu body text, labels and anything small.
- Noto Nastaliq Urdu for Urdu headings, titles, the app bar and dialogs,
  with taller lines (1.9) for its descenders. Urdu is read in Nastaliq; it is
  not used below title size.

The theme applies Nastaliq whenever the app is in Urdu
(BrandTheme.urdu in lib/core/theme.dart), and the Latin letters on the same
line stay in Atkinson.

Fallback stack (web)

  "Atkinson Hyperlegible Next", "Noto Sans Arabic", system-ui, sans-serif

Rules

- Sentence case everywhere, buttons included.
- No letter spacing outside the type scale (enforced by design_rules_test).
- Nothing smaller than 12px (enforced by design_rules_test and
  accessibility_test).
- Figures that are compared are tabular and right-aligned.

---

11. Type Scale

Style            Size / line   Weight   Use
Display          32 / 38       700      The intro's headline.
Page heading     24 / 30       700      Screen titles.
Section heading  18 / 24       600      Sheet titles, section heads.
Body             16 / 24       400      Everything people read.
Supporting       14 / 20       400      Location, time, distance on a row.
Caption          12 / 16       500      Labels under figures, chips.
Button           16 / 24       600      Every button.
Fare             18 / 24       700      Money. Tabular figures.

Values live in BrandType (lib/core/tokens.dart). Tracking is 0 throughout:
Atkinson is spaced for reading as drawn.

---

12. Logo and App Icon

The mark is the map pin: one circle for the head and two tangent lines down to
a point, the same construction the map's markers use. It is drawn in ink on a
turmeric ground.

- App icon (Android, iOS, web): an ink pin on a turmeric square, rounded on
  Android and the web, square and opaque on iOS (iOS applies its own mask).
- Maskable web icons keep the pin inside the 80% safe zone.
- Favicon: square, the pin larger, because a rounded corner at 16px is mush.
- At the head of the navigation rail: the same pin, turmeric on the ink shell,
  with the wordmark "Trust Hire" in the shell's text colour.

All icons are drawn by code/frontend/tool/generate_app_icons.py; regenerate
them after any change to the mark. Each file carries its provenance.

---

13. Logo Usage

Wordmark

"Trust Hire" in Atkinson Hyperlegible Next, bold, one colour. Never TrustHire
or TRUST HIRE (section 3).

Minimum size: the pin stays clear at 24px; below that, use the mark alone.

---

14. Iconography

- Material Symbols, the rounded set, filled. Filled shapes read better than
  thin outlines at small sizes in bright light.
- An outline that carries state (an unsaved bookmark, an empty star) is the
  rounded set's own _border variant.
- One family only: test/design_rules_test.dart fails on any icon outside it.
- Icons are 20px in rows and 24px in navigation, and always sit beside a word
  unless the control has a label for screen readers and a tooltip.

---

15. Map Styling

- Basemap: Esri Light Gray Canvas in light and Dark Gray Canvas in dark,
  tinted toward the page colour (lime-wash, night) so the map sits in the
  world. Place names are a separate layer drawn above the tint.
- Pins at rest are ink with a white glyph (light) or night pin with a night
  glyph (dark).
- The selected pin is turmeric with an ink glyph, larger, with an ink outline.
  Its approximate area is a turmeric wash with a turmeric edge, and its fare
  flies above it on a turmeric flag with ink figures.
- Your own jobs are drawn inverted: the ground's colour inside, the pin colour
  as outline and glyph.
- Your location is an ink dot with a white ring and a faint ink halo.
- The exact spot is never shown until a worker is chosen; the area is.

---

16. Photography

Photography should show real work and real environments.

Preferred Subjects

- Tradespeople
- Repair work
- Construction
- Workshops
- Shops
- Homes
- Markets
- Local businesses
- Tools
- Hands performing work
- People discussing or inspecting work

Photography Style

- Natural lighting
- Real locations
- Warm colour temperature
- Honest expressions
- Practical clothing
- Everyday environments
- Documentary rather than advertising photography

Avoid

- Corporate office stock photos
- People in suits shaking hands
- Artificially diverse boardrooms
- Overly polished construction scenes
- Fake call-centre imagery
- AI-generated-looking faces
- Heavy colour filters
- Pakistan flags used as decorative backgrounds

Images should communicate dignity without pretending the work environment is perfect.

---

17. Illustration

Illustrations may be used for:

- Empty states
- Permission explanations
- Onboarding
- Error recovery
- Media guidance

Illustration Style

- Simple geometric forms
- Rounded edges
- Limited detail
- Ink, turmeric, white and lime-wash, as the app uses them
- Human proportions that feel natural
- Subtle local context

Avoid

- Purple 3D characters
- Floating glass cards
- Robots
- AI sparkle symbols
- Excessive gradients
- Cartoon construction stereotypes
- Cultural clothing used as decoration without purpose

---

18. Voice and Tone

Trust Hire should sound like a helpful person, not a recruitment department.

Voice Characteristics

Clear

Use familiar words.

Respectful

Never speak down to the user.

Direct

State what the user needs to do next.

Reassuring

Explain that incomplete information is acceptable.

Flexible

Do not imply that there is only one correct way to post a job.

---

19. Writing Principles

Prefer

Tell people what work you need.

Instead of:

Enter a comprehensive job description.

Prefer:

Add a voice note, photo, or short message.

Instead of:

Complete all mandatory job information fields.

Prefer:

Choose the general area.

Instead of:

Provide the exact worksite address.

Prefer:

You can add this later.

Instead of:

This field is optional.

Prefer:

Could not save your job. Try again.

Instead of:

An unexpected system exception occurred.

---

20. Terminology

Use

- Job
- Work
- Person
- Worker
- Helper
- Nearby
- Area
- Voice note
- Photo
- Time
- Contact
- Post
- Save

Avoid Where Possible

- Vacancy
- Candidate
- Human resources
- Recruitment pipeline
- Applicant tracking
- Employment opportunity
- Geospatial coordinates
- Multimedia attachment
- Submit record
- Mandatory field
- Labour resource

The word “worker” should be used respectfully and contextually.

---

21. Calls to Action

A button says what happens when you press it, in sentence case.

Primary actions (filled, one per screen)

Post a job
Post job
Offer a fare
Choose Rs. 2,500
Show number
Open details
Add tokens

Secondary actions (outlined or text)

Add a voice note
Add a trade
Change area
Listen again
Edit job
Switch account

Avoid

Submit
Proceed
OK
Confirm
Click here
Title Case Buttons

The full string rules are in documents/product/product-context.md.

---

22. UI Components

Buttons

- Filled: ink (night turmeric in dark), white (night) text, a 52px pill.
- Outlined: transparent, ink border and text, 52px pill.
- Text: ink, at least 44px tall.
- Pressed: the fill darkens a step (slate). Disabled: mist fill, muted text.

Navigation

- An ink shell: the bottom bar on a phone, a rail on a tablet or desktop.
  Four destinations (Jobs, Directory, Activity, Profile) and one action.
- The selected destination is a turmeric pill under an ink icon, with a white
  label. Unselected labels are a muted near-white.
- "Post a job" is a white pill with an ink plus, in the middle of the bar or at
  the head of the rail. It is an action, never a place, so it is never
  turmeric.

Search and filters

- A white search bar with "Ask" (ink) and the account avatar, over the map.
- White filter chips with a hairline; a selected chip takes the turmeric fill
  with ink text.

Map controls

- White round buttons with ink icons, over the map. The view switch is an ink
  pill ("16 jobs" / "Map").

---

23. Form Controls

- Inputs: white (night raised in dark), a 1px line-strong border, a 2px ink
  border when focused, labels always visible above the field, 48px minimum.
- Chips and segments: stadium shape; selected takes the turmeric wash or fill.
- Radios and checkboxes: ink when on (turmeric in dark), with the row around
  them as the larger target.

---

24. Rows and Cards

- A job row: title, fare in the right column with its kind of fare under it
  ("Starting fare", "Agreed fare"), then location, time and distance at 14px,
  then what the job carries (voice note, photos). Hairline below.
- The selected row takes the turmeric wash.
- The map's preview is the one card on the jobs screen: white, 16px corners,
  the lift shadow, one filled "Open details" button.

---

25. Bottom Sheets and Dialogs

- White (night surface), 24px top corners, a drag handle.
- A job's sheet opens in a fixed order: title and status, fare, the voice note
  if there is one, the details, then the actions.
- Dialogs share the sheet's corners and ask with the action's own words
  ("Choose Rs. 2,500"), never "OK".

---

26. Voice Notes

- Peacock is the voice note's colour and nothing else's: the play button, the
  played part of the waveform, the microphone on the post form.
- The unplayed waveform is a neutral line. Length is shown as 0:00 / 0:12.
- A job described only by voice says so on its row ("Described by voice
  only"), so nobody opens it expecting text.

---

27. Photos

- Photos sit in a horizontal strip with 12px corners and open full-screen on
  an ink ground.
- Placeholder photos in the demo are drawn by
  tool/generate_placeholder_assets.py: bands of brand colour, obviously not
  photographs.

---

28. Motion

Motion says what changed; it never decorates.

- Durations: fast 160ms (a press, a toggle), standard 240ms (a sheet, a card),
  large 340ms (a screen).
- One curve: Cubic(0.22, 1, 0.36, 1), a quick start and a long settle.
- The selected pin grows; the preview card slides up; the map's controls move
  up with it.
- With reduced motion switched on, transitions become fades or nothing.

---

29. Accessibility

- Contrast: 4.5:1 for all text, 3:1 for a control's boundary and the shell's
  selected mark, in both themes, checked for every role pair by a test.
- Targets: 48px preferred, 44px minimum; buttons are 52px.
- Text: body 16px, nothing under 12px, and the app survives 2x text scaling
  without overflowing (tested).
- Colour is never the only carrier: a sign on money, a word on a status, a
  filled icon for a saved job, a wider dot for the current page.
- Keyboard: every control reachable by Tab, a visible ring when it is,
  arrow keys along the bar and rail, Escape closes sheets and dialogs and
  returns focus to what opened them.
- Every screen works right to left in Urdu.

---

30. Dark Mode

- The page is night (#0E141A), not black; sheets and the shell are night
  surface.
- Turmeric becomes the action fill, under night text: in dark, the filled
  button and the selection share a colour, because ink would vanish.
- Pins at rest are a light grey (night pin) with night glyphs; the selected
  pin stays turmeric.
- Every text role has its own dark value; none is a fill reused as text.

---

31. Design Tokens

The source of truth is code, not this table:

- code/frontend/lib/core/tokens.dart: palette (BrandColours), type (BrandType),
  radii (BrandRadius: 8, 12, 16, 24), spacing (BrandSizing: 4, 8, 16, 24, 32,
  40, 56), control height 52, readable width 720, motion (BrandMotion).
- code/frontend/lib/core/roles.dart: the colour roles in both themes, and the
  card and lift shadows.
- code/frontend/lib/core/theme.dart: Material's theme, built from the roles.
- DESIGN.md at the repository root: the design system as built, written by
  Impeccable's documenter after the 0.24 finish review.

---

32. Design Language

These are the rules the app is built on. Each says where it is enforced, so
the next change is held to it rather than to memory.

Surfaces

- The page is lime-wash (night in dark). Sheets, rows and the search bar are
  white (night surface). A surface that floats above the page carries a
  hairline ring and a soft shadow (AppColours.card); something lifted over the
  map carries a deeper one (AppColours.lift). There are no other shadows.
- Enforced by: roles.dart (card, lift); no BoxShadow outside lib/core in
  practice, checked in review.

Rows, not cards

- A list is rows on one surface with hairlines between them. A card is for
  something that sits above the page (the map's preview, a sheet), never for
  an item in a list.
- Enforced by: design_rules_test.dart ("rows are rows"), for the job and inbox
  rows.

One loud status

- Only work agreed or under way gets a filled status pill (ink). Every other
  state (taking offers, finished, called off, expired) is the quiet pill, and
  the word says which.
- Enforced by: StatusPill (lib/widgets/status_pill.dart).

The job in hand glows turmeric

- The selected pin, its area, its fare flag and its row are turmeric.
  Selection everywhere else (a picked offer, the chosen role, a selected
  segment or tab) takes the same turmeric wash. Nothing at rest is turmeric.
- Enforced by: the roles (highlight, selection, accentText); turmeric text is
  never a link colour.

One filled button per screen

- The action the screen is for is filled; everything else is outlined or text.
  A hirer's offers are a radio group with one "Choose Rs. 2,500" button, not a
  button on every offer.

Accent text in dark mode

- In dark the action fill is turmeric under night text, and turmeric as words
  is night turmeric. Fills are never used as text colours; each role has its
  own text value (accentText), which is how dark mode passed AA.
- Enforced by: accessibility_test.dart over every role pair.

Switch or table

- Short parallel facts are read across, not down: a worker's record is one bar
  of three cells (rating, jobs finished, usual fare) with hairlines between;
  the wallet's history is a table with column headings and right-aligned
  tabular amounts. Fares and times sit in fixed columns so a list reads down
  like a departures board.
- Enforced by: rating_test.dart and wallet_test.dart, both at 320px.

One motion curve

- Cubic(0.22, 1, 0.36, 1) for everything, at three durations (section 28).
- Enforced by: design_rules_test.dart ("one motion curve").

Keyboard focus is always visible

- Every control shows a 2px ring when reached by keyboard, and only then:
  ink on the page, turmeric on the ink shell, just outside a Material button.
- Enforced by: keyboard_test.dart, which walks the app by Tab.

---

33. Urdu

- Right to left throughout, mirrored layout, figures left to right.
- Headings in Nastaliq, body in Noto Sans Arabic (section 10).
- Times name the part of the day: صبح، دوپہر، شام، رات, never a Latin a or p.

---

34. Brand Do and Don't

Do

- Keep the page calm: ink, white and lime-wash.
- Spend turmeric only on the job in hand and what is waiting.
- Keep peacock for voice.
- Say states in words.
- Line figures up in columns.

Don't

- Use turmeric for links, icons or decoration.
- Add a green "success" or blue "info" colour.
- Put a list item in a card.
- Put two filled buttons on one screen.
- Use a second icon family, a second curve, or text under 12px.
- Use green-and-white "Pakistan" theming, purple gradients or neon.

---

35. Brand Summary

Trust Hire is ink and turmeric on lime-wash: a calm, legible tool for finding
nearby work, where the one thing that matters now is the one thing that glows.

---

Version history

0.2 (November 2026, app 0.24): ink, turmeric and lime-wash replace burgundy,
copper and sand; Atkinson Hyperlegible Next replaces Inter; colour roles,
design language and the rules that enforce them added; written from the app
as built and reviewed.
0.1: POC brand direction.
