#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
[ "$(psql "$DATABASE_URL" -tAc "select count(*) from information_schema.columns where table_name='users' and column_name='name'")" = 0 ] || exit 1
[ "$(psql "$DATABASE_URL" -tAc "select convalidated from pg_constraint where conname='users_full_name_not_null'")" = t ] || exit 1
