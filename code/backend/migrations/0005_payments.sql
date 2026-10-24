-- Trust Hire — top-ups that were really paid for.
--
-- Stripe Checkout, in test mode, through the dev server
-- (`code/backend/dev_server/`). A paid top-up carries the Checkout Session it
-- came from, and the one claim this migration makes is that **a payment buys
-- tokens once.** The app makes `creditPayment` idempotent; this makes a
-- second credit impossible however many clients are told the payment landed —
-- the sheet that polled for it, a retried webhook, a second device.

alter table wallet_entries add column payment_id text;

-- Across every wallet, not per wallet: one payment credited to two people is
-- the same mistake as crediting it twice to one.
create unique index wallet_one_top_up_per_payment
  on wallet_entries (payment_id) where payment_id is not null;

-- A payment is what a top-up was bought with. On a commission or a bonus it
-- would be a reference to money that did not move in that direction.
alter table wallet_entries add constraint payment_only_on_a_top_up
  check (payment_id is null or kind = 'topUp');
