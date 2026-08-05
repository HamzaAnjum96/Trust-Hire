-- Trust Hire — what the schema refuses.
--
-- Run by `tool/verify_schema.sh`, which builds a throwaway database from
-- `migrations/` and then executes this file. Every block below is a rule the
-- app already enforces in Dart; the point of repeating it here is that a
-- client-side rule holds until somebody writes a different client, and four of
-- these decide what money changes hands or who sees somebody's identity
-- document.
--
-- The style is deliberate: each check either raises (and fails the run) or
-- notices. There is no test framework because there is no application here to
-- carry one — this is a schema, and `psql -v ON_ERROR_STOP=1` is enough.

\set ON_ERROR_STOP on
\set QUIET on
set client_min_messages to notice;

-- Procedures rather than functions, purely so the transcript reads as a list of
-- rules rather than as fifty single-column result tables.
--
-- `must_fail` asserts a statement *is* refused. Anything that succeeds when it
-- should not is the failure this file exists to catch.
--
-- **`set constraints all immediate` is load-bearing.** Two of the rules below
-- are deferred constraint triggers, which normally fire at commit — long after
-- this block has returned, and outside any exception handler that could see
-- them. Without this line a deferred rule looks like a rule the schema does not
-- have, which is exactly the false negative this file is meant to make
-- impossible.
-- The SQLSTATE is printed rather than swallowed, and a statement the *server*
-- could not make sense of is re-raised rather than counted. Otherwise renaming
-- a column would quietly turn every check that touches it into a pass — a test
-- suite that goes green precisely when the schema stops matching it.
create or replace procedure must_fail(statement text, why text)
  language plpgsql as $$
declare
  state text;
begin
  begin
    execute statement;
    set constraints all immediate;
  exception
    when syntax_error_or_access_rule_violation or invalid_text_representation then
      raise;
    when others then
      get stacked diagnostics state = returned_sqlstate;
      raise notice '  refused [%]: %', state, why;
      return;
  end;
  raise exception 'NOT REFUSED: % — the statement succeeded: %', why, statement;
end;
$$;

create or replace procedure must_work(statement text, what text)
  language plpgsql as $$
begin
  execute statement;
  set constraints all immediate;
  raise notice '  allowed: %', what;
end;
$$;

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------

insert into profiles (id, display_name, area, role, status) values
  ('11111111-1111-1111-1111-111111111111', 'Hina Butt', 'F-7, Islamabad', 'hirer', 'approved'),
  ('22222222-2222-2222-2222-222222222222', 'Usman Raza', 'Johar Town, Lahore', 'worker', 'approved'),
  ('33333333-3333-3333-3333-333333333333', 'Bilal Awan', 'Gulshan-e-Iqbal, Karachi', 'worker', 'approved'),
  ('44444444-4444-4444-4444-444444444444', 'Trust Hire staff', null, 'hirer', 'approved');

insert into jobs (id, posted_by, title, latitude, longitude, starting_fare)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111',
        'Fan making noise', 33.7104, 73.0551, 2000);

insert into job_tag_links (job_id, tag_id)
values ('aaaaaaaa-0000-0000-0000-000000000001', 'electrical');

\echo '== Section 8 — the tag vocabulary'

call must_work(
  $$insert into worker_tags (profile_id, tag_id)
    values ('22222222-2222-2222-2222-222222222222', 'electrical')$$,
  'a worker opts into a trade');

call must_fail(
  $$delete from worker_tags
    where profile_id = '22222222-2222-2222-2222-222222222222' and tag_id = 'misc'$$,
  'removing general work, which would empty the feed forever');

call must_fail(
  $$insert into worker_tags (profile_id, tag_id)
    values ('22222222-2222-2222-2222-222222222222', 'not-a-trade')$$,
  'a tag outside the fixed vocabulary');

do $$
begin
  if not exists (
    select 1 from worker_tags
    where profile_id = '33333333-3333-3333-3333-333333333333' and tag_id = 'misc'
  ) then
    raise exception 'every worker should hold the default tag from the start';
  end if;
  raise notice '  granted: general work, automatically, on sign-up';
end;
$$;

\echo '== Section 4 — the fare is fixed at acceptance'

call must_fail(
  $$update jobs set agreed_fare = 1800
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'an agreed fare on a job with nobody chosen');

call must_work(
  $$update jobs
    set accepted_worker_id = '22222222-2222-2222-2222-222222222222',
        agreed_fare = 1800,
        status = 'accepted'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'choosing a worker and locking the fare together');

call must_fail(
  $$update jobs set agreed_fare = 9000
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'rewriting the agreed fare afterwards');

call must_fail(
  $$update jobs set accepted_worker_id = '33333333-3333-3333-3333-333333333333'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'swapping the chosen worker afterwards');

call must_fail(
  $$insert into jobs (posted_by, accepted_worker_id, latitude, longitude, status,
                      agreed_fare)
    values ('11111111-1111-1111-1111-111111111111',
            '11111111-1111-1111-1111-111111111111', 33.7, 73.0, 'accepted', 500)$$,
  'somebody working for themselves');

\echo '== Section 4 — one winner per job'

insert into bids (job_id, worker_id, fare, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', 1800, 'accepted'),
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '33333333-3333-3333-3333-333333333333', 1600, 'passedOver');

call must_fail(
  $$update bids set status = 'accepted'
    where job_id = 'aaaaaaaa-0000-0000-0000-000000000001'
      and worker_id = '33333333-3333-3333-3333-333333333333'$$,
  'a second accepted bid on one job');

call must_fail(
  $$insert into bids (job_id, worker_id, fare)
    values ('aaaaaaaa-0000-0000-0000-000000000001',
            '33333333-3333-3333-3333-333333333333', 1500)$$,
  'a worker holding two live offers on one job');

-- The winning bid and the job have to say the same number. Section 11 charges
-- commission on one of them and pays the other to a person, so a disagreement
-- here is a disagreement about money.
insert into jobs (id, posted_by, accepted_worker_id, agreed_fare, status,
                  latitude, longitude)
values ('aaaaaaaa-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111',
        '33333333-3333-3333-3333-333333333333', 1000, 'accepted', 31.5204, 74.3587);

call must_fail(
  $$insert into bids (job_id, worker_id, fare, status)
    values ('aaaaaaaa-0000-0000-0000-000000000003',
            '33333333-3333-3333-3333-333333333333', 1200, 'accepted')$$,
  'a winning bid for a fare the job does not record');

call must_fail(
  $$insert into bids (job_id, worker_id, fare, status)
    values ('aaaaaaaa-0000-0000-0000-000000000003',
            '22222222-2222-2222-2222-222222222222', 1000, 'accepted')$$,
  'a winning bid from somebody other than the chosen worker');

call must_work(
  $$insert into bids (job_id, worker_id, fare, status)
    values ('aaaaaaaa-0000-0000-0000-000000000003',
            '33333333-3333-3333-3333-333333333333', 1000, 'accepted')$$,
  'the winning bid, agreeing with the job on both counts');

\echo '== Section 3 — what a job carries'

call must_work(
  $$insert into job_media (job_id, kind, storage_path, duration_ms)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'voiceNote',
            'jobs/aaa1/note.m4a', 9000)$$,
  'a voice note describing the work');

call must_fail(
  $$insert into job_media (job_id, kind, storage_path, duration_ms)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'voiceNote',
            'jobs/aaa1/note-2.m4a', 4000)$$,
  'a second voice note on one job');

call must_fail(
  $$insert into job_media (job_id, kind, storage_path, duration_ms)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'photo',
            'jobs/aaa1/photo.jpg', 4000)$$,
  'a photograph with a playing time');

call must_work(
  $$insert into job_media (job_id, kind, storage_path, position) values
      ('aaaaaaaa-0000-0000-0000-000000000001', 'photo', 'jobs/aaa1/1.jpg', 0),
      ('aaaaaaaa-0000-0000-0000-000000000001', 'photo', 'jobs/aaa1/2.jpg', 1)$$,
  'several photographs of the same job');

\echo '== Section 8 — at most three tags'

call must_fail(
  $$insert into job_tag_links (job_id, tag_id) values
      ('aaaaaaaa-0000-0000-0000-000000000001', 'plumbing'),
      ('aaaaaaaa-0000-0000-0000-000000000001', 'carpentry'),
      ('aaaaaaaa-0000-0000-0000-000000000001', 'painting')$$,
  'a fourth tag on a job');

\echo '== Section 10 — ratings'

call must_fail(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'worker', 5)$$,
  'rating a job that has not finished');

update jobs set status = 'completed'
  where id = 'aaaaaaaa-0000-0000-0000-000000000001';

call must_work(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'worker', 5)$$,
  'rating a finished job');

call must_fail(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'worker', 1)$$,
  'the same side rating twice');

call must_work(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'hirer', 2)$$,
  'the other side rating, independently');

-- Deliberately a job with no rating on it yet. Aimed at job ...001 this check
-- passes for the wrong reason — the once-per-side rule refuses it before the
-- range is ever consulted — and would go on passing with the range removed.
update jobs set status = 'completed'
  where id = 'aaaaaaaa-0000-0000-0000-000000000003';

call must_fail(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000003', 'worker', 9)$$,
  'a score outside one to five');

call must_fail(
  $$insert into ratings (job_id, side, stars)
    values ('aaaaaaaa-0000-0000-0000-000000000003', 'worker', 0)$$,
  'a score of nothing');

-- The asymmetry: the hirer's two stars exist and must not reach the average.
do $$
declare stars numeric;
begin
  select average_stars into stars from worker_standing
  where profile_id = '22222222-2222-2222-2222-222222222222';

  if stars is distinct from 5 then
    raise exception
      'the public average is %, so a hirer rating leaked into it', stars;
  end if;
  raise notice '  hidden: the hirer''s rating, from the public average';
end;
$$;

\echo '== Section 11 — the wallet is a ledger'

insert into wallet_entries (profile_id, kind, tokens) values
  ('22222222-2222-2222-2222-222222222222', 'topUp', 5000);

insert into wallet_entries (profile_id, kind, tokens, job_id) values
  ('22222222-2222-2222-2222-222222222222', 'commission', -90,
   'aaaaaaaa-0000-0000-0000-000000000001');

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens, job_id)
    values ('22222222-2222-2222-2222-222222222222', 'commission', -90,
            'aaaaaaaa-0000-0000-0000-000000000001')$$,
  'charging commission on the same job twice');

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens)
    values ('22222222-2222-2222-2222-222222222222', 'commission', 400)$$,
  'a commission that pays the worker');

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens)
    values ('22222222-2222-2222-2222-222222222222', 'topUp', -400)$$,
  'a top-up that takes money away');

insert into wallet_entries (profile_id, kind, tokens) values
  ('22222222-2222-2222-2222-222222222222', 'firstJobCredit', 500);

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens)
    values ('22222222-2222-2222-2222-222222222222', 'firstJobCredit', 500)$$,
  'a second first job');

call must_fail(
  $$update wallet_entries set tokens = 0
    where profile_id = '22222222-2222-2222-2222-222222222222'$$,
  'editing a ledger entry after the fact');

call must_fail(
  $$delete from wallet_entries
    where profile_id = '22222222-2222-2222-2222-222222222222'$$,
  'deleting a ledger entry');

do $$
declare balance integer;
begin
  select sum(tokens) into balance from wallet_entries
  where profile_id = '22222222-2222-2222-2222-222222222222';

  -- 5000 topped up, 90 commission, 500 for the first job.
  if balance <> 5410 then
    raise exception 'balance derived as %, expected 5410', balance;
  end if;
  raise notice '  derived: a balance, from the entries and nothing else';
end;
$$;

\echo '== Messages — the thread attached to a job'

insert into messages (id, job_id, sender_id, body) values
  ('cccccccc-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111',
   'Are you free tomorrow morning?');

call must_fail(
  $$insert into messages (id, job_id, sender_id, body)
    values ('cccccccc-0000-0000-0000-000000000002',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '   ')$$,
  'a message that is nothing but whitespace');

call must_fail(
  $$insert into messages (id, job_id, sender_id, body)
    values ('cccccccc-0000-0000-0000-000000000003',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', repeat('x', 1001))$$,
  'a message longer than the bubble it goes in');

-- **What was said cannot change.** A conversation people can rewrite afterwards
-- is not a record of one.
call must_fail(
  $$update messages set body = 'something else'
    where id = 'cccccccc-0000-0000-0000-000000000001'$$,
  'rewriting what a message said');

call must_fail(
  $$update messages set sender_id = '22222222-2222-2222-2222-222222222222'
    where id = 'cccccccc-0000-0000-0000-000000000001'$$,
  'changing who sent a message');

call must_fail(
  $$update messages set read_at = sent_at - interval '1 hour'
    where id = 'cccccccc-0000-0000-0000-000000000001'$$,
  'a read receipt from before the message was sent');

-- The one update a message does take.
call must_work(
  $$update messages set read_at = now()
    where id = 'cccccccc-0000-0000-0000-000000000001'$$,
  'marking a message read');

\echo '== Section 9 — Mode B'

call must_fail(
  $$insert into jobs (posted_by, booked_worker_id, latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222', 33.7, 73.0)$$,
  'a booking with no listed price to compute commission from');

call must_work(
  $$insert into jobs (id, posted_by, booked_worker_id, listed_fare, agreed_fare,
                      latitude, longitude)
    values ('aaaaaaaa-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222', 3000, 2925, 33.7, 73.0)$$,
  'a booking carrying both the listed price and what the hirer pays');

insert into directory_listings (profile_id, plan, subscribed_at, expires_at)
values ('22222222-2222-2222-2222-222222222222', 'monthly', now(),
        now() + interval '30 days');

call must_fail(
  $$insert into directory_listings (profile_id, plan)
    values ('33333333-3333-3333-3333-333333333333', 'monthly')$$,
  'a subscription with no end date, which could never lapse');

call must_fail(
  $$insert into service_offerings (profile_id, tag_id, title, price_rupees)
    values ('22222222-2222-2222-2222-222222222222', 'cleaning', 'Deep clean', 0)$$,
  'a service listed at nothing');

\echo '== The small print'
--
-- Positive numbers, non-empty names, coordinates on the actual planet. None of
-- these decide anything on their own; together they are the difference between
-- a row the app can render and a row that puts `Rs. 0` or a blank name on a
-- screen with no way to tell where it came from. Each check below is aimed at a
-- row that violates *only* it, so none of them can pass for a neighbour's
-- reasons.

call must_fail(
  $$insert into profiles (id, display_name)
    values ('55555555-5555-5555-5555-555555555555', '   ')$$,
  'an account with no name to show');

call must_fail(
  $$insert into jobs (posted_by, latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111', 91.0, 73.0)$$,
  'a job north of the north pole');

call must_fail(
  $$insert into jobs (posted_by, latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111', 33.7, 181.0)$$,
  'a job off the edge of the map');

call must_fail(
  $$insert into jobs (posted_by, latitude, longitude, radius_metres)
    values ('11111111-1111-1111-1111-111111111111', 33.7, 73.0, 0)$$,
  'a job whose circle has no area');

call must_fail(
  $$insert into jobs (posted_by, latitude, longitude, geofence_metres)
    values ('11111111-1111-1111-1111-111111111111', 33.7, 73.0, 0)$$,
  'a geofence that could reach nobody');

call must_fail(
  $$insert into jobs (posted_by, latitude, longitude, starting_fare)
    values ('11111111-1111-1111-1111-111111111111', 33.7, 73.0, 0)$$,
  'work advertised at nothing');

call must_fail(
  $$insert into jobs (posted_by, accepted_worker_id, status, agreed_fare,
                      latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222', 'accepted', 0, 33.7, 73.0)$$,
  'an agreed fare of nothing');

call must_fail(
  $$insert into jobs (posted_by, booked_worker_id, listed_fare,
                      latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222', 0, 33.7, 73.0)$$,
  'a service booked at nothing');

-- Section 7: past `open`, somebody is on the job. The two ways a job ends
-- without a worker — cancelled, expired — are the deliberate exceptions.
call must_fail(
  $$insert into jobs (posted_by, status, latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111', 'inProgress', 33.7, 73.0)$$,
  'work in progress with nobody doing it');

call must_work(
  $$insert into jobs (posted_by, status, latitude, longitude)
    values ('11111111-1111-1111-1111-111111111111', 'expired', 33.7, 73.0)$$,
  'a job that ran out of time with nobody on it');

call must_fail(
  $$insert into bids (job_id, worker_id, fare)
    values ('aaaaaaaa-0000-0000-0000-000000000002',
            '33333333-3333-3333-3333-333333333333', 0)$$,
  'an offer to work for nothing');

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens)
    values ('22222222-2222-2222-2222-222222222222', 'adminAdjustment', 0)$$,
  'a ledger line that moves no money');

call must_fail(
  $$insert into wallet_entries (profile_id, kind, tokens, job_id) values
      ('33333333-3333-3333-3333-333333333333', 'cancellationPenalty', -200,
       'aaaaaaaa-0000-0000-0000-000000000003'),
      ('33333333-3333-3333-3333-333333333333', 'cancellationPenalty', -200,
       'aaaaaaaa-0000-0000-0000-000000000003')$$,
  'being fined twice for pulling out of one job');

call must_fail(
  $$insert into job_media (job_id, kind, storage_path, duration_ms)
    values ('aaaaaaaa-0000-0000-0000-000000000003', 'voiceNote',
            'jobs/aaa3/note.m4a', 0)$$,
  'a voice note of no length');

call must_fail(
  $$insert into directory_listings (profile_id, service_radius_metres)
    values ('33333333-3333-3333-3333-333333333333', 0)$$,
  'a worker who will travel nowhere');

call must_fail(
  $$insert into service_offerings (profile_id, tag_id, title, price_rupees)
    values ('22222222-2222-2222-2222-222222222222', 'cleaning', '  ', 1500)$$,
  'a service with no name');

call must_fail(
  $$insert into worker_credentials (profile_id, kind, title)
    values ('22222222-2222-2222-2222-222222222222', 'certification', ' ')$$,
  'a qualification with no name');

call must_fail(
  $$insert into worker_credentials (profile_id, kind, title, year)
    values ('22222222-2222-2222-2222-222222222222', 'certification',
            'City & Guilds Level 2', 1642)$$,
  'a certificate from before there were any');

-- Section 8 says one tag is the default. Two would make `grant_default_tag`
-- silently hand out both, and no screen decides which.
call must_fail(
  $$update job_tags set is_default = true where id = 'plumbing'$$,
  'a second trade claiming to be the one everybody holds');

\echo '== Section 2 and 12 — the CNIC, disputes, and the log'

insert into verifications (profile_id, cnic_masked, cnic_name, cnic_plausible)
values ('33333333-3333-3333-3333-333333333333', '*****-*****45-6', 'Bilal Awan', true);

call must_fail(
  $$insert into verifications (profile_id, cnic_masked)
    values ('22222222-2222-2222-2222-222222222222', '35202-1234567-1')$$,
  'storing a whole CNIC number');

do $$
begin
  if may_open_cnic('33333333-3333-3333-3333-333333333333') then
    raise exception 'a CNIC was openable with no dispute against the person';
  end if;
  raise notice '  refused: opening a CNIC with no dispute';
end;
$$;

call must_fail(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, note)
    values ('viewCnic', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', 'curious')$$,
  'logging a CNIC view with no dispute to justify it');

insert into disputes (id, job_id, about_profile_id, raised_by_id, reason)
values ('dddddddd-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001',
        '33333333-3333-3333-3333-333333333333',
        '11111111-1111-1111-1111-111111111111',
        'Did not turn up and stopped answering.');

call must_work(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, note)
    values ('viewCnic', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', 'checking the name')$$,
  'opening a CNIC once a dispute names that person');

call must_fail(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, tokens)
    values ('adjustWallet', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', -4000)$$,
  'an override with no reason recorded');

call must_work(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, tokens, note)
    values ('adjustWallet', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', -4000,
            'Charged twice for job aaaa...001.')$$,
  'the same override, with a reason');

call must_fail(
  $$update admin_audit_log set note = 'something else'$$,
  'editing the audit log');

call must_fail(
  $$delete from admin_audit_log$$,
  'deleting from the audit log');

call must_fail(
  $$insert into disputes (job_id, about_profile_id, raised_by_id, reason)
    values ('aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            '11111111-1111-1111-1111-111111111111', 'Complaining about myself')$$,
  'somebody disputing themselves');

call must_fail(
  $$insert into disputes (job_id, about_profile_id, raised_by_id, reason)
    values ('aaaaaaaa-0000-0000-0000-000000000001',
            '33333333-3333-3333-3333-333333333333',
            '11111111-1111-1111-1111-111111111111', '   ')$$,
  'a complaint with nothing written in it');

call must_fail(
  $$update disputes set resolution = 'Settled between them.'
    where id = 'dddddddd-0000-0000-0000-000000000001'$$,
  'a resolution with no date, which is a case nobody can tell is closed');

call must_fail(
  $$update disputes set resolved_at = now()
    where id = 'dddddddd-0000-0000-0000-000000000001'$$,
  'closing a case without saying how it ended');

call must_fail(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, tokens, note)
    values ('cancelJob', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', -500, 'Cancelled it.')$$,
  'tokens moving under an action that has nothing to do with the wallet');

-- Closing the dispute closes the door again.
update disputes set resolved_at = now(), resolution = 'Settled between them.'
  where id = 'dddddddd-0000-0000-0000-000000000001';

call must_fail(
  $$insert into admin_audit_log (action, admin_id, target_profile_id, note)
    values ('viewCnic', '44444444-4444-4444-4444-444444444444',
            '33333333-3333-3333-3333-333333333333', 'one more look')$$,
  'opening a CNIC after the dispute is settled');

\echo '== The one rule that cannot be provoked'
--
-- `bids_one_accepted_per_job` has no behavioural test, and it is worth being
-- precise about why rather than quietly leaving a gap.
--
-- Every route to a second accepted bid is stopped earlier by something
-- stricter: `unique (job_id, worker_id)` rules out the same worker twice, so
-- the second acceptance is always a *different* worker — and that fails
-- `agreed_fare_matches_bid`, because the job names one chosen worker. There is
-- no row the index refuses that the trigger does not refuse first.
--
-- It stays because a trigger is switchable and an index is not: `alter table
-- ... disable trigger`, or a restore run under `session_replication_role =
-- replica`, turns the trigger off and leaves the unique index doing the work.
-- So the check here is that it still exists, which is the only claim honestly
-- available.
do $$
begin
  if not exists (
    select 1 from pg_index x
    join pg_class i on i.oid = x.indexrelid
    where i.relname = 'bids_one_accepted_per_job' and x.indisunique
  ) then
    raise exception
      'bids_one_accepted_per_job is gone: with triggers disabled, one job '
      'could carry two winning bids and two people would be owed the fare';
  end if;
  raise notice '  present: one winning bid per job, enforced without a trigger';
end;
$$;

\echo ''
\echo 'Every rule above was enforced by the database, not by a client.'
