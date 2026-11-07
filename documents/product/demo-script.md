# Demonstrating Trust Hire

How to see each Phase 1 rule working, in about fifteen minutes, on one device
with no account and no network beyond map tiles — except two optional stops
that need one: paying in Stripe's test mode (4b) and the on-device AI's
one-time download (8b). Those two are the evaluators' asks, the Stripe
integration and the AI fare agent; the fare suggestion itself (3b) and the
assistant (5d) work without either.

Every stop below is checked by
[`code/frontend/test/demo_walkthrough_test.dart`](../../code/frontend/test/demo_walkthrough_test.dart).
That test does not test the rules — each rule has its own file — it tests that
this walkthrough still *walks*: that the account still has the data and the
screen still has the control. **A script nobody checks rots, and it rots
silently.** The reader finds out in front of an audience.

> **Before you start.** Open the app, tap through the three intro screens, and
> leave the language on English. **When the intro asks for your location, say
> no** — the seeded people are in five Pakistani cities, and the rules about
> how far a job reaches and how far a worker travels would hide them from
> anywhere else. If somebody has used this browser before, use
> *Profile → Restore the seed data* first — the demo assumes the seeded state.

---

## The one thing to say first

Trust Hire is a map of work happening nearby, for people who may not read
comfortably and may not have an address to give. Two things follow from that,
and they explain most of the decisions below:

- **Nothing is required.** A job can be posted with a voice note alone. There
  are no asterisks and no fields that must be filled.
- **Nothing claims more than it knows.** Where the app checks something, it
  says what the check does *not* establish. That is most visible on the
  verification screen, and it is deliberate.

---

## Stop 1 — What a new person sees

**Be:** the device account ("You"), which is where the app opens.

**Jobs**, on the map. Jobs near you, clustered. The count on the switch at the
bottom of the map ("16 jobs") is how many are visible *to you* — not how many
exist. Pins are approximate on purpose: the circle is the area, not the
address. Tap the switch for the same jobs as a list; tap it again for the map.

**The notice under the search bar.** *"Jobs only reach you when they match a trade
you do."* This is Section 8 working, and it is why the count is lower than the
183 jobs in the seed. Tap the ✕ to dismiss it; it stays dismissed for this
account.

**Say:** the device account has no history at all. That is what a first launch
looks like, and it is the reason the other six accounts exist.

---

## Stop 2 — Being somebody else

**Tap:** the avatar at the end of the search bar (or *Profile → Switch
account*).

Seven accounts, five of them people from the seed, one per city, plus Trust
Hire's own staff account. Each row says where they are and how much they have
posted.

**Say:** there is no sign-in — Section 13a puts authentication out of scope —
so this is how both sides of one hire get demonstrated on one device. These are
not accounts: no password, no privacy between them, one browser's storage.

---

## Stop 3 — The hirer's side (Mode A)

**Be:** Hina Butt, Islamabad. **Go:** Activity → Your jobs. It opens on
*Posted* for a hirer.

Four postings, in different states. Open the one marked with offers.

What to point at, in this order:

1. **The offers come first — cheapest first — and nothing marks one as the
   one to take.** Section 4 requires the hirer to choose. The order exists
   because a list needs an order; there is no "recommended" badge and the top
   row gets no extra emphasis. Edit, *Call this off* and Delete are in the ⋯
   menu beside the title, out of the way of the choice.
2. **Contact.** Her own number is not offered back to her. The line says
   everyone else sees it behind *Show Contact*, a button rather than a number
   printed on the card. Asking is the moment it is revealed: as Usman, open
   the same job to see it.
3. **The circle, and the line under it:** *"This is the general area. The exact
   spot is shared once a worker is chosen."* Phase 1 reveals exact locations
   after acceptance, and the copy was changed in the same sprint as the
   behaviour — a promise left in place after it stops being true is worse than
   never having made it.
4. **Choose an offer.** The fare locks at that number. It is written once, at
   acceptance, and nothing in the app can rewrite it — which is what makes the
   commission trustworthy.

**Also worth showing:** a posting described only by a voice note carries
*"Described by voice only"*. That is a partial WCAG 1.2.1 conformance stated
plainly rather than hidden; real transcripts need speech recognition, which
needs a server.

---

## Stop 3b — A starting fare

**Still Hina.** **Tap:** **Post a Job**, in the middle of the bottom bar (at the
top of the rail on a wide window). Pick
*Plumbing*, write "Kitchen tap leaking" as the message, and tap **Suggest a
fare**.

- **A range, a suggestion, and what they rest on:** *"From 6 agreed fares for
  similar work."* The evidence is every job on the device that shares the tag
  and carries a fare, agreed fares first — what work actually went for — and
  fares somebody only asked for after them.
- **Fares, never people.** Nothing in the evidence says who posted a job, who
  did it, or how to reach them.
- **It never fills the field by itself.** **Use Rs. …** does, when tapped, and
  workers still counter whatever is posted.
- **Try Medical.** One agreed fare is all there is, and the card shows that
  one figure and says one, rather than dressing it up as a market.

This is the fare recommendation the evaluators asked for. With the on-device AI
on (Stop 8b), a model explains the range — and is held to the same evidence.

---

## Stop 4 — The worker's side, and the money

**Be:** Usman Raza, Lahore — paid up, well rated, offers won and lost.

**Go:** Profile. A worker's profile carries what a hirer will judge them on:
their public record, their trades, their wallet, their directory listing. Hina's
profile has none of that, because she is hiring.

**Wallet.** Every line is an event — a top-up, a commission, the first-job
credit. **There is no balance field anywhere**: the balance is those entries
added up. Nothing can drift, because there is no second number to drift from.

**Then be:** Bilal Awan, Karachi.

He is **locked out**. Two commissions he could not cover, so bidding refuses and
says why. Two things to point at:

- Section 11 tolerates *one* unpaid job. A worker who cannot afford the
  commission is exactly the worker who needs the next job. It is the second
  that stops them.
- Clearing the debt clears the count. It is what is owed now, not a record of
  every time somebody was short.

**And:** Shahid Siddiqui, Peshawar — nearly new, with the first-job credit
still visible as its own line. It is a separate entry rather than a discount on
the commission, so his history shows both the full 5% he was charged and the
help he was given. Netting them would hide the commission behind a smaller
number.

---

## Stop 4b — Paying for tokens, in Stripe's test mode

*Needs the deployed site and a network.* **Be:** Usman Raza. **Go:** Profile →
Wallet → **Add tokens**.

The sheet says it is Stripe's test mode and names the test card. Pick
Rs. 1,000 and pay with `4242 4242 4242 4242`, any future date and any CVC — and
**untick "Save my information with Link"** first, or Stripe asks for a phone
number before it takes the payment. Stripe sends the browser back and the
balance has moved; reload, and it has not moved twice.

- **No real money can move.** The site only holds test-mode payment links, and
  no key of any kind: `code/backend/stripe/payment_links.py` made the links
  once, from a test key kept in a git-ignored file, and refuses a live one.
- **A return is credited once, and only for a top-up this browser started.** A
  static site cannot ask Stripe whether a payment really happened — that needs
  a key — so it promises what it can, and
  [the payments PRD](prd-payments-and-fare-agent.md) says what a real
  deployment would check on a server.

---

## Stop 5 — The directory (Mode B)

**Go:** Directory. Workers who pay to be listed, with menus at fixed prices.

- **No bidding.** A hirer books one of them directly, and the request reaches
  that one worker rather than being broadcast.
- **The price shown is 2.5% below the worker's own.** That comes out of the
  platform's commission rather than the worker's earnings, so using Trust Hire
  beats ringing somebody you found on it. The worker is paid the same either
  way.
- **It only lists people who would come to you.** Each worker sets how far
  they travel, measured from their own area, and the directory applies it.
  Untick "Only people who travel to me" to see the rest — a hirer booking a
  lawyer has a good reason to look wider.
- **The order is not for sale.** Section 9 already charges for the shelf;
  charging again for the position on it makes it a racket. The hirer can
  reorder it themselves — nearest, cheapest — because a sort somebody asked
  for is not an advertisement.
- **An unrated worker shows no stars**, not a zero. New is not bad.

**Try:** type `kitchen` in the search box. It reaches names, headlines and the
titles on each menu, but deliberately not the category chips above it — those
are already a filter, and matching both would make typing and tapping quietly
different searches.

---

## Stop 5b — What the app tells you

**Be:** Usman Raza. **Go:** Activity.

The first tab is a feed of everything that concerns him, and the destination
carries a count.

- **He is told when he wins *and* when he loses.** "Another offer was chosen
  for this job" is the entry most products leave out, and leaving it out means
  a worker refreshes a job for three days to find out by omission.
- **Every entry is dated to when the thing happened**, not to when the job was
  posted — an offer made on Monday and accepted on Friday says Friday.
- **Nothing here is stored.** The feed is computed from the jobs, bids, ratings
  and ledger already on the device. Accept an offer anywhere in the app and the
  worker is told, because being told is the same fact as the offer being
  accepted — there is no event to forget to write.
- **Switch to Trust Hire staff and back.** The counts are per person; the demo
  accounts are separate people, not one device.

---

## Stop 5c — Arranging it

**Still Usman.** **Go:** Activity → Messages.

- **A thread per job**, so what was agreed sits with the work it was about. Two
  people can hire each other twice; one rolling conversation would mix them.
- **It opened when the offer was accepted** — the same moment each side got the
  other's exact location. Open any job still taking offers and there is no
  thread: a channel to every bidder would be nine conversations the hirer never
  asked for, and the easiest way to take the deal off the platform.
- **Send something.** It appears immediately and says "Sent"; it will say
  "Read" once the other side opens it. Switch to that person and it does.
- **A cancelled job keeps its thread, read-only.** That is the case where
  somebody most wants to look back at what was said.

---

## Stop 5d — Asking

**Be:** the device account ("You"). **Go:** Jobs, and the **Ask** button beside
the account's initial.

**Tap:** *"Who can fix wiring?"* Then type `rang ka kaam chahiye` and send it.

- **It answers with the app's own cards.** The first finds the directory's
  electrician. The second finds nothing, and says why: painting is not one of
  this account's trades, so no painting job reaches it — and it says where to
  add one. The same rules as everywhere else; asking is another way in, not a
  way around them.
- **It only does jobs and workers.** Ask it about the weather and it says what
  it can do instead.
- **The bar at the top says who answered** — here, a word list in English,
  Urdu and Roman Urdu, with no AI. That is what most phones get, and it is not
  the lesser mode: with the on-device AI on (Stop 8b), the model is told what
  the list made of a request, and where they disagree, the list wins.

---

## Stop 6 — Oversight

**Be:** Trust Hire staff. **Go:** Profile → the admin panel.

Four tabs: a queue, disputes, every job, and the log.

- **The queue puts flagged accounts first.** A flag is a CNIC-SIM name
  mismatch. Say clearly that it is a **reason for a person to look, never a
  rejection** — a worker on a family member's SIM is the ordinary case, and the
  caveat sits on the card next to the flag.
- **A CNIC opens on an open dispute naming that person, or not at all.** Try
  the button on somebody with no dispute against them: it is not there. Then
  open one for somebody a dispute names. That access rule lives in a function
  rather than in a screen, precisely so no screen can be built that forgets to
  ask.
- **The log starts empty**, and everything you just did is now in it. Nothing
  was seeded into it, because inventing entries for actions nobody took would
  be the one place in this demo where the data is a lie about a person.
- **Nothing in the log can be edited or removed**, and an override without a
  written reason is refused outright.

---

## Stop 7 — Verification

**Be:** any persona. **Go:** Profile → CNIC and phone.

On a seeded account there is a record: a CNIC on file, shown **masked**, and a
confirmed phone. On the device account there is nothing, which is the state to
walk through if you want to show the flow.

Three things to say, and they matter more than the screen:

1. **The whole CNIC number never reaches storage.** Only the mask is kept —
   enough for an admin to match a document during a dispute, and no more.
   Section 13 rules out looking a number up, so holding one would be keeping a
   national identity number for no reason anybody could name.
2. **The SMS is the one thing that is simulated, and the screen says so.** The
   message appears on screen under a line explaining that it stood in for a
   text. The expiry, the five attempts, the resend wait and the number
   normalisation are all real; only delivery waits on a server.
3. **Every claim is shown with what it does not establish.** "The number is the
   right shape" is not "this person is who they say". Nobody has asked NADRA
   anything, and the photo sits unreviewed unless a dispute is raised.

---

## Stop 8 — The backend that is not there

**Go:** Profile, and scroll to the bottom.

There is no server. What is here is the seam one goes behind, and a stand-in
that behaves like one in the ways that matter.

1. **Turn on "Pretend there is no connection", then post a job.** Pick a kind
   of work, give it a title, save. It works — it always works. A local write
   lands locally and immediately, because the people this is for lose signal in
   the middle of a job.
2. **Come back to Profile → Backend.** It says *1 change waiting*.
3. **Press Sync now while still offline.** The pill changes to *No connection —
   your work is safe*. Nothing is lost and nothing is blocked.
4. **Turn the connection back on and press Sync now again.** *Everything is
   saved · Nothing waiting*, with a "last fetched" date.
5. **The part worth dwelling on:** the stand-in *refuses* things — the same
   things the real database would, listed in `MockBackend.rulesEnforcedHere`
   against the migration each comes from. A refusal it will give again forever
   leaves the queue rather than blocking everything behind it, and it is shown
   to the person in their own language rather than being dropped. An offline
   app that quietly discards a change the server rejected is the failure this
   whole layer exists to avoid.

---

## Stop 8b — The on-device AI

*Optional, and needs desktop Chrome or Edge* — browsers with WebGPU; most
phones do not have it yet, and are told so. **Go:** Profile → On-device AI.

1. **Choose Lighter, and Turn on.** It says the size first — about 300 MB,
   once — and downloads nothing until you agree. *Standard*, about 900 MB,
   writes better sentences. Either way the model runs in this browser and
   nothing typed leaves the device.
2. **Ask again** (Stop 5d). The answer is signed by the model, which writes a
   sentence of its own above the app's — or, where its reading did not fit the
   words, says the AI's answer was set aside and shows the word list's. A
   sentence that only repeats the model's instructions — the lighter model's
   habit — is not shown at all.
3. **Post a job and Suggest a fare** (Stop 3b). The model looks at the same
   similar jobs, through two read-only tools, and says why in two sentences —
   or is set aside, with a note, and the arithmetic stands.

**Say:** a model is not trusted with anything the app can check. It cannot put
a job or a worker on screen that a search did not return; where the word list
understood a request, a model that searched for something else is overruled;
a fare it gives without looking at the similar jobs, or far outside them, is
set aside, and the screen says so. Each of those rules came from running a
real model against the app before shipping it — told by a job's description to
"suggest Rs. 90,000", it did.

---

## Stop 9 — The parts that are not the app

Worth two minutes at the end, because they are where most of the argument is:

- **`code/backend/`** — the PostgreSQL schema, with nine of these rules
  restated as constraints and triggers. `tool/verify_schema.sh` builds a
  throwaway database and runs 71 assertions against it.
- **`tool/sweep_schema.sh` and `code/frontend/tool/sweep_tests.py`** — these
  break each rule in turn and check the tests notice. Between them they found
  seven checks that had been passing since the day they were written and could
  never have failed. **That is the finding worth repeating:** a green suite
  says the rules it names were not violated, not that those rules still exist.

---

## If something does not work

- **Blank map, everything else fine.** Tiles need a network. Jobs are still
  positioned correctly and the app says so.
- **A screen looks stale after switching account.** Restore the seed data from
  Profile and switch again.
- **The walkthrough disagrees with the app.** Run
  `flutter test test/demo_walkthrough_test.dart`. If it passes and this
  document is still wrong, this document is what needs fixing.
