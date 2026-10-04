# Meet the system

Before changing anything, let's see what is running, so we have something to compare with when it breaks.

What the users see right now:

```
./status.sh
```{{exec}}

You should only see `v1` and no failures. It helps to open a second terminal tab (the `+` at the top) and leave the status refreshing there for the rest of the tutorial:

```
watch -n1 /root/tutorial/status.sh
```{{copy}}

You can also talk to the app yourself:

```
curl -s localhost:8001/users; echo
curl -s -X POST localhost:8001/users -H 'Content-Type: application/json' -d '{"name": "Ada Lovelace"}'; echo
```{{exec}}

Every schema change lives in a SQL file in `db/migrations/`, with an `up` part and a `down` part. dbmate remembers which files it already applied in a table called `schema_migrations`:

```
cat db/migrations/20261001000000_create_users.sql
dbmate status
```{{exec}}

Keeping schema changes as versioned files in Git means they can be reviewed, they run the same way in every environment, and a pipeline can work with them. It's the same idea as Infrastructure as Code, just for the database.

And this is the only line that is different between v1 and v2:

```
grep -n "COLUMN =" app.py
```{{exec}}

Click Check when you're done.
