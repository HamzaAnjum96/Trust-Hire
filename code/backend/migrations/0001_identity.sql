-- Trust Hire — identity, roles and verification.
--
-- Phase 1 Sections 2 and 8. This is the first migration because everything
-- else references it: a job has a poster, a bid has a worker, a wallet entry
-- has an owner.
--
-- **Supabase's `auth.users` is the account.** This schema deliberately does
-- not invent its own password or session table — the app has never had one,
-- Section 13a excludes authentication from the prototype, and rolling a second
-- identity store beside a managed one is how two of them end up disagreeing
-- about who somebody is. `profiles.id` is the auth user's id and nothing else.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- The fixed tag vocabulary (Section 8)
-- ---------------------------------------------------------------------------
--
-- A table rather than a Postgres enum. The list is closed *today* and adding
-- to it is a product decision, but an enum makes that a migration with an
-- exclusive lock, and a lookup table makes it a row — and lets the label live
-- next to the id instead of in the client only.
--
-- The ids match `JobTag.id` in the app exactly. They are the storage contract:
-- renaming a label must never orphan a job.
create table job_tags (
  id           text primary key,
  sort_order   integer not null,
  is_default   boolean not null default false
);

comment on column job_tags.is_default is
  'True for the tag every worker holds and cannot remove — Section 8''s '
  '"general work". Exactly one row should have this set.';

create unique index job_tags_one_default
  on job_tags (is_default) where is_default;

insert into job_tags (id, sort_order, is_default) values
  ('plumbing', 10, false),
  ('electrical', 20, false),
  ('painting', 30, false),
  ('carpentry', 40, false),
  ('masonry', 50, false),
  ('construction', 60, false),
  ('applianceRepair', 70, false),
  ('cleaning', 80, false),
  ('moving', 90, false),
  ('driving', 100, false),
  ('gardening', 110, false),
  ('tailoring', 120, false),
  ('cooking', 130, false),
  ('tutoring', 140, false),
  ('security', 150, false),
  ('legal', 160, false),
  ('medical', 170, false),
  ('beauty', 180, false),
  ('misc', 190, true);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

create type user_role as enum ('worker', 'hirer');

create type review_status as enum ('pending', 'approved', 'suspended');

create table profiles (
  id             uuid primary key,
  display_name   text not null check (length(trim(display_name)) > 0),

  -- A neighbourhood and a city, never an address. The same granularity the
  -- app has always shown, and the reason there is no street column: a field
  -- that exists gets filled in, and Section 5 spends its whole length keeping
  -- exact locations away from people who have not been chosen yet.
  area           text,

  role           user_role not null default 'worker',
  headline       text,

  -- Section 12's approval state. Not a soft delete: a suspended account keeps
  -- its history, because oversight of somebody whose record vanished is not
  -- oversight.
  status         review_status not null default 'pending',
  status_note    text,
  status_at      timestamptz,

  created_at     timestamptz not null default now()
);

comment on table profiles is
  'One row per authenticated account. `id` is the Supabase auth user id.';

-- The trades a worker has opted into (Section 8).
--
-- A join table rather than an array column, so the visibility rule is a join
-- rather than an array-overlap operator the planner cannot index as well —
-- and so a tag can never be a string nobody recognises.
create table worker_tags (
  profile_id  uuid not null references profiles (id) on delete cascade,
  tag_id      text not null references job_tags (id),
  primary key (profile_id, tag_id)
);

-- Every worker holds the default tag and cannot lose it. Enforced here rather
-- than in the client because the whole of Section 8 rests on it: a worker with
-- no tags has an empty feed forever, and no screen would explain why.
create or replace function grant_default_tag() returns trigger
  language plpgsql as $$
begin
  insert into worker_tags (profile_id, tag_id)
  select new.id, id from job_tags where is_default
  on conflict do nothing;
  return new;
end;
$$;

create trigger profiles_grant_default_tag
  after insert on profiles
  for each row execute function grant_default_tag();

create or replace function refuse_default_tag_removal() returns trigger
  language plpgsql as $$
begin
  if exists (select 1 from job_tags where id = old.tag_id and is_default) then
    raise exception
      'the default tag cannot be removed: a worker without it has an empty '
      'feed and nothing on screen can explain why';
  end if;
  return old;
end;
$$;

create trigger worker_tags_keep_default
  before delete on worker_tags
  for each row execute function refuse_default_tag_removal();

-- ---------------------------------------------------------------------------
-- Verification (Section 2)
-- ---------------------------------------------------------------------------
--
-- **These are signals, not identity.** Section 13 rules out any live NADRA
-- lookup, so the strongest claim available is that a number is the right shape
-- and a phone answered an OTP. The column names say `plausible` and `matches`
-- rather than `verified` for that reason.
create table verifications (
  profile_id        uuid primary key references profiles (id) on delete cascade,

  -- The whole number is never stored. What is kept is enough for an admin to
  -- match a document against a claim during a dispute, and no more.
  cnic_masked       text,
  cnic_name         text,
  cnic_plausible    boolean not null default false,
  cnic_submitted_at timestamptz,

  phone_e164        text,
  phone_verified_at timestamptz,

  -- Section 2's cheap fraud deterrent. False means *review*, never reject:
  -- a worker on a family member's SIM is the ordinary case.
  sim_name_matches  boolean not null default true,

  constraint cnic_number_is_masked
    check (cnic_masked is null or cnic_masked like '%*%')
);

comment on constraint cnic_number_is_masked on verifications is
  'A full CNIC must never reach this table. The app has no use for one and '
  'Section 13 rules out looking one up, so storing it would be holding a '
  'national identity number for no reason anybody could name.';
