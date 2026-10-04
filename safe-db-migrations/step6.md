# Contract: remove what nobody uses

**Step 3, contract:** drop the trigger and the old column, and make sure `full_name` is always filled from now on. A first attempt:

```
cat > db/migrations/20261004000000_contract_drop_name.sql <<'SQL'
-- migrate:up
SET lock_timeout = '2s';
SET statement_timeout = '10s';

-- CONTRACT: no running version uses "name" anymore (v1 is gone),
-- so the sync trigger and the old column can be removed.
DROP TRIGGER IF EXISTS users_sync_full_name ON users;
DROP FUNCTION IF EXISTS users_sync_full_name();

ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;

-- squawk-ignore ban-drop-column
ALTER TABLE users DROP COLUMN IF EXISTS name;

-- migrate:down
-- A contract step cannot be fully undone: the old column comes back empty.
ALTER TABLE users ADD COLUMN IF NOT EXISTS name text;
SQL
./ci.sh
```{{exec}}

Two things to notice.

**The `squawk-ignore` comment.** Dropping a column is normally forbidden by the `ban-drop-column` rule, because it breaks anyone still reading it. Here we *know* nobody reads it, since v1 was stopped in the previous step. The comment records that decision in the migration itself, where reviewers can see it. A gate that cannot be overridden on purpose is a gate people learn to bypass.

**The pipeline is still blocked.** `SET NOT NULL` makes PostgreSQL scan the whole table to check every row, while holding an `ACCESS EXCLUSIVE` lock that blocks reads and writes. On 200,000 rows that is short; on 200 million it is an outage. The safe version splits it in two:

1. add a `CHECK` constraint marked `NOT VALID`: instant, it only applies to new rows;
2. `VALIDATE` it in a separate migration: it scans the table, but with a light lock that lets reads and writes continue.

```
cat > db/migrations/20261004000000_contract_drop_name.sql <<'SQL'
-- migrate:up
SET lock_timeout = '2s';
SET statement_timeout = '10s';

-- CONTRACT: no running version uses "name" anymore (v1 is gone),
-- so the sync trigger and the old column can be removed.
DROP TRIGGER IF EXISTS users_sync_full_name ON users;
DROP FUNCTION IF EXISTS users_sync_full_name();

-- full_name must always be filled from now on. Added as NOT VALID, the
-- constraint applies to new rows immediately and skips the full-table scan.
ALTER TABLE users ADD CONSTRAINT users_full_name_not_null
  CHECK (full_name IS NOT NULL) NOT VALID;

-- squawk-ignore ban-drop-column
ALTER TABLE users DROP COLUMN IF EXISTS name;

-- migrate:down
-- A contract step cannot be fully undone: the old column comes back empty.
ALTER TABLE users ADD COLUMN IF NOT EXISTS name text;
SQL

cat > db/migrations/20261004000001_validate_full_name.sql <<'SQL'
-- migrate:up
-- Check the existing rows in a separate step. VALIDATE takes only a
-- SHARE UPDATE EXCLUSIVE lock, so reads and writes keep working.
SET lock_timeout = '2s';
SET statement_timeout = '60s';
ALTER TABLE users VALIDATE CONSTRAINT users_full_name_not_null;

-- migrate:down
SELECT 1;
SQL
./ci.sh
```{{exec}}

The pipeline passes. dbmate runs each file in its own transaction, so the two steps really are separate. The users never noticed:

```
sleep 2; ./status.sh
psql "$DATABASE_URL" -c '\d users'
```{{exec}}

The rename is done: three deploys instead of one, and zero failed requests.
