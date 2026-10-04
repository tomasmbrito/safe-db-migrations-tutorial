# Contract: remove what nobody uses

Last part, contract: drop the trigger and the old column, and make sure `full_name` is always filled from now on. First attempt:

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

A couple of things here.

The `squawk-ignore` comment: dropping a column is normally blocked by the `ban-drop-column` rule, because it breaks anyone still reading it. Here we know nobody reads it, since we stopped v1 in the last step. The comment writes that decision down in the migration itself, where reviewers can see it. If a check can't be overridden on purpose, people just end up finding ways around it.

The pipeline is still blocked, though. `SET NOT NULL` makes PostgreSQL scan the whole table while holding an `ACCESS EXCLUSIVE` lock, so reads and writes are blocked the whole time. With 200,000 rows that's quick, with 200 million it's an outage. The safe way splits it in two:

1. add a `CHECK` constraint marked `NOT VALID`, which is instant and only applies to new rows
2. `VALIDATE` it in a separate migration, which scans the table but with a light lock, so reads and writes keep going

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

Now it passes. dbmate runs each file in its own transaction, so the two steps really are separate. And the users didn't notice a thing:

```
sleep 2; ./status.sh
psql "$DATABASE_URL" -c '\d users'
```{{exec}}

The rename is done: three deploys instead of one, and not a single failed request.
