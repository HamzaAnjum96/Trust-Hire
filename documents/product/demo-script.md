# Demonstrating Trust Hire

How to see each Phase 1 rule working, in about fifteen minutes, on one device
with no account and no network beyond map tiles.

Every stop below is checked by
[`code/frontend/test/demo_walkthrough_test.dart`](../../code/frontend/test/demo_walkthrough_test.dart).
That test does not test the rules — each rule has its own file — it tests that
this walkthrough still *walks*: that the account still has the data and the
screen still has the control. **A script nobody checks rots, and it rots
silently.** The reader finds out in front of an audience.

> **Before you start.** Open the app, tap through the three intro screens, and
> leave the language on English. If somebody has used this browser before, use
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

**Map.** Jobs near you, clustered. The count in the header is how many are
visible *to you* — not how many exist. Pins are approximate on purpose: the
circle is the area, not the address.

**The notice under the header.** *"Jobs only reach you when they match a trade
you do."* This is Section 8 working, and it is why the count is lower than the
183 jobs in the seed. Tap the ✕ to dismiss it; it stays dismissed for this
account.

**Say:** the device account has no history at all. That is what a first launch
looks like, and it is the reason the other six accounts exist.

---

## Stop 2 — Being somebody else

**Tap:** the avatar in the map header (or *Profile → Demo accounts*).

Seven accounts, five of them people from the seed, one per city, plus Trust
Hire's own staff account. Each row says where they are and how much they have
posted.

**Say:** there is no sign-in — Section 13a puts authentication out of scope —
so this is how both sides of one hire get demonstrated on one device. These are
not accounts: no password, no privacy between them, one browser's storage.

---

## Stop 3 — The hirer's side (Mode A)

**Be:** Hina Butt, Islamabad. **Go:** Activity → Posted.

Four postings, in different states. Open the one marked with offers.

What to point at, in this order:

1. **The offers, cheapest first — and nothing marks one as the one to take.**
   Section 4 requires the hirer to choose. The order exists because a list
   needs an order; there is no "recommended" badge and the top row gets no
   extra emphasis.
2. **"Show Contact".** The poster's number is behind a button rather than
   printed on the card. Asking is the moment it is revealed.
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

## Stop 5 — The directory (Mode B)

**Go:** Directory. Workers who pay to be listed, with menus at fixed prices.

- **No bidding.** A hirer books one of them directly, and the request reaches
  that one worker rather than being broadcast.
- **The price shown is 2.5% below the worker's own.** That comes out of the
  platform's commission rather than the worker's earnings, so using Trust Hire
  beats ringing somebody you found on it. The worker is paid the same either
  way.
- **The order is not for sale.** Section 9 already charges for the shelf;
  charging again for the position on it makes it a racket.
- **An unrated worker shows no stars**, not a zero. New is not bad.

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

1. **Turn on "Pretend there is no connection", then do something** — accept an
   offer, post a job. It works. It always works: a local write lands locally
   and immediately, because the people this is for lose signal in the middle of
   a job.
2. **The pill says "No connection — your work is safe", with a count waiting.**
   Nothing is lost and nothing is blocked.
3. **Turn the connection back on and press Sync now.** The queue drains.
4. **The part worth dwelling on:** the stand-in *refuses* things — the same
   things the real database would, listed in `MockBackend.rulesEnforcedHere`
   against the migration each comes from. A refusal it will give again forever
   leaves the queue rather than blocking everything behind it, and it is shown
   to the person in their own language rather than being dropped. An offline
   app that quietly discards a change the server rejected is the failure this
   whole layer exists to avoid.

---

## Stop 9 — The parts that are not the app

Worth two minutes at the end, because they are where most of the argument is:

- **`code/backend/`** — the PostgreSQL schema, with nine of these rules
  restated as constraints and triggers. `tool/verify_schema.sh` builds a
  throwaway database and runs 71 assertions against it.
- **`tool/sweep_schema.sh` and `code/frontend/tool/sweep_tests.py`** — these
  break each rule in turn and check the tests notice. Between them they found
  six checks that had been passing since the day they were written and could
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
