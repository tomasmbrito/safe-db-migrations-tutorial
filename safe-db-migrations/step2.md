# The innocent migration

Product wants to rename `name` to `full_name`. The new app version (v2) is ready and uses `full_name`. A typical deploy runs the migration first and then rolls out the new code, so let's write the obvious migration:

```
cat > db/migrations/20261002000000_rename_name_to_full_name.sql <<'SQL'
-- migrate:up
ALTER TABLE users RENAME COLUMN name TO full_name;

-- migrate:down
ALTER TABLE users RENAME COLUMN full_name TO name;
SQL
```{{exec}}

Apply it the way many teams do, straight from the command line or a pipeline without checks:

```
dbmate up
```{{exec}}

The migration took a few milliseconds and reported success. Now look at the users (in your second tab, or here):

```
sleep 3; ./status.sh
```{{exec}}

**v1 fails on every request.** It is still running, because v2 has not been rolled out yet, and it asks for a column that no longer exists:

```
curl -s localhost:8001/users; echo
```{{exec}}

Nothing crashed, the migration "worked", and yet production is down. In a real rolling deploy this window lasts as long as the rollout, from seconds to many minutes, and with a large table the `ALTER` itself may wait for locks first.

Undo it, the way you would during an incident:

```
dbmate rollback
sleep 3; ./status.sh
```{{exec}}

The errors stop. Rolling back was easy here only because a rename loses no data. Many schema changes (dropping a column, changing a type) cannot be undone this cleanly, which is why we want to stop them **before** they reach the database.

Click **Check** once the rename is rolled back.
