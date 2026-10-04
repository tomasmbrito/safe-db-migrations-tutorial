# Locks: adding an index

A new feature lists the newest customers, so it needs an index on `created_at`. Adding an index does not change any column, so no app version can break. Can it still hurt production?

A normal `CREATE INDEX` takes a `SHARE` lock on the table for the whole build: **reads continue, but every write waits** until the index is finished. Our table builds its index in a fraction of a second, so we simulate a big table by keeping the transaction open for 8 seconds, which is what a build on a large production table looks like:

```
psql "$DATABASE_URL" -qc "BEGIN; CREATE INDEX users_created_at_idx ON users (created_at); SELECT pg_sleep(8); ROLLBACK;" &
sleep 6; ./status.sh
```{{exec}}

Look at the failures: only `POST` requests fail, after hitting the app's 2-second timeout. The `GET`s keep working. While the build holds the lock, you can see who is waiting:

```
psql "$DATABASE_URL" -c "SELECT pid, wait_event_type, left(query, 50) AS query FROM pg_stat_activity WHERE wait_event_type = 'Lock'"
```{{exec}}

(If the list is empty, the 8 seconds are already over; run both commands again.)

**What would the pipeline say?** Write the obvious migration:

```
cat > db/migrations/20261005000000_index_created_at.sql <<'SQL'
-- migrate:up
CREATE INDEX users_created_at_idx ON users (created_at);

-- migrate:down
DROP INDEX users_created_at_idx;
SQL
./ci.sh
```{{exec}}

Blocked by `require-concurrent-index-creation`. `CREATE INDEX CONCURRENTLY` builds the index without blocking writes: it takes longer and scans the table twice, but the application never waits. It has one rule: it cannot run inside a transaction. dbmate wraps every migration in a transaction unless the file says `transaction:false`, and a multi-statement file is also sent as one implicit transaction, so the file holds a single statement:

```
cat > db/migrations/20261005000000_index_created_at.sql <<'SQL'
-- migrate:up transaction:false
-- "transaction:false": dbmate must not wrap this file in a transaction,
-- because CREATE INDEX CONCURRENTLY is not allowed inside one. For the same
-- reason the file holds a single statement, so the timeout rules are waived.
-- squawk-ignore ban-concurrent-index-creation-in-transaction, require-lock-timeout, require-statement-timeout
CREATE INDEX CONCURRENTLY IF NOT EXISTS users_created_at_idx ON users (created_at);

-- migrate:down transaction:false
-- squawk-ignore require-lock-timeout, require-statement-timeout
DROP INDEX CONCURRENTLY IF EXISTS users_created_at_idx;
SQL
./ci.sh
sleep 10; ./status.sh
```{{exec}}

The index is built and no write had to wait (the status covers the last 10 seconds, so give it those 10 seconds to forget the failures from the simulation). One more detail: if a concurrent build fails halfway, PostgreSQL leaves an **invalid** index behind that must be dropped by hand. This query should show `true`:

```
psql "$DATABASE_URL" -c "SELECT indexrelid::regclass AS index, indisvalid AS valid FROM pg_index WHERE indrelid = 'users'::regclass"
```{{exec}}
