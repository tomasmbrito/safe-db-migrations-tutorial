#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
[ "$(cat /root/tutorial/state/ci_result)" = PASSED ] || exit 1
[ "$(psql "$DATABASE_URL" -tAc "select count(*) from information_schema.columns where table_name='users' and column_name in ('name','full_name')")" = 2 ] || exit 1
[ "$(psql "$DATABASE_URL" -tAc "select count(*) from pg_trigger where tgname='users_sync_full_name'")" = 1 ] || exit 1
