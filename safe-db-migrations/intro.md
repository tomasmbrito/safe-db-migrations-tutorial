# Safe database migrations in Continuous Delivery

Your team deploys many times a day. Rolling back a bad *code* change is easy: deploy the previous version again. Rolling back a bad *schema* change is not, because the database keeps its state. On top of that, during a rolling deploy the **old and the new version of the app run at the same time against the same database**. A schema change that only the new version understands breaks the old one, and your users see errors.

In this tutorial you will break a running service with an innocent-looking migration, then build the two things that prevent it:

1. an automated **gate in the delivery pipeline** that lints every migration before it reaches the database, and
2. the **expand/contract pattern**, which turns one dangerous change into a few safe ones.

## Intended learning outcomes

After this tutorial you will be able to:

- **explain** why schema changes are the hard part of zero-downtime deployments, and why the old and the new app version must both work with the schema during a rollout;
- **manage** schema changes as versioned migration files with `dbmate`, and apply and roll them back;
- **add** an automated migration linter (`squawk`) to a CI/CD pipeline and interpret the problems it reports;
- **perform** a column rename with the expand/contract pattern (expand, backfill, rolling deploy, contract) while the service keeps serving traffic;
- **recognise** operations that take heavy table locks (like a normal `CREATE INDEX`) and use the non-blocking alternative;
- **judge** when this approach is worth its cost and when it is not.

## The system

![Architecture](https://raw.githubusercontent.com/tomasmbrito/safe-db-migrations-tutorial/main/safe-db-migrations/images/architecture.png)

- **App v1 / v2**: a tiny user directory service (Python). v1 stores a user's name in the column `name`; v2 uses `full_name`. Same HTTP API.
- **Load balancer**: a list of active versions in `state/active_versions`; traffic is sent round robin to them, like in a rolling deploy.
- **Users**: `traffic.sh` sends a request every 0.3 seconds. `./status.sh` shows what they experienced in the last 10 seconds.
- **PostgreSQL 16**: one table, `users`, with 200,000 existing customers.
- **dbmate**: a small, language-agnostic migration tool. Migrations are plain SQL files in `db/migrations/`.
- **squawk**: a linter that knows which PostgreSQL statements are dangerous on a live database.
- **ci.sh**: our pipeline. Stage 1 lints pending migrations, stage 2 applies them.

Everything is being installed in the background (about a minute). The terminal tells you when it is ready.
