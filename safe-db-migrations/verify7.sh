#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
[ "$(psql "$DATABASE_URL" -tAc "select indisvalid from pg_index where indexrelid = 'users_created_at_idx'::regclass")" = t ] || exit 1
grep -q CONCURRENTLY /root/tutorial/db/migrations/20261005000000_index_created_at.sql || exit 1
