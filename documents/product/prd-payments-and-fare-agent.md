# PRD — Stripe payments and the AI fare agent

**Status:** built in 0.19.0, test mode and local model only. Verified end to
end against a real Stripe test account and a local Qwen2.5 1.5B.
**Asked for by:** the project evaluators — "Stripe integration, and an AI agent
for fare recommendation."

## The problem each one solves

**Payments.** Workers buy tokens to cover the 5% commission (Section 11). Until
0.19.0 the purchase was simulated. A real integration shows the flow works
against a real payment provider without taking real money, which Section 13a
of the POC plan still rules out.

**Fare recommendation.** Section 4 makes the starting fare optional because a
hirer who has no idea what work is worth should not be blocked from asking.
That same hirer is the one who most needs a sensible number — too low and
nobody offers, too high and they overpay. The app already holds what similar
work actually went for; the agent turns that into a range, and says why.

## Requirements

| # | Requirement | Where it is held |
| --- | --- | --- |
| R1 | Top-ups can be paid through Stripe Checkout | `top_up_sheet.dart`, `payments.py` |
| R2 | No real money can move: live keys are refused | `payments.key_problem` |
| R3 | The tokens credited are what Stripe charged | `describe_session`, `top_up_sheet.dart` |
| R4 | A payment buys tokens once, in one wallet | `creditPayment`, `0005_payments.sql`, the mock backend |
| R5 | A hirer can ask for a suggested starting fare | `fare_advice_panel.dart` |
| R6 | The suggestion rests on what similar work went for, and says how many | `FareEvidence`, `FareRange` |
| R7 | An AI model may explain the number but cannot set it outside the evidence | `FareGuard`, `fare_agent.guard` |
| R8 | Nothing about people leaves the device; the model runs locally | `FareComparable.toJson`, `.env.example` |
| R9 | With no dev server, everything works as before | `DevServicesController` — empty by default |
| R10 | Every fallback says why it happened | the panel's notices, the sheet's notices |
| R11 | The deployed GitHub Pages site takes a Stripe test payment, with no server and no key in the site | `StripePaymentLinks`, `StripeReturn`, `payment_links.py` |
| R12 | A return from Stripe credits only a top-up this browser started, once | `StripeReturn.check`, `completeStripeReturn` |

## Non-goals

- **Real money.** Test mode only, until there is a hosted backend, a privacy
  policy and a payments review.
- **A hosted AI service.** A hosted model would mean sending job text to a
  third party. The agent speaks the OpenAI-compatible API, so swapping one in
  is a configuration change — but it is a privacy decision, not a technical
  one, and it has not been made.
- **Setting the fare.** The suggestion never fills the field by itself, and
  workers still counter whatever is posted.

## How it fits

```
Flutter app ──(optional, local)──► dev server ──► Stripe API (test mode)
     │                                  └──────► local model (Ollama / LM Studio / llama.cpp)
     └── on-device estimate, always available
```

The README's [dev server section](../../README.md#the-dev-server-codebackenddev_server)
has the set-up steps and the rules in detail.

## Demonstrating it (about five minutes)

Before: `ollama pull qwen2.5:3b`, a Stripe test key in
`code/backend/dev_server/.env` (copied from `.env.example`; it is git-ignored,
and must stay that way — never commit a key, even a test one),
`python3 code/backend/dev_server/server.py`, and
`flutter run -d chrome --dart-define=DEV_SERVER=http://localhost:8787`.

1. **Profile → Dev services.** Show "Connected", "Payments: Stripe test mode"
   and "Fare agent: qwen2.5:3b". This is the whole configuration.
2. **Post a job** as Hina Butt. Tag it *Plumbing*, title "Kitchen tap
   leaking". Tap **Suggest a fare**. The line under the button names the model
   before it is asked; after 10–20 seconds the range appears with "From *n*
   agreed fares for similar work" and the model's reasoning. Tap **Use** and
   the fare field fills — nothing else changed.
3. **Stop the model** (quit Ollama) and ask again. The on-device estimate
   appears with "The fare agent could not reach its model…". The feature
   degrades; it does not break.
4. **Switch to Usman Raza → Wallet → Add tokens.** This step also works on
   the GitHub Pages link with nothing running locally — it uses a Payment Link
   there (see *What it does not establish*). The sheet says Stripe test
   mode and names the test card. Pay Rs. 1,000 with `4242 4242 4242 4242`.
   On Stripe's page, **untick "Save my information with Link"** first —
   otherwise Stripe asks for a phone number before it will take the payment.
   Back in the app the balance moves within a few seconds.
5. **Show the guard** if asked how the AI is kept honest: the test
   `a misplaced zero cannot get through` in `test/fare_advice_test.dart`, and
   the same case in `code/backend/dev_server/test_dev_server.py`.

## What it does not establish

- A suggestion from a few dozen seeded jobs is a demonstration of the
  mechanism, not market data. With real use the evidence grows by itself —
  every accepted offer is a new agreed fare.
- A 1.5B–3B model's reasoning is sometimes thin, and below 7B it often answers
  in English when asked in Urdu. The number is guarded; the prose is not.
- Test-mode Stripe proves the integration, not the business: PKR payouts,
  refunds and disputes are all untouched.
- On the GitHub Pages site the payment is confirmed by Stripe sending the
  browser back, not checked by a server — a static site cannot hold the key
  that check needs. A return is credited only for a top-up that browser
  started; the dev server path is the one that asks Stripe.
