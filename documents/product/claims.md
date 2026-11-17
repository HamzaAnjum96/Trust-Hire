# Claims register

Every promise the interface makes to the people using it, and what keeps it
true.

**A sentence on screen is a claim.** "The fare is fixed once you choose" is
only true while `Job.withAcceptedBid` refuses a second acceptance. Change the
rule and the sentence becomes a lie nobody notices. So each claim below names
its string (in `code/frontend/lib/l10n/app_en.arb`) and the rule that keeps it
true: a mutation in `code/frontend/tool/sweep_tests.py`, which breaks the rule
and fails if the tests do not notice.

`test/claims_test.dart` reads the table and fails if a listed string is gone,
or if a listed rule is not in the sweep. A claim with no rule behind it says
`none`, gives the reason in the last column, and is a candidate for one.

**Adding a sentence that promises something?** Add a row. **Changing a
rule?** Read the rows that name it first.

| String | What it promises | Rule | Note |
| --- | --- | --- | --- |
| `fareLocked` | The fare is fixed once the hirer chooses | `fare-lock` | Also held at the server: `the-fare-lock-holds-at-the-server-too` |
| `generalAreaNotice` | Only the general area is shown until a worker is chosen | `location-reveal` | |
| `areaHelp` | The exact spot goes only to the person chosen | `location-reveal` | |
| `exactLocationShown` | The exact spot is shown because these two are working together | `bystander-sees-nothing` | |
| `walletExplanation` | Trust Hire takes 5% of the agreed fare when a job is finished | `commission-rate` | |
| `walletInDebt` | One more job is allowed before the account is paused | `debt-lockout` | |
| `walletLocked` | A paused account cannot take work until it clears what it owes | `wallet-lock-blocks-bidding` | |
| `firstJobCreditWaiting` | The first job's commission is covered, up to an amount | `first-job-credit-cap` | |
| `bookingSaving` | Booking here is cheaper than the worker's own price | `hirer-discount` | Paid from the platform's cut: `mode-b-commission` |
| `notifOfferPassedOver` | A worker is told when another offer was chosen | `a-worker-is-told-they-lost` | |
| `noThreadsMessage` | A conversation opens only once a job is accepted | `no-thread-before-somebody-is-chosen` | |
| `audioOnlyJob` | A job described only by voice says so | `audio-only-is-labelled` | |
| `syncOffline` | Losing the connection loses no work | `offline-keeps-the-queue` | |
| `verifyCnicMaskExplain` | The whole CNIC number is never kept | `cnic-mask` | |
| `verifySimFlagged` | A name mismatch is not a rejection | `sim-mismatch-is-not-a-rejection` | |
| `aiConsentBody` | Nothing is downloaded before the person agrees | `nothing-downloads-before-consent` | "Nothing you type leaves this device" has no mutation: the on-device engine has no network path to test |
| `topUpStripeLinkNotice` | Stripe here is test mode, and no real money moves | `stripe-return-is-test-money-only` | |
| `settingsStorageNotice` | Nothing is uploaded and no account is needed | none | Architecture: there is no backend to upload to. A real backend must rewrite this string |
