-- Trust Hire — jobs, their tags, and their life.
--
-- Phase 1 Sections 3, 4, 6 and 7. The load-bearing decisions here are the two
-- the app already enforces on the model and which have to survive the move to
-- a server, because a client-side rule is a rule until somebody writes a
-- different client:
--
--   * the agreed fare is written **once**, at acceptance;
--   * a job with no worker has no agreed fare.

create type job_status as enum (
  'open', 'accepted', 'inProgress', 'completed', 'cancelled', 'expired'
);

create table jobs (
  id                uuid primary key default gen_random_uuid(),
  posted_by         uuid not null references profiles (id),

  -- Section 3: missing information is acceptable. Only the place and the time
  -- it was posted are required, because the poster may have spoken rather than
  -- typed — which is the product's entire premise.
  title             text,
  short_description text,

  latitude          double precision not null check (latitude between -90 and 90),
  longitude         double precision not null check (longitude between -180 and 180),
  area              text,

  -- The circle the map draws. Approximate on purpose (Section 5).
  radius_metres     double precision not null default 1000 check (radius_metres > 0),

  -- Section 6. Null means the platform default; the app reads 12 km.
  geofence_metres   double precision check (geofence_metres > 0),
  open_to_all       boolean not null default false,

  scheduled_at      timestamptz,
  contact_number    text,

  starting_fare     integer check (starting_fare > 0),
  agreed_fare       integer check (agreed_fare > 0),

  -- Mode B (Section 9). Set together with `listed_fare` or not at all.
  booked_worker_id  uuid references profiles (id),
  listed_fare       integer check (listed_fare > 0),

  accepted_worker_id uuid references profiles (id),
  status            job_status not null default 'open',

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  -- Nobody works for themselves. The app refuses this in three places
  -- (bidding, booking, the lifecycle); here it is one line that no client can
  -- get around.
  constraint worker_is_not_the_hirer
    check (accepted_worker_id is distinct from posted_by
           and booked_worker_id is distinct from posted_by),

  -- Section 4: the fare is fixed *by acceptance*. A job nobody has been chosen
  -- for cannot carry an agreed price, because there is nobody who agreed to it.
  constraint agreed_fare_needs_a_worker
    check (agreed_fare is null or accepted_worker_id is not null
           or booked_worker_id is not null),

  -- A Mode B booking carries both numbers: what the worker listed, and what
  -- the hirer pays after the platform's 2.5%. One without the other would make
  -- the commission uncomputable.
  constraint booking_carries_both_fares
    check ((booked_worker_id is null) = (listed_fare is null)),

  -- Section 7's ordering, as far as a row can express it: anything past `open`
  -- has somebody on it, except the two ways a job ends without one.
  constraint live_statuses_have_a_worker
    check (status in ('open', 'cancelled', 'expired')
           or accepted_worker_id is not null)
);

comment on column jobs.agreed_fare is
  'Written once, at acceptance. See the trigger below — Section 11''s '
  'commission is trustworthy only while this is the number both sides agreed '
  'to, so nothing may edit it afterwards.';

-- **The fare lock.**
--
-- `Job.withAcceptedBid` is the app's only writer of this column and refuses to
-- run twice. That is a promise one client keeps. This is the same promise the
-- database keeps, for every client there will ever be.
create or replace function refuse_fare_rewrite() returns trigger
  language plpgsql as $$
begin
  if old.agreed_fare is not null and new.agreed_fare is distinct from old.agreed_fare then
    raise exception
      'the agreed fare is fixed at acceptance and cannot be changed (job %)',
      old.id;
  end if;

  if old.accepted_worker_id is not null
     and new.accepted_worker_id is distinct from old.accepted_worker_id then
    raise exception
      'the chosen worker cannot be swapped after acceptance (job %)', old.id;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger jobs_fare_is_locked
  before update on jobs
  for each row execute function refuse_fare_rewrite();

-- 1 to 3 tags, required (Section 8).
create table job_tag_links (
  job_id  uuid not null references jobs (id) on delete cascade,
  tag_id  text not null references job_tags (id),
  primary key (job_id, tag_id)
);

create or replace function enforce_tag_count() returns trigger
  language plpgsql as $$
declare
  total integer;
  target uuid := coalesce(new.job_id, old.job_id);
begin
  select count(*) into total from job_tag_links where job_id = target;

  if total > 3 then
    raise exception 'a job carries at most 3 tags (job %)', target;
  end if;

  return null;
end;
$$;

-- Deferred, so that *replacing* a job's tags can go through an intermediate
-- state. Editing a job writes the new set and removes the old one, and the two
-- orders that involves — insert-then-delete, or a swap done tag by tag — would
-- otherwise depend on which statement ran first rather than on what the job
-- ends up with.
create constraint trigger job_tag_links_at_most_three
  after insert or delete on job_tag_links
  deferrable initially deferred
  for each row execute function enforce_tag_count();

-- Media, kept out of the job row.
--
-- Section 3 allows several photos and one voice note, and a row that grew an
-- array of storage paths would make retention (Section 13's media rules, due
-- with the storage bucket) a string-surgery problem.
create type media_kind as enum ('photo', 'voiceNote');

create table job_media (
  id           uuid primary key default gen_random_uuid(),
  job_id       uuid not null references jobs (id) on delete cascade,
  kind         media_kind not null,
  storage_path text not null,
  duration_ms  integer check (duration_ms > 0),
  position     integer not null default 0,

  -- The text alternative WCAG 1.2.1 asks for. Null until transcription runs;
  -- the app labels an audio-only job as such in the meantime rather than
  -- pretending it has one.
  transcript   text,

  constraint only_audio_has_a_duration
    check (kind = 'voiceNote' or duration_ms is null)
);

create unique index job_media_one_voice_note
  on job_media (job_id) where kind = 'voiceNote';

create index jobs_status_created on jobs (status, created_at desc);
create index jobs_posted_by on jobs (posted_by);
create index jobs_accepted_worker on jobs (accepted_worker_id)
  where accepted_worker_id is not null;
create index jobs_booked_worker on jobs (booked_worker_id)
  where booked_worker_id is not null;
