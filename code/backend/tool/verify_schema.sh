#!/usr/bin/env bash
#
# Trust Hire — build the schema from scratch and check what it refuses.
#
# Creates a throwaway database, applies `migrations/` in filename order, runs
# `test/schema_test.sql`, and drops the database again. Nothing persists, so
# this is safe to run on a laptop with other databases on it.
#
#   code/backend/tool/verify_schema.sh
#
# It fails loudly. `ON_ERROR_STOP` is on for every file, so the first statement
# the server rejects — or the first rule the schema *fails* to reject — ends
# the run with a non-zero status.
#
# The connection is whatever `psql` already uses (PGHOST, PGUSER, PGDATABASE
# and friends). On a machine where the only superuser is the `postgres` OS
# account — a stock Debian or Ubuntu install, and the container this was
# written in — it re-runs itself through `sudo -u postgres`. Set
# TRUST_HIRE_PSQL_USER to override, or leave it empty to force a direct
# connection.

set -euo pipefail

backend="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database="${TRUST_HIRE_TEST_DB:-trust_hire_schema_check}"

# Who we talk to the server as.
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

drop_database() {
  run_psql -q -v ON_ERROR_STOP=1 -d postgres \
    -c "drop database if exists $database" >/dev/null
}

trap drop_database EXIT

echo "Building $database from scratch."
drop_database
run_psql -q -v ON_ERROR_STOP=1 -d postgres -c "create database $database" >/dev/null

# `-f -` rather than a path: the files are read by *this* user and piped in, so
# the server account never needs to be able to see the checkout.
for migration in "$backend"/migrations/*.sql; do
  echo "  applying $(basename "$migration")"
  run_psql -q -v ON_ERROR_STOP=1 -d "$database" -f - < "$migration"
done

echo
run_psql -q -v ON_ERROR_STOP=1 -d "$database" -f - < "$backend/test/schema_test.sql"

echo
echo "Schema verified. Dropping $database."
