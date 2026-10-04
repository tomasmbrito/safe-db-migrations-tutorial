# The harmless-looking migration

Product wants `name` renamed to `full_name`. The new version of the app (v2) is ready and already uses `full_name`. A normal deploy runs the migration first and then rolls out the new code, so let's write the obvious migration:

```
cat > db/migrations/20261002000000_rename_name_to_full_name.sql <<'SQL'
-- migrate:up
ALTER TABLE users RENAME COLUMN name TO full_name;

-- migrate:down
ALTER TABLE users RENAME COLUMN full_name TO name;
SQL
```{{exec}}

And apply it directly, like a lot of teams do (by hand, or from a pipeline without any checks):

```
dbmate up
```{{exec}}

It took a few milliseconds and said it worked. Now check the users:

```
sleep 3; ./status.sh
```{{exec}}

Every request to v1 fails. v1 is still running because v2 hasn't been rolled out yet, and it asks for a column that doesn't exist anymore:

```
curl -s localhost:8001/users; echo
```{{exec}}

Nothing crashed and the migration "succeeded", but production is down. In a real rolling deploy this lasts for the whole rollout, which can be anything from seconds to many minutes. On a big table the `ALTER` might also have to wait for locks first.

Let's undo it, like you would during an incident:

```
dbmate rollback
sleep 3; ./status.sh
```{{exec}}

The errors stop. Here the rollback was easy because a rename doesn't lose data, but plenty of schema changes (dropping a column, changing a type) can't be undone that cleanly. That's why we want to catch them before they get to the database.

Click Check once the rename is rolled back.
