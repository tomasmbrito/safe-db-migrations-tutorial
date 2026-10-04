# Meet the system

Before changing anything, look at what is running. This is a habit worth keeping: you need a baseline to notice when something breaks.

**What the users see right now.** Run the status script:

```
./status.sh
```{{exec}}

You should see only `v1` and no failures. Open a **second terminal tab** (the `+` at the top) and keep the status refreshing there for the rest of the tutorial:

```
watch -n1 /root/tutorial/status.sh
```{{copy}}

**Talk to the app yourself:**

```
curl -s localhost:8001/users; echo
curl -s -X POST localhost:8001/users -H 'Content-Type: application/json' -d '{"name": "Ada Lovelace"}'; echo
```{{exec}}

**How the schema is managed.** Every schema change is a SQL file in `db/migrations/`, with an `up` part and a `down` part. dbmate keeps track of which files were already applied in a table called `schema_migrations`:

```
cat db/migrations/20261001000000_create_users.sql
dbmate status
```{{exec}}

Keeping schema changes as versioned files in Git is what makes them reviewable, repeatable in every environment, and something a pipeline can act on. It is the same idea as Infrastructure as Code, applied to the database.

**Look at the one line that differs between v1 and v2:**

```
grep -n "COLUMN =" app.py
```{{exec}}

Click **Check** when you have seen the status and the migration status.
