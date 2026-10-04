# Locks: adding an index

Say a new feature lists the newest customers, so we need an index on `created_at`. An index doesn't change any column, so no app version can break. Can it still hurt production?

A normal `CREATE INDEX` holds a `SHARE` lock on the table for the whole build: reads keep working, but every write waits until the index is done. Our table is small enough that the build takes a fraction of a second, so we fake a big table by keeping the transaction open for 8 seconds:

```
psql "$DATABASE_URL" -qc "BEGIN; CREATE INDEX users_created_at_idx ON users (created_at); SELECT pg_sleep(8); ROLLBACK;" &
sleep 6; ./status.sh
```{{exec}}

Only the `POST` requests fail, after hitting the app's 2 second timeout. The `GET`s keep working. While the lock is held you can see who's waiting for it:

```
psql "$DATABASE_URL" -c "SELECT pid, wait_event_type, left(query, 50) AS query FROM pg_stat_activity WHERE wait_event_type = 'Lock'"
```{{exec}}

(If the list is empty the 8 seconds were already over, just run both commands again.)

What would the pipeline say? Let's write the obvious migration:

```
cat > db/migrations/20261005000000_index_created_at.sql <<'SQL'
-- migrate:up
CREATE INDEX users_created_at_idx ON users (created_at);

-- migrate:down
DROP INDEX users_created_at_idx;
SQL
./ci.sh
```{{exec}}

Blocked by `require-concurrent-index-creation`. `CREATE INDEX CONCURRENTLY` builds the index without blocking writes. It's slower and scans the table twice, but the app never has to wait. The catch is that it can't run inside a transaction. dbmate wraps every migration in a transaction unless the file says `transaction:false`, and a file with several statements also gets sent as one implicit transaction, so this file only has one statement:

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

The index is there and no write had to wait. (The status shows the last 10 seconds, so the failures from the simulation can still show up for a moment.) One more thing: if a concurrent build fails halfway, PostgreSQL leaves an invalid index behind that you have to drop by hand. This should show `true`:

```
psql "$DATABASE_URL" -c "SELECT indexrelid::regclass AS index, indisvalid AS valid FROM pg_index WHERE indrelid = 'users'::regclass"
```{{exec}}
