#!/usr/bin/env bash
# runs in the background while the intro is shown
set -x
export DEBIAN_FRONTEND=noninteractive
T=/root/tutorial
DBMATE_VERSION=v2.36.0
SQUAWK_VERSION=v2.66.0

# postgres 16 + python driver for the app
apt-get update -q
apt-get install -y -q postgresql python3-psycopg
service postgresql start
su postgres -c "psql -qc \"CREATE ROLE app LOGIN PASSWORD 'app' CREATEDB\""
su postgres -c "createdb -O app shop"

# dbmate and squawk, pinned versions
curl -fsSL -o /usr/local/bin/dbmate "https://github.com/amacneil/dbmate/releases/download/$DBMATE_VERSION/dbmate-linux-amd64"
curl -fsSL -o /usr/local/bin/squawk "https://github.com/sbdchd/squawk/releases/download/$SQUAWK_VERSION/squawk-linux-x64"
chmod +x /usr/local/bin/dbmate /usr/local/bin/squawk

# project folder (files come from the assets)
mkdir -p $T/db/migrations $T/state $T/logs
mv $T/20261001000000_create_users.sql $T/db/migrations/
chmod +x $T/*.sh
cat >>/root/.bashrc <<'RC'
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
export DBMATE_NO_DUMP_SCHEMA=true
cd /root/tutorial
RC
export DATABASE_URL="postgres://app:app@127.0.0.1:5432/shop?sslmode=disable"
export DBMATE_NO_DUMP_SCHEMA=true

# first migration, app v1 and the fake traffic
cd $T
dbmate up
./deploy.sh start v1
nohup ./traffic.sh >/dev/null 2>&1 &

touch /tmp/setup-done
