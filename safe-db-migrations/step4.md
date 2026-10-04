# Expand: add, don't change

The idea of expand/contract (also called parallel change) is to never change something a running version depends on. Instead the change is split into steps, and each step works with every app version that is running at that moment:

![Expand and contract](https://raw.githubusercontent.com/tomasmbrito/safe-db-migrations-tutorial/main/safe-db-migrations/images/expand-contract.png)

First, expand: add `full_name` next to `name`. Nothing v1 uses changes, so v1 doesn't notice anything.

There's one more problem: while v1 and v2 run side by side, v1 only writes `name` and v2 only writes `full_name`. To keep the two columns in sync, a trigger in the database fills in whichever one is missing. We could also make v2 write both columns, but the trigger keeps the app simpler and it also covers v1, which we can't change anymore.

```
cat > db/migrations/20261003000000_expand_add_full_name.sql <<'SQL'
-- migrate:up
-- Never wait long for a lock: fail fast instead of queueing behind other queries.
SET lock_timeout = '2s';
SET statement_timeout = '10s';

-- EXPAND: add the new column next to the old one. Nullable and without a
-- default, so PostgreSQL only updates its catalog and does not rewrite the table.
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name text;

-- Keep both columns in sync while v1 and v2 run side by side.
CREATE OR REPLACE FUNCTION users_sync_full_name() RETURNS trigger AS $$
BEGIN
  IF NEW.full_name IS NULL THEN NEW.full_name := NEW.name; END IF;
  IF NEW.name IS NULL THEN NEW.name := NEW.full_name; END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_sync_full_name
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION users_sync_full_name();

-- migrate:down
SET lock_timeout = '2s';
SET statement_timeout = '10s';
DROP TRIGGER IF EXISTS users_sync_full_name ON users;
DROP FUNCTION IF EXISTS users_sync_full_name();
-- squawk-ignore ban-drop-column
ALTER TABLE users DROP COLUMN IF EXISTS full_name;
SQL
```{{exec}}

Send it through the pipeline:

```
./ci.sh
```{{exec}}

This time squawk has nothing to complain about and dbmate applies it. v1 should still be fine:

```
sleep 2; ./status.sh
```{{exec}}

New rows from v1 now get `full_name` from the trigger, but the 200,000 old rows still have it empty:

```
psql "$DATABASE_URL" -c "SELECT count(*) AS rows_without_full_name FROM users WHERE full_name IS NULL"
```{{exec}}

That's the next step.
