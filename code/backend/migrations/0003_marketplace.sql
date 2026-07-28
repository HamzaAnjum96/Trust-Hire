-- Trust Hire — bids, ratings, the wallet, and the directory.
--
-- Phase 1 Sections 4, 9, 10 and 11. Two structural claims from the app carry
-- over unchanged, and both are the reason their sections can be trusted:
--
--   * **one accepted bid per job**, so an agreed fare always has exactly one
--     offer behind it;
--   * **the wallet is a ledger and nothing else**, so there is no balance
--     column to disagree with the entries that produced it.

-- ---------------------------------------------------------------------------
-- Bidding (Section 4)
-- ---------------------------------------------------------------------------

create type bid_status as enum ('offered', 'accepted', 'passedOver', 'withdrawn');

create table bids (
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references jobs (id) on delete cascade,
  worker_id   uuid not null references profiles (id),

  fare        integer not null check (fare > 0),

  -- Optional. A worker who cannot write should be able to bid with a number
  -- alone — the same rule the posting form follows.
  message     text,

  status      bid_status not null default 'offered',
  created_at  timestamptz not null default now(),

  -- A revised offer replaces the old one; two live bids from one worker would
  -- let them occupy a hirer's list twice, and there is no honest way to show
  -- that.
  unique (job_id, worker_id)
);

-- One winner, ever.
create unique index bids_one_accepted_per_job
  on bids (job_id) where status = 'accepted';

-- The agreed fare must be the accepted bid's fare.
--
-- The app writes the two together and the tests check they agree. Here they
-- *cannot* disagree, which matters because Section 11 charges a commission on
-- one of them and pays the other to a person.
create or replace function agreed_fare_matches_bid() returns trigger
  language plpgsql as $$
declare
  job_fare integer;
  job_worker uuid;
begin
  if new.status <> 'accepted' then return new; end if;

  select agreed_fare, accepted_worker_id into job_fare, job_worker
  from jobs where id = new.job_id;

  if job_fare is distinct from new.fare or job_worker is distinct from new.worker_id then
    raise exception
      'the accepted bid must match the job''s agreed fare and chosen worker '
      '(job %)', new.job_id;
  end if;

  return new;
end;
$$;

create constraint trigger bids_agree_with_the_job
  after insert or update on bids
  deferrable initially deferred
  for each row execute function agreed_fare_matches_bid();

create index bids_job on bids (job_id);
create index bids_worker on bids (worker_id);

-- ---------------------------------------------------------------------------
-- Ratings (Section 10)
-- ---------------------------------------------------------------------------
--
-- **The asymmetry is the whole section.** Both sides rate each other; only the
-- worker's score is ever shown. `rated_side` is what makes that enforceable
-- rather than remembered — see the view at the end, which is the only thing
-- any public screen is meant to read.

create type rated_side as enum ('worker', 'hirer');

create table ratings (
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references jobs (id) on delete cascade,
  side        rated_side not null,
  stars       smallint not null check (stars between 1 and 5),

  -- Collected for the admin panel, never shown beside the public average.
  -- Section 10 gives no free-text review, and a five-star average with a
  -- paragraph under it is a review site.
  note        text,
  created_at  timestamptz not null default now(),

  -- Once each, per side. Nobody rates twice.
  unique (job_id, side)
);

-- Only a finished job can be rated. A cancelled one is deliberately excluded:
-- nobody did any work, and a one-star for a job that never happened is a
-- weapon rather than a signal.
create or replace function rating_needs_finished_work() returns trigger
  language plpgsql as $$
begin
  if (select status from jobs where id = new.job_id) <> 'completed' then
    raise exception 'only a completed job can be rated (job %)', new.job_id;
  end if;
  return new;
end;
$$;

create trigger ratings_only_on_finished_work
  before insert on ratings
  for each row execute function rating_needs_finished_work();

-- ---------------------------------------------------------------------------
-- The wallet (Section 11)
-- ---------------------------------------------------------------------------
--
-- **A ledger, and nothing else.** No balance column anywhere. Balance,
-- lifetime top-up, debt and the lockout are all derived by replaying this
-- table, which is why the sprint's "cannot reach an inconsistent state" is
-- structural: there is no second number to drift.

create type wallet_entry_kind as enum (
  'topUp', 'commission', 'firstJobCredit', 'loyaltyBonus',
  'cancellationPenalty', 'adminAdjustment'
);

create table wallet_entries (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references profiles (id) on delete cascade,
  kind        wallet_entry_kind not null,

  -- Signed. Positive adds, negative takes. Whole tokens; 1 token is Rs. 1.
  tokens      integer not null check (tokens <> 0),

  job_id      uuid references jobs (id) on delete set null,
  created_at  timestamptz not null default now(),

  -- A commission is charged once per job. The app makes `recordCompletion`
  -- idempotent; this makes a double charge impossible however it is called.
  constraint charge_direction_matches_kind check (
    case kind
      when 'topUp' then tokens > 0
      when 'firstJobCredit' then tokens > 0
      when 'loyaltyBonus' then tokens > 0
      when 'commission' then tokens < 0
      when 'cancellationPenalty' then tokens < 0
      else true            -- an admin adjustment goes either way
    end
  )
);

create unique index wallet_one_commission_per_job
  on wallet_entries (profile_id, job_id) where kind = 'commission';

create unique index wallet_one_penalty_per_job
  on wallet_entries (profile_id, job_id) where kind = 'cancellationPenalty';

create unique index wallet_one_first_job_credit
  on wallet_entries (profile_id) where kind = 'firstJobCredit';

create index wallet_entries_owner on wallet_entries (profile_id, created_at);

-- Nothing is ever edited or removed. A record that can be rewritten after the
-- fact is a record nobody can rely on — the same argument as the audit log.
create or replace function ledgers_are_append_only() returns trigger
  language plpgsql as $$
begin
  raise exception
    'wallet entries are append-only: correct a mistake with an '
    'adminAdjustment entry, which leaves both the error and the fix visible '
    'to the worker';
end;
$$;

create trigger wallet_entries_no_update
  before update or delete on wallet_entries
  for each row execute function ledgers_are_append_only();

-- ---------------------------------------------------------------------------
-- The directory (Section 9)
-- ---------------------------------------------------------------------------

create type subscription_plan as enum ('monthly', 'yearly');

create table directory_listings (
  profile_id            uuid primary key references profiles (id) on delete cascade,

  plan                  subscription_plan,
  subscribed_at         timestamptz,

  -- The whole of the lapse rule is a comparison against this. A boolean would
  -- need somebody to remember to clear it, and it would still be set a year
  -- after the money stopped.
  expires_at            timestamptz,

  headline              text,

  -- Section 9 is explicit that this is separate from the job-centered geofence
  -- in Mode A: there the hirer decides how far to cast, here the worker
  -- decides how far to go.
  service_radius_metres double precision not null default 10000
                        check (service_radius_metres > 0),
  remote_only           boolean not null default false,

  constraint subscription_is_whole
    check ((plan is null) = (expires_at is null))
);

create table service_offerings (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references directory_listings (profile_id)
                on delete cascade,
  tag_id        text not null references job_tags (id),
  title         text not null check (length(trim(title)) > 0),
  description   text,

  -- Fixed, and shown before booking. The difference between Mode B and Mode A
  -- is exactly this column being not-null.
  price_rupees  integer not null check (price_rupees > 0)
);

create type credential_kind as enum (
  'qualification', 'certification', 'experience', 'membership'
);

create table worker_credentials (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references directory_listings (profile_id)
              on delete cascade,
  kind        credential_kind not null,
  title       text not null check (length(trim(title)) > 0),
  issuer      text,
  year        smallint check (year between 1900 and 2200)
);

comment on table worker_credentials is
  'Self-declared, and every screen showing these says so. Section 2 verifies '
  'a CNIC and a phone number; it does not verify a degree.';

create index service_offerings_tag on service_offerings (tag_id);

-- ---------------------------------------------------------------------------
-- What a worker's public record is
-- ---------------------------------------------------------------------------
--
-- **The only thing a public screen should read.** It cannot expose a hirer's
-- rating, because it never selects one — which makes Section 10's asymmetry a
-- property of the query rather than a rule each screen has to remember.
--
-- The fare average comes from the jobs rather than from the ratings, because a
-- worker who was never rated has still been paid. It is aggregated and never
-- broken down per job: that aggregate is what makes under-reporting a fare
-- self-defeating, since the worker lowers the figure future hirers anchor on.
create view worker_standing as
select
  p.id                                                as profile_id,
  count(distinct j.id)                                as completed_jobs,
  avg(r.stars) filter (where r.side = 'worker')       as average_stars,
  floor(avg(j.agreed_fare))::integer                  as average_fare
from profiles p
left join jobs j
  on j.accepted_worker_id = p.id and j.status = 'completed'
left join ratings r
  on r.job_id = j.id and r.side = 'worker'
group by p.id;

comment on view worker_standing is
  'Three numbers and nothing else. A per-job breakdown would undo the '
  'deterrent the aggregate creates.';
