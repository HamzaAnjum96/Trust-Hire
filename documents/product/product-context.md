# Product context: voice, words and claims

Who the product is for and what it is are in [`PRODUCT.md`](../../PRODUCT.md) at
the repository root, where Impeccable reads them. This file is the part a
writer needs: how Trust Hire talks, the words it uses, and what it may and may
not say. Read it before changing any string in `app_en.arb`.

## Voice

A helpful person, not a recruitment department (brand guidelines §18). Plain
verbs, short sentences, the next step stated. The people reading are often in
the middle of something, outdoors, on a small screen, and many read slowly in
English. So:

- **Say the one thing that matters now, then what to do.** An error names what
  failed and how to recover. An empty screen says what will appear and how to
  make it appear.
- **Never blame the reader, never apologise, never joke** about money,
  identity or a job that was called off.
- **Optional things are genuinely optional,** and the copy says so once.

## How strings are written (decided 2026-11-17)

- **Sentence case** for every heading, button, tab, chip and menu item:
  "Post a job", "Save changes", "Show number". Title Case had crept in on
  about twenty buttons and sat next to sentence case in the same menu ("Edit
  Job" above "Call this off"). Brand guidelines v0.2 adopt this rule.
- **No em dashes in interface copy.** Use a full stop, a comma or "so". A dash
  in a short line on a phone reads as a break in the text, and it does not
  survive translation well.
- **No "not X but Y" turns, no colon reveals, no rhetorical questions.** Say
  the thing.
- **Buttons say what happens:** "Post job", not "Submit"; "Show number", not
  "Show contact". The action keeps its name through the flow: "Post job" gives
  "Job posted".
- **Numbers as figures** ("3 offers", "Rs. 2,500"), formatted through
  `Format`, never by hand.
- **Urdu is written by an Urdu speaker,** never machine-converted from a
  changed English string. When an English string changes meaning, its Urdu
  pair is checked; when only punctuation or casing changes, the Urdu stays.

## Glossary

| Use | Not | Meaning |
| --- | --- | --- |
| job | vacancy, gig, task | A piece of work somebody posted |
| work | employment | What a worker does; "find work" |
| worker | candidate, applicant, labour | A person offering to do jobs |
| hirer | employer, client | A person who posted a job or booked someone |
| offer | bid, application | A worker's proposed fare on a job |
| fare | price, rate, wage | The money for a job, in rupees |
| choose | accept, award | What a hirer does to an offer |
| call this off | cancel, terminate | Ending a job before it is done |
| area | location data, coordinates | Where a job roughly is |
| voice note | audio, recording | A spoken description of a job |
| directory | marketplace, listing page | Mode B: people at fixed prices |
| book | hire directly | Choosing a directory listing |

## Claims

Every sentence that promises something is listed, with the rule that keeps it
true, in [`claims.md`](claims.md). Add a row when you add a promise.

## Never say

- Anything that suggests a check proves more than it does ("verified" over a
  check that a number has thirteen digits).
- A number, customer, testimonial or outcome that is not real.
- "Pakistan-themed" flourishes: flags, crescents, national colours.
- That data is safe, private or encrypted in general terms. Say what happens
  to it, specifically.
