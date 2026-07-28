-- Trust Hire — disputes and the audit log.
--
-- Phase 1 Section 12, and the half of Section 2 that only an admin ever
-- touches. The claim this migration has to make good on is the one the app
-- makes structurally: **every admin action is written down, and the writing
-- down cannot be skipped.**

create type admin_action as enum (
  'approveUser', 'suspendUser', 'reinstateUser', 'viewCnic',
  'adjustWallet', 'unlockWallet', 'cancelJob', 'closeDispute'
);

create table disputes (
  id                uuid primary key default gen_random_uuid(),
  job_id            uuid not null references jobs (id) on delete cascade,

  -- Who is complained about. This is the account whose CNIC becomes openable,
  -- and nobody else's.
  about_profile_id  uuid not null references profiles (id),
  raised_by_id      uuid not null references profiles (id),

  reason            text not null check (length(trim(reason)) > 0),
  raised_at         timestamptz not null default now(),

  resolved_at       timestamptz,
  resolution        text,

  constraint nobody_disputes_themselves
    check (about_profile_id <> raised_by_id),

  -- A resolution without a reason would be a closed case nobody can review.
  constraint resolution_is_whole
    check ((resolved_at is null) = (resolution is null))
);

create index disputes_open on disputes (about_profile_id) where resolved_at is null;

-- ---------------------------------------------------------------------------
-- The audit log
-- ---------------------------------------------------------------------------

create table admin_audit_log (
  id                uuid primary key default gen_random_uuid(),
  action            admin_action not null,
  admin_id          uuid not null references profiles (id),

  target_profile_id uuid references profiles (id),
  target_job_id     uuid references jobs (id) on delete set null,

  -- Why. Section 12 lists notes as part of every entry, and for an override
  -- it is the only thing that makes the entry reviewable.
  note              text,

  -- The size of a wallet adjustment, signed. Null for everything else.
  tokens            integer,

  at                timestamptz not null default now(),

  -- **An override without a reason is the black box the log exists to
  -- prevent.** The app refuses these in `AdminController._perform`; this is
  -- the same refusal for anything that talks to the database directly.
  constraint overrides_carry_a_reason check (
    action not in ('suspendUser', 'adjustWallet', 'unlockWallet')
    or length(trim(coalesce(note, ''))) >= 3
  ),

  constraint only_wallet_actions_move_tokens check (
    tokens is null or action in ('adjustWallet', 'unlockWallet')
  )
);

create index admin_audit_log_recent on admin_audit_log (at desc);
create index admin_audit_log_target on admin_audit_log (target_profile_id);

-- Append-only, like the wallet and for the same reason: a record of what
-- happened that can be edited afterwards is a record nobody can rely on.
create trigger admin_audit_log_no_update
  before update or delete on admin_audit_log
  for each row execute function ledgers_are_append_only();

-- ---------------------------------------------------------------------------
-- The CNIC access rule (Section 2)
-- ---------------------------------------------------------------------------
--
-- "The photo sits unreviewed unless a dispute is raised later, at which point
-- an admin manually pulls it up."
--
-- In the app this is `AdminRules.mayOpenCnic`, deliberately a function rather
-- than a checkbox on a screen so that no screen can be built that forgets to
-- ask. Here it is the same rule where no *client* can forget to ask.
create or replace function may_open_cnic(subject uuid) returns boolean
  language sql stable as $$
  select exists (
    select 1 from disputes
    where about_profile_id = subject and resolved_at is null
  );
$$;

comment on function may_open_cnic is
  'A resolved dispute does not keep the door open: the reason to look was the '
  'complaint, and the complaint is finished.';

-- Recording a CNIC view is only honest if the view was allowed. A refusal is
-- not an inspection, and logging one would put a line in the record saying
-- somebody looked at a document they never saw.
create or replace function cnic_view_needs_a_dispute() returns trigger
  language plpgsql as $$
begin
  if new.action = 'viewCnic'
     and not may_open_cnic(new.target_profile_id) then
    raise exception
      'a CNIC may only be opened while a dispute about that person is open '
      '(profile %)', new.target_profile_id;
  end if;
  return new;
end;
$$;

create trigger admin_audit_log_cnic_rule
  before insert on admin_audit_log
  for each row execute function cnic_view_needs_a_dispute();
