#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
T=/root/tutorial
[ -f $T/db/migrations/20261002000000_rename_name_to_full_name.sql ] || exit 1
grep -q " v1 .* 500 " $T/logs/traffic.log || exit 1                    # the break happened
[ "$(psql "$DATABASE_URL" -tAc "select count(*) from information_schema.columns where table_name='users' and column_name='name'")" = 1 ] || exit 1
