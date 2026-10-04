#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
[ "$(psql "$DATABASE_URL" -tAc 'select count(*) from users where full_name is null')" = 0 ] || exit 1
curl -sf localhost:8002/health >/dev/null || exit 1
[ "$(cat /root/tutorial/state/active_versions)" = v2 ] || exit 1
