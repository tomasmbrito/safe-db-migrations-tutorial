#!/usr/bin/env bash
# mini pipeline for schema changes
# stage 1: lint the pending migrations with squawk
# stage 2: apply them with dbmate (only if stage 1 passed)
set -uo pipefail
T="${TUTORIAL_DIR:-/root/tutorial}"
cd "$T"
mkdir -p state
pending=$(dbmate status 2>/dev/null | awk '/^\[ \]/ {print "db/migrations/"$3}')

if [ -z "$pending" ]; then
  echo "Nothing to deploy: no pending migrations."
  exit 0
fi

echo "== stage 1: lint =================================================="
echo "pending migrations:"; echo "$pending" | sed 's/^/  /'
echo
if ! squawk --config .squawk.toml $pending; then
  echo
  echo "PIPELINE BLOCKED: fix the migration above (or justify an exception) and run ./ci.sh again."
  echo BLOCKED >state/ci_result
  exit 1
fi

echo
echo "== stage 2: deploy ================================================"
if dbmate up; then
  echo
  echo "PIPELINE PASSED: migrations applied."
  echo PASSED >state/ci_result
else
  echo "PIPELINE FAILED while applying the migration."
  echo FAILED >state/ci_result
  exit 1
fi
