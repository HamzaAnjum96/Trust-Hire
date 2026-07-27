# UX audit — what was taken, deferred, and declined

Version: 1.0

A response to the Trust Hire UI and UX audit. Every finding is answered here:
done, scheduled, or declined with a reason. Nothing is silently dropped.

The audit's own sequencing — web shell first, then information architecture,
then adaptive discovery — was followed, because it puts the cheapest visible
gains before the restructuring and avoids polishing an architecture that still
needs to move.

## Done

| Finding | Where | Version |
|---|---|---|
| Web metadata and manifest are Flutter defaults | `web/index.html`, `web/manifest.json`, branded icons, boot screen, canonical at deploy | 0.2.1 |
| "Saved" also contains Posted; no profile surface | Nav is now Discover-by-map, Jobs, **Activity**, **Profile**, with settings nested under Profile | 0.3.0 |
| No text alternative for voice-only jobs | Audio-only jobs labelled in list and details; the form asks for words without requiring them | 0.3.1 |
| No adaptive layout; single-column scaffolds everywhere | `LayoutSize`, a navigation rail from medium up, `ReadableWidth` on every text column | 0.4.0 |
| No wide-screen map/list split | Map and results rail side by side past 1024px, selection shared between them | 0.5.0 |
| PWA locked to `portrait-primary` | `orientation: any` | 0.2.1 |
| A hard-coded English helper string in the posting flow | Removed, and the guard that missed it twice now counts words instead of looking for a capital followed by a space | 0.3.1 |
| Map spinner where the list uses a skeleton | Scheduled — see below | — |

## Scheduled

**Progressive posting flow** (audit: High). The form is long and mixes media,
tags, contact, location and timing in one scroll. Worth doing, but it should
follow **P1-2** rather than precede it: bidding adds a starting fare to the
same form, and restructuring it twice is wasted work. Sectioning happens once,
with the final field set in place.

**Map loading skeleton** (audit: Medium). Cheap, and it belongs with the
posting-flow pass rather than on its own.

**Filter panel on desktop** (audit: Medium). The split view landed first
because it changes the shape of the screen the filters live on. A persistent
filter panel now has somewhere sensible to go — the rail's header — and is
next in the discovery thread.

**Transcripts for voice notes** (audit: High, partially addressed). Real
transcripts need speech recognition, which needs a server. Scheduled for
**P1-8** with the backend, and recorded as partial conformance until then.

**Keyboard focus and non-text contrast QA** (audit: High). The accessibility
suite covers tap targets, labels, contrast and text scale, but not tab order
or focus rings, which matter much more now that the app has a desktop layout.
This belongs immediately after the discovery thread, while the new controls
are fresh.

## Declined, with reasons

**"Add a web footer with About, Help, Privacy."** Not yet. The POC has no
privacy policy, no help content and no About page, so a footer would be four
links to pages that do not exist — worse than no footer. Revisit when there is
something to link to.

**"Show a completion meter on the posting form."** The audit suggests "2 of 5
helpful details added". This contradicts the product's second design
principle: missing information is acceptable. A progress meter tells someone
who posted a voice note that they are 40% finished, which is exactly the
judgement the form is built to avoid making. Sectioning the form addresses the
same fatigue without scoring the user.

**"Emulate Upwork/Indeed profile and search patterns."** Partly. The trust
surfaces are coming with P1-5, but the CV-centric framing is the thing the
brand guidelines rule out by name, and the audit agrees in its own closing
paragraph. Ratings and history land as a worker's page, not a résumé.

**"Rename the map destination to Discover."** The map *is* the product, and
"Map" says exactly what the destination shows. "Discover" is a category label
from a different kind of app. The audit's underlying point — that Map and Jobs
are two views of one thing — is answered by the split view instead.

## Where the audit was working from stale code

Two findings were already fixed before the audit was written, and are recorded
here so nobody re-fixes them:

- The job list's three distinct empty states and its skeleton loading were
  delivered in P1-1 and Sprint 13 respectively.
- Job tags stopped being optional in P1-1; the audit describes the POC's
  optional job type.
