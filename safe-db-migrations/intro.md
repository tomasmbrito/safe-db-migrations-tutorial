# Safe database migrations in Continuous Delivery

When a deploy goes wrong you can usually just roll back to the previous version of the code. The database is different: it keeps its state, so a bad schema change does not simply go away. And during a rolling deploy there is a period where the old and the new version of the app both run against the same database. If the schema change only works for the new version, the old one starts failing while it is still serving users.

In this tutorial we break a running service with a migration that looks completely harmless, and then fix the process in two ways:

1. we add a check to the delivery pipeline that lints every migration before it touches the database
2. we redo the change with the expand/contract pattern, which splits one risky change into a few safe ones

## Intended learning outcomes

After the tutorial you should be able to:

- explain why schema changes are the hard part of zero-downtime deployments, and why the old and the new app version both have to work with the schema during a rollout
- manage schema changes as versioned migration files with `dbmate`, apply them and roll them back
- add a migration linter (`squawk`) to a CI/CD pipeline and understand what it reports
- rename a column with expand/contract (expand, backfill, rolling deploy, contract) while the service keeps serving traffic
- recognise operations that lock a table for a long time, like a normal `CREATE INDEX`, and use the non-blocking version instead
- judge when this approach is worth the extra work and when it isn't

## What is running

![Architecture](https://raw.githubusercontent.com/tomasmbrito/safe-db-migrations-tutorial/main/safe-db-migrations/images/architecture.png)

- `app.py` is a small user directory service. Version v1 stores the name in the column `name`, v2 uses `full_name`. Both have the same HTTP API.
- The "load balancer" is just a file, `state/active_versions`. Traffic goes round robin to the versions listed there, like during a rolling deploy.
- `traffic.sh` plays the users and sends a request every 0.3 seconds. `./status.sh` shows what they got in the last 10 seconds.
- PostgreSQL 16 with one table, `users`, that already has 200,000 customers.
- dbmate runs the migrations, which are plain SQL files in `db/migrations/`.
- squawk is a linter that knows which PostgreSQL statements are dangerous on a live database.
- `ci.sh` is our pipeline: first it lints the pending migrations, then it applies them.

Everything gets installed in the background while you read this (takes about a minute). The terminal tells you when it's ready.
