# PRD — Stripe payments and the AI fare agent

**Status:** payments built, test mode only, and verified end to end on the
deployed GitHub Pages site against a real Stripe test account. The fare
suggestion is built and runs on the device; **the AI agent is paused** (0.20.0)
and will return running in the browser, not on a server.
**Asked for by:** the project evaluators — "Stripe integration, and an AI agent
for fare recommendation."

## The problem each one solves

**Payments.** Workers buy tokens to cover the 5% commission (Section 11). Until
0.19 the purchase was simulated. A real integration shows the flow works
against a real payment provider without taking real money, which Section 13a
of the POC plan still rules out.

**Fare recommendation.** Section 4 makes the starting fare optional because a
hirer who has no idea what work is worth should not be blocked from asking.
That same hirer is the one who most needs a sensible number — too low and
nobody offers, too high and they overpay. The app already holds what similar
work actually went for; the suggestion turns that into a range, and says what
it rests on. The agent, when it returns, will explain it.

## Requirements

| # | Requirement | Where it is held |
| --- | --- | --- |
| R1 | Top-ups can be paid through Stripe's own checkout page | `top_up_sheet.dart`, `StripePaymentLinks` |
| R2 | No real money can move: only test-mode links are made, from a test key | `stripe_api.key_problem`, `payment_links.py` |
| R3 | No key of any kind is in the site | `stripe_links.dart` holds URLs only; `.env` is git-ignored |
| R4 | A payment buys tokens once, in one wallet | `creditPayment`, `0005_payments.sql`, the mock backend |
| R5 | A hirer can ask for a suggested starting fare | `fare_advice_panel.dart` |
| R6 | The suggestion rests on what similar work went for, and says how many | `FareEvidence`, `FareRange` |
| R7 | An AI model may explain the number but cannot set it outside the evidence | `FareGuard` — in place and tested before the agent returns |
| R8 | Nothing about people is in the evidence | `FareComparable.toJson` |
| R9 | No server is needed for any of it | the site is static; everything else runs on the device |
| R10 | Every fallback says why it happened | the panel's notices, the sheet's notices |
| R11 | The deployed GitHub Pages site takes a Stripe test payment | `StripePaymentLinks`, `StripeReturn`, `payment_links.py` |
| R12 | A return from Stripe credits only a top-up this browser started, once | `StripeReturn.check`, `completeStripeReturn` |

## Non-goals

- **Real money.** Test mode only, until there is a hosted backend, a privacy
  policy and a payments review.
- **A server.** The deployed app is GitHub Pages. 0.19.0 had an optional dev
  server for Stripe Checkout and a local model; nobody was going to run one,
  and 0.20.0 removed it.
- **A hosted AI service.** A hosted model would mean sending job text to a
  third party. That is a privacy decision, not a technical one, and it has not
  been made — the paused work keeps the model behind one interface so a
  premium one can be swapped in later if it is.
- **Setting the fare.** The suggestion never fills the field by itself, and
  workers still counter whatever is posted.

## How it fits

```
Flutter web app (GitHub Pages) ──► Stripe Payment Link (test mode) ──► back to the app
     │
     └── fare suggestion: the device's own jobs, always available
```

The README's [Stripe](../../README.md#stripe-codebackendstripe) and
[Fare suggestions](../../README.md#fare-suggestions) sections have the detail.

## Demonstrating it (about three minutes)

Nothing to set up: open the GitHub Pages link.

1. **Post a job** as Hina Butt. Tag it *Plumbing*, title "Kitchen tap
   leaking". Tap **Suggest a fare**. The range appears with "From *n* agreed
   fares for similar work". Tap **Use** and the fare field fills — nothing
   else changed.
2. **Switch to Usman Raza → Profile → Wallet → Add tokens.** The sheet says
   Stripe test mode and names the test card. Pay Rs. 1,000 with `4242 4242
   4242 4242`. On Stripe's page, **untick "Save my information with Link"**
   first — otherwise Stripe asks for a phone number before it will take the
   payment. Stripe sends the browser back and the balance has moved; reload,
   and it has not moved twice.
3. **Show the guard** if asked how the AI will be kept honest: the test
   `a misplaced zero cannot get through` in `test/fare_advice_test.dart`.

## What it does not establish

- A suggestion from a few dozen seeded jobs is a demonstration of the
  mechanism, not market data. With real use the evidence grows by itself —
  every accepted offer is a new agreed fare.
- Test-mode Stripe proves the integration, not the business: PKR payouts,
  refunds and disputes are all untouched.
- The payment is confirmed by Stripe sending the browser back, not checked by
  a server — a static site cannot hold the key that check needs. A return is
  credited only for a top-up that browser started. A real deployment checks
  the session on its own server.
