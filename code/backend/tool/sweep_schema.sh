#!/usr/bin/env bash
#
# Trust Hire — does the schema test actually test anything?
#
# `verify_schema.sh` proves the schema refuses what it should. It cannot prove
# the *tests* are doing the refusing: a check aimed at a row that also violates
# a neighbouring rule passes whether or not the rule it names still exists.
# That happened twice while this suite was being written — the star-range check
# was being refused by the once-per-side rule, and the tag-count check was being
# deferred past the assertion entirely — and neither showed up as a failure.
#
# So: drop each rule in turn, against a throwaway copy of the database, and run
# the suite. A rule whose removal the suite does not notice is printed. The run
# fails if anything is printed that is not on the list below.
#
#   code/backend/tool/sweep_schema.sh
#
# This is slow — one database and one full suite run per rule, around ninety of
# them. It is a thing to run when the schema changes, not on every commit.

set -uo pipefail

backend="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database="${TRUST_HIRE_SWEEP_DB:-trust_hire_schema_sweep}"

# Rules the suite is *expected* not to cover, each with the reason.
#
#   jobs_accepted_worker, jobs_booked_worker, disputes_open
#     Not rules. Partial indexes that make three common lookups fast; there is
#     no row they refuse, so there is no row that could test them.
#
#   bids_one_accepted_per_job
#     A rule, but an unreachable one — `agreed_fare_matches_bid` refuses every
#     row it would have refused, first. `schema_test.sql` ends by asserting it
#     still exists instead, and says why.
expected_uncovered=(
  "drop index jobs_accepted_worker"
  "drop index jobs_booked_worker"
  "drop index disputes_open"
  # A partial index over unread messages. Speeds up the thread list; enforces
  # nothing, so nothing can fail when it is gone.
  "drop index messages_unread"
)

if [ -z "${TRUST_HIRE_PSQL_USER+x}" ]; then
  if psql -tAc 'select 1' postgres >/dev/null 2>&1; then
    TRUST_HIRE_PSQL_USER=""
  else
    TRUST_HIRE_PSQL_USER="postgres"
  fi
fi

run_psql() {
  if [ -n "$TRUST_HIRE_PSQL_USER" ]; then
    sudo -u "$TRUST_HIRE_PSQL_USER" psql "$@"
  else
    psql "$@"
  fi
}

drop_databases() {
  run_psql -q -d postgres -c "drop database if exists ${database}_trial" >/dev/null 2>&1
  run_psql -q -d postgres -c "drop database if exists ${database}" >/dev/null 2>&1
}

trap drop_databases EXIT

echo "Building $database from scratch."
drop_databases
run_psql -q -v ON_ERROR_STOP=1 -d postgres -c "create database $database" >/dev/null
for migration in "$backend"/migrations/*.sql; do
  run_psql -q -v ON_ERROR_STOP=1 -d "$database" -f - < "$migration" >/dev/null
done

# Every check constraint, unique constraint, partial index and user trigger the
# migrations created. Foreign keys and primary keys are left out: they are
# structure rather than policy, and dropping one usually breaks the fixtures
# rather than testing anything.
list() { run_psql -tAq -d "$database" -c "$1"; }

mutations=$(
  list "select format('alter table %I drop constraint %I', rel.relname, c.conname)
        from pg_constraint c
        join pg_class rel on rel.oid = c.conrelid
        join pg_namespace n on n.oid = rel.relnamespace
        where n.nspname = 'public' and c.contype in ('c', 'u')"
  list "select format('drop index %I', i.relname)
        from pg_index x
        join pg_class i on i.oid = x.indexrelid
        join pg_class t on t.oid = x.indrelid
        join pg_namespace n on n.oid = t.relnamespace
        where n.nspname = 'public' and not x.indisprimary and x.indpred is not null"
  list "select format('drop trigger %I on %I', tg.tgname, rel.relname)
        from pg_trigger tg
        join pg_class rel on rel.oid = tg.tgrelid
        join pg_namespace n on n.oid = rel.relnamespace
        where n.nspname = 'public' and not tg.tgisinternal"
)

total=0
unexpected=0
echo

while IFS= read -r mutation; do
  [ -z "$mutation" ] && continue
  total=$((total + 1))

  run_psql -q -d postgres -c "drop database if exists ${database}_trial" >/dev/null 2>&1
  run_psql -q -v ON_ERROR_STOP=1 -d postgres \
    -c "create database ${database}_trial template $database" >/dev/null

  if ! run_psql -q -v ON_ERROR_STOP=1 -d "${database}_trial" -c "$mutation" >/dev/null 2>&1; then
    echo "  ?  could not drop, so not swept: $mutation"
    continue
  fi

  if run_psql -q -v ON_ERROR_STOP=1 -d "${database}_trial" -f - \
       < "$backend/test/schema_test.sql" >/dev/null 2>&1; then
    excused=0
    for allowed in "${expected_uncovered[@]}"; do
      [ "$mutation" = "$allowed" ] && excused=1
    done
    if [ "$excused" = 1 ]; then
      echo "  -  not a rule, nothing to cover: $mutation"
    else
      echo "  !  UNCOVERED: $mutation"
      unexpected=$((unexpected + 1))
    fi
  fi
done <<< "$mutations"

echo
echo "Swept $total rules."

if [ "$unexpected" -gt 0 ]; then
  echo
  echo "$unexpected rule(s) can be removed without the suite noticing."
  echo "Either add a test that provokes the rule alone, or — if nothing can"
  echo "provoke it — say so in expected_uncovered above, with the reason."
  exit 1
fi

echo "Every rule is held up by at least one test."
