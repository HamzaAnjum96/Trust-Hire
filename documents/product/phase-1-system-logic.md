# TrustHire — Complete System Logic Report
### SDLC Phase 1 Consolidated Documentation

This report consolidates every design decision made during Phase 1 planning. It is meant to be the single source of truth for the app's logic before moving into wireframing/design (Phase 2).

---

## 1. Project Identity & Scope

- **Name:** TrustHire (originally discussed as VVFM).
- **What it is:** A hyper-local, trust-focused, two-sided marketplace connecting manual laborers, skilled tradespeople, and consultants/professionals with local hirers.
- **Platform:** Android-only for the prototype. Built with React Native (cross-platform-ready for a later iOS port) and a Supabase (Postgres) backend, chosen over Firebase because the data is inherently relational (jobs, wallets, transactions, verification records) rather than document-based.
- **Academic constraints:** Solo student project, strict 8-week (2-month) timeline. Scope deliberately excludes live NADRA/government database access and real payment gateways — both are simulated with dummy data and real-feeling UI flows that don't process actual money or verified IDs.
- **Accessibility as a first-class constraint:** The app must work for users with low or no literacy. This shapes several decisions below (job posting format, category/tag logic).

---

## 2. Verification & Trust (Workers)

- **CNIC verification:** Worker uploads a CNIC photo at sign-up. It is **not** manually reviewed by default — an automated check confirms basic plausibility (valid CNIC number format, name/DOB present). The photo itself sits unreviewed unless a dispute is raised later, at which point an admin manually pulls it up.
- **CNIC-SIM name matching (fraud deterrent):** A low-cost third-party API checks whether the phone number provided matches the name on the submitted CNIC. This isn't a full identity verification — it's a cheap plausibility check specifically aimed at closing the "buy a new Rs. 100 SIM and re-register after being banned" loophole. A mismatch flags the account for manual admin review rather than auto-rejecting, since false positives are possible (e.g. a family member's SIM). This is a fraud-deterrence measure, not a claim of legal identity verification — any question of what this does or doesn't establish for liability purposes is a separate legal question, not something resolved by the check itself.
- **Phone verification:** A real SMS OTP (via a Pakistani SMS provider or similar) confirms the worker's phone number. This is genuinely implemented, not simulated, since it's inexpensive and adds real credibility.
- **Arrival verification:** No facial-recognition algorithm. The hirer simply confirms in-app, in their own judgment, that the person who arrived matches the profile — a human-verified step, not an AI one. This keeps the trust claim honest for an 8-week solo build.
- **No live government ID lookup** — this is explicitly out of scope, consistent with the academic project constraints.

---

## 3. Job Posting (Hirer Side)

- Jobs can be described via **text, voice/audio note, or video** — chosen to accommodate hirers with varying literacy levels.
- **Media compression (cost control):** Every uploaded image and video is auto-compressed server-side — images to WebP (roughly 80% quality, max width 1200px), videos to H.265/HEVC at 720p. This cuts typical file sizes by 80–90% with no meaningful quality loss on a phone screen, and it's pure engineering hygiene with no downside — worth building regardless of any other decision in this document.
- **Job media retention:** A job's audio/video/text description is only needed while it's active. Once a job's status becomes `completed`, `cancelled`, or `expired`, its associated media is automatically deleted from storage within 24 hours. Keeps storage costs predictable as job volume grows.
- Every job must have **1 to 3 tags**, selected from a fixed, controlled list (not free text) — this list is what powers the visibility/filtering logic described in Section 8.
- The hirer sets a **starting fare** — an opening point for bidding, not a fixed price (except in Mode B, see Section 9).
- The hirer sets a **job location**. By default, geofencing restricts visibility to nearby workers (Section 6), but the hirer can flip a toggle to make the job visible to workers anywhere, useful for jobs that don't require physical presence.

---

## 4. Bidding & Fare Logic (Mode A: Post & Bid)

- Bidding works like InDrive: the hirer posts a starting fare, and any eligible worker (per the tag/geofence filters) can submit a counter-offer.
- The hirer manually reviews all incoming bids and selects a worker — there's no auto-selection (not lowest-bid-wins, not first-come-first-served).
- Whatever fare is agreed at that moment of selection is **locked** — no renegotiation once the job is accepted and underway.
- This "fare locked at acceptance" rule is also what makes the commission calculation trustworthy — see Section 11.

---

## 5. Location Privacy (Mutual, Symmetric)

- **Before acceptance:** A worker browsing leads only sees distance (e.g. "3.2 km away") — never the exact address. Meanwhile, the worker's live GPS location is tracked continuously in the background (for safety/accountability), but this is likewise hidden from the hirer.
- **After acceptance:** Both sides' exact locations are revealed simultaneously — the hirer can see the worker's live location approaching, and the worker sees the job's exact address.
- This symmetry (neither side over-exposed pre-commitment, both revealed post-commitment) is a deliberate trust design, not an oversight.

---

## 6. Geofencing (Job-Centered, Mode A)

- By default, a job posting is only visible to workers within a **10–15 km radius of the job's location**. Workers outside this radius don't see a distant listing — the job simply doesn't appear in their feed at all.
- The hirer can override this with an **"open to all locations"** flag on the job — intended for jobs that don't require physical presence (e.g. remote consulting).
- This is distinct from the **worker-set service radius** used in Mode B (Section 9), which is a different mechanism entirely.

---

## 7. Portfolio Proof (Before/After Documentation)

- After a job is marked complete, a worker can **optionally** (encouraged, not mandatory) upload a before-photo and after-photo, or a video, as proof of the work performed.
- **Consultation-type jobs skip this entirely** — there's nothing physical to document.
- Uploaded proof is **private by default**. The worker separately chooses which pieces of proof to "feature" on their public portfolio — so there's a private raw-documentation layer and a curated public-showcase layer, kept distinct.
- **Retention:** Private (non-featured) proof is kept for a 30-day dispute window, then auto-purged if no complaint was raised. Featured portfolio items are exempt from this and persist indefinitely, since they're the worker's own public showcase, not just dispute evidence.

---

## 8. Job Category & Tag System (Illiteracy-Proof Design)

This is the mechanism that actually solves the "everyone bids on everything, including jobs they can't do, then cancels" problem — using a default-based, opt-in specialization model rather than any category tree that requires reading/classification skill from the average worker.

- **Every worker defaults to a "Misc/General Labor" tag automatically upon completing verification.** No selection screen, no decision required at sign-up.
- **The hirer's job tags are what drive visibility.** Every job must carry 1–3 tags from a fixed list (which includes both specific trade/professional tags like Plumbing, Electrical, Legal Consulting, Tutoring, and the generic Misc tag itself).
- **Visibility rule:** A job appears in a worker's feed only if at least one job tag overlaps with at least one tag on the worker's profile. Since every worker starts on Misc by default, they automatically see Misc-tagged jobs — and nothing tagged with a specialty they never opted into.
- **Specialization is fully opt-in and worker-initiated.** A worker who is, say, a plumber can add "Plumbing" to their own tag list. This is a much lower-friction ask than the earlier icon/category-tree idea, since it only requires a worker to recognize their own trade — not classify unfamiliar work into an unfamiliar taxonomy. Adding a specialty doesn't remove Misc, so a part-time specialist still sees general jobs too.
- **This directly prevents the original problem:** a job tagged only "Legal Consulting" never reaches a worker sitting on the default Misc tag — there's no tag overlap, so it's never shown, not "shown but shouldn't be bid on."
- This same tag system, not a separate category tree, is what also powers Mode B directory filtering (Section 9) — no duplicate taxonomy was built.

---

## 9. Premium Accounts & the Service Directory (Mode B: Search & Book)

A second, parallel discovery mode alongside Mode A bidding — built for professionals/service-based workers (doctors, lawyers, consultants, barbers, MUAs, coaches) who want to be found directly rather than reactively bidding on posted jobs.

- **Directory listing is a premium-only feature**, funded by a **recurring subscription** (monthly/yearly). This keeps the directory from becoming an unfiltered mess — only workers who've actively invested in visibility appear there. Non-premium workers are unaffected in Mode A; premium status has no bearing on bidding ability.
- **A premium worker builds a service menu, not just one rate.** Each entry has a category tag, short description, and a **fixed price** (e.g. "Rs. 1,500/consultation," "Rs. 3,000 home haircut"). Bookings in Mode B are not negotiated — the hirer sees the price and books it directly.
- **Each premium worker sets their own service radius** — a separate mechanism from the job-centered geofence in Mode A. A barber doing house calls might cap it at 8km; a lawyer doing remote consultations might set it to unlimited/remote-only.
- **Premium also unlocks the credentials/portfolio showcase** (degrees, certifications, experience, featured proof photos) — a trust-signal layer that helps a hirer choose between multiple workers offering similar services.
- **The 2.5% hirer discount (leakage prevention):** For Mode B bookings with premium workers only (never Mode A bidding jobs), the platform splits its own 5% commission take — it keeps 2.5% and passes the other 2.5% back to the hirer as a price reduction. The worker's cost is unaffected; they still pay the standard 5% commission regardless of mode. This makes booking *through the app* cheaper than what the same worker would quote someone who found them off-platform, directly countering the risk of hirers finding a worker once via the directory and then transacting privately with them afterward.
- **Mode B booking flow:** hirer browses directory by tag → views a worker's service menu, credentials, portfolio, and public rating → books a specific service at its fixed (discounted) price → this creates a job record flagged as a direct request to that one worker (not broadcast) → the worker can accept or decline based on availability → from there, the job follows the exact same lifecycle as any Mode A job (arrival confirmation, optional proof upload, completion, 5% commission debited).
- **Subscription lapse handling:** Any job already booked/in progress is unaffected. A lapsed subscription only stops the worker from appearing in *future* directory searches — it has no retroactive effect and doesn't touch Mode A bidding eligibility.
- **Premium payment mechanics:** Same simulation approach as wallet top-ups — a real-looking subscription/payment UI is built, but the backend simply grants premium status directly rather than processing real money, consistent with the no-payment-gateway constraint.

---

## 10. Ratings

- Both parties rate each other after a job (mutual), but **only the worker's rating is shown publicly.** The hirer's rating is still collected (useful for internally flagging problem hirers) but never displayed.
- Worker's public profile also shows an **aggregated fare average** and total completed job count — not a per-job fare breakdown. This aggregate acts as a natural deterrent against under-reporting fares to dodge commission (see Section 11).

---

## 11. Wallet, Commission & Monetization

- **Model:** A lead-generation tool running on an in-app token wallet, not a real payment/escrow system. 1 token = Rs. 1.
- **First-job credit:** A new worker receives a **Rs. 500 token credit** applied toward their first job's 5% commission. If the commission owed exceeds Rs. 500, the worker pays the difference themselves (via top-up).
- **Standard commission:** 5% of the agreed fare, debited as tokens from the worker's wallet upon job completion — applies to both Mode A and Mode B (Mode B's *hirer-side* discount doesn't change this worker-side rate; see Section 9).
- **Why the commission can't be gamed:** The fare is locked in during bidding (Mode A) or fixed at listing (Mode B) — before the job starts — so there's no "real" value to misreport after the fact. If a worker still tries to under-report, that low number becomes their public average fare, which just makes future hirers offer them less. The deterrent is reputational, not enforcement-based.
- **Loyalty bonus:** Every time a worker's cumulative lifetime top-up crosses another Rs. 100,000 (100k, 200k, 300k...), they automatically receive a **1,000-token bonus**. This recurs indefinitely, not just once.
- **Account lockout:** A worker's wallet can go into debt for at most one job. If a second job goes unpaid on top of that, the account **locks automatically** — no new leads until the balance is topped up and cleared.
- **Cancellation penalty:** If a worker accepts a job and then cancels or no-shows, a small token penalty is charged.
- **Top-up mechanics:** A real-feeling top-up UI/flow is built (package selection, payment screen), but the backend simply grants tokens directly without processing real money — consistent with the no-payment-gateway academic scope.

---

## 12. Admin Panel

Full CRUD scope, covering:

- **User approvals** — reviewing new signups/profiles.
- **CNIC dispute lookup** — the only point at which a CNIC photo is actually pulled up and manually reviewed by a human, triggered only by a reported dispute.
- **Wallet overrides** — manually adjusting balances or unlocking accounts when needed.
- **Job oversight** — visibility into all jobs and bid history platform-wide.
- **Audit logging** — every admin action (type, target user, notes, timestamp) is logged, so manual overrides remain traceable rather than being a black box.

---

## 13. Scope Exclusions (Explicitly Out of Bounds for the Prototype)

These are deliberate, documented boundaries — not gaps — reflecting the academic project's constraints:

- No live NADRA/government ID database integration — CNIC checks are local format/plausibility checks only (supplemented by the lightweight SIM-name-match deterrent above).
- No real payment gateway — wallet top-ups and premium subscriptions use real-feeling UI flows with simulated backend crediting.
- No facial-recognition/ML-based arrival verification — arrival confirmation is human-judgment based (the hirer confirming identity), not algorithmic.
- No live telecom-level SIM verification beyond standard SMS OTP and the lightweight name-match check.

---

## 13a. Future Roadmap / Post-MVP Considerations (Not Built, Flagged for Legal Review)

These ideas surfaced during a risk-assessment discussion but are **deliberately excluded** from the 8-week prototype, since they involve real money handling and professional-conduct questions that need actual legal counsel, not a design decision made in a planning document:

- **Real-money top-up (JazzCash/bank deposit):** Collecting real customer funds — even manually, even just to demonstrate revenue collection to investors — likely falls under Pakistan's payment-services regulatory framework (State Bank of Pakistan oversight, EMI/PSO licensing). This is a genuine post-graduation business question, not something to build into a solo academic prototype without proper legal review.
- **Splitting the 5% fee into a "hirer service fee" + "worker marketplace fee":** Relabeling the commission doesn't change its underlying economic substance. Whether fee arrangements involving licensed professionals (doctors, lawyers) comply with their professional bodies' codes of conduct (Pakistan Medical Commission, Pakistan Bar Council, etc.) is a real regulatory question a naming convention doesn't resolve on its own.

Both are reasonable to mention in a project write-up as **future direction pending legal review** — not as settled decisions baked into the current data model or commission logic, which remains the original simulated-wallet, flat-5%-commission design from Section 11.

---

## Summary of What's Been Fully Specified

| Area | Status |
|---|---|
| User flows (hirer, worker onboarding, worker job lifecycle, wallet/lockout) | Mapped |
| Admin panel structure | Mapped |
| Data dictionary (Users, Wallets, Wallet Transactions, Jobs, Bids, Ratings, Admin Actions, Job Proof, Platform Config) | Documented |
| ERD (entity relationships) | Documented |
| Geofencing logic (job-centered, Mode A) | Finalized |
| Location privacy (mutual reveal) | Finalized |
| Category/tag filtering (default Misc + opt-in specialization) | Finalized |
| Premium accounts & Mode B directory | Finalized |
| Commission, loyalty bonus, lockout mechanics | Finalized (simulated wallet, unchanged) |
| Media compression & retention (jobs + proof) | Finalized |
| CNIC-SIM name-match fraud deterrent | Finalized (deterrent only, not a legal identity claim) |
| Real-money top-up / semantic fee split | Excluded — Section 13a, pending legal review |

**Now complete:** Data dictionary and ERD have been updated with the tag-based category system, worker services (Mode B menu), premium subscriptions, and the direct-booking/discount fields. Week-by-week 8-week timeline has also been laid out (Planning → Wireframes/setup → Auth/verification → Job posting/bidding → Geofencing/lifecycle → Wallet/commission → Premium/Mode B/admin → Testing/buffer). Phase 1 planning is now fully closed out, with cost-control and fraud-deterrence additions layered in without touching the commission model or introducing real payment handling.
