#!/usr/bin/env bash
# fill full_name for the old rows, in small batches
# (short transactions = locks are held only for a moment)
batch=${1:-5000}
while true; do
  psql "$DATABASE_URL" -qtAX -c "
    UPDATE users SET full_name = name
    WHERE id IN (SELECT id FROM users WHERE full_name IS NULL LIMIT $batch);" >/dev/null
  left=$(psql "$DATABASE_URL" -qtAX -c "SELECT count(*) FROM users WHERE full_name IS NULL")
  echo "batch done, rows still without full_name: $left"
  [ "$left" -eq 0 ] && break
  sleep 0.2
done
echo "backfill complete"
