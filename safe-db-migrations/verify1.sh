#!/bin/bash
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
curl -sf localhost:8001/health >/dev/null || exit 1
[ "$(psql "$DATABASE_URL" -tAc 'select count(*) from schema_migrations')" -ge 1 ] || exit 1
