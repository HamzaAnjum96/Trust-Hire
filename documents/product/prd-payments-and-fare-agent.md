# PRD — Stripe payments and the AI fare agent

**Status:** payments built, test mode only, and verified end to end on the
deployed GitHub Pages site against a real Stripe test account. The fare
suggestion is built and runs on the device. **The AI agent is back** (0.22.0,
after a pause in 0.20.0), running in the visitor's own browser rather than on
a server, together with "Ask Trust Hire", an assistant for finding jobs and
workers.
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
it rests on. The agent explains it.

## Requirements

| # | Requirement | Where it is held |
| --- | --- | --- |
| R1 | Top-ups can be paid through Stripe's own checkout page | `top_up_sheet.dart`, `StripePaymentLinks` |
| R2 | No real money can move: only test-mode links are made, from a test key | `stripe_api.key_problem`, `payment_links.py` |
| R3 | No key of any kind is in the site | `stripe_links.dart` holds URLs only; `.env` is git-ignored |
| R4 | A payment buys tokens once, in one wallet | `creditPayment`, `0005_payments.sql`, the mock backend |
| R5 | A hirer can ask for a suggested starting fare | `fare_advice_panel.dart` |
| R6 | The suggestion rests on what similar work went for, and says how many | `FareEvidence`, `FareRange` |
| R7 | An AI model may explain the number but cannot set it outside the evidence | `FareGuard`; `FareAdvisor` sets aside an answer that used no evidence or lands outside the band |
| R8 | Nothing about people is in the evidence | `FareComparable.toJson` |
| R9 | No server is needed for any of it | the site is static; everything else runs on the device |
| R10 | Every fallback says why it happened | the panel's notices, the sheet's notices |
| R11 | The deployed GitHub Pages site takes a Stripe test payment | `StripePaymentLinks`, `StripeReturn`, `payment_links.py` |
| R12 | A return from Stripe credits only a top-up this browser started, once | `StripeReturn.check`, `completeStripeReturn` |
| R13 | The AI downloads nothing until somebody switches it on, having been told the size | `AiController`, `ai_consent.dart` |
| R14 | The assistant answers about open jobs and directory workers only, from the app's own data and visibility rules | `AssistantEngine`, `AssistantSearch` |
| R15 | A model cannot show a job or worker no search returned, and cannot do worse than the word list | `AssistantEngine` — matched by id; overruled or set aside |
| R16 | A premium model can replace the on-device one without touching any feature | `AiModel`, `RemoteModel` behind a build flag |

## Non-goals

- **Real money.** Test mode only, until there is a hosted backend, a privacy
  policy and a payments review.
- **A server.** The deployed app is GitHub Pages. 0.19.0 had an optional dev
  server for Stripe Checkout and a local model; nobody was going to run one,
  and 0.20.0 removed it.
- **A hosted AI service.** A hosted model would mean sending job text to a
  third party. That is a privacy decision, not a technical one, and it has not
  been made — the model sits behind one interface, `AiModel`, and
  `RemoteModel` is ready behind a build flag if it is.
- **Setting the fare.** The suggestion never fills the field by itself, and
  workers still counter whatever is posted.

## How it fits

```
Flutter web app (GitHub Pages) ──► Stripe Payment Link (test mode) ──► back to the app
     │
     ├── fare suggestion: the device's own jobs, always available
     └── on-device AI (WebLLM, WebGPU) ── only once switched on ──► explains the
         fare, answers "Ask Trust Hire"; a word list answers without it
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
3. **Ask Trust Hire** — the Ask button on the Jobs list. Tap "Who can fix
   wiring?", then type `rang ka kaam chahiye`. Works on any browser: without
   the AI, a word list answers and says so.
4. **The AI**, on desktop Chrome or Edge (WebGPU): Profile → On-device AI →
   choose the 0.5B model → turn it on (about 300 MB, once). Ask the same
   questions; the answer is signed by the model. On the posting form, tap
   **Explain it with the on-device AI** under the suggestion.
5. **Show how it is kept honest** if asked: in `test/assistant_test.dart`,
   `a model cannot put a job on screen that no search returned` and
   `where the word list understood, a model that searched for something else
   is overruled`; in `test/fare_advice_test.dart`, `an answer given without
   looking at the evidence is set aside` — each written from what Qwen2.5 1.5B
   actually did when the code was run against it.

## What it does not establish

- A suggestion from a few dozen seeded jobs is a demonstration of the
  mechanism, not market data. With real use the evidence grows by itself —
  every accepted offer is a new agreed fare.
- Test-mode Stripe proves the integration, not the business: PKR payouts,
  refunds and disputes are all untouched.
- A model small enough for a browser is a demonstration of where the AI sits
  and how it is held, not of what a good model would say. Its sentences can
  still be clumsy or wrong about a detail; the results under them, and the
  app's own sentence beneath, cannot. The 1.5B model was run against the real
  code before shipping, and the browser path — WebLLM from its CDN, the 0.5B
  download, a reply held to its schema — in headless Chromium on a software
  GPU, where one short reply took eleven minutes. The app's own screens ran
  the same way, end to end: the 0.5B model searched correctly, and its answer
  — 55 minutes later — was its own instructions read back, which the app now
  refuses to show. A real GPU, and a phone with WebGPU, have not been tried.
- The payment is confirmed by Stripe sending the browser back, not checked by
  a server — a static site cannot hold the key that check needs. A return is
  credited only for a top-up that browser started. A real deployment checks
  the session on its own server.
