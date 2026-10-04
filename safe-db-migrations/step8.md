# Reflection: is it worth it?

We renamed one column with five migrations and two app deploys, instead of one line, and added a check that sometimes says no. That has a cost, so it's worth thinking about when it pays off.

## Why these tools

dbmate keeps migrations as plain SQL with an `up` and a `down` part, and it doesn't care what language the app is written in. We picked it because the point here is the SQL that actually reaches PostgreSQL. Framework tools like Django migrations, Rails, Alembic, Flyway or Liquibase do the same job, and in a real project you'd use whatever fits your stack. The patterns stay the same.

squawk is made specifically for PostgreSQL and understands lock levels, not just syntax. It's a single binary, with no server and no account, so it fits in any CI job (it can even comment on a GitHub pull request).

The lint stage runs before the deploy stage for the usual pipeline reason: fail early and cheaply, before anything you can't undo.

## When it's useful

- Services that deploy often with rolling, blue-green or canary deployments, where two versions always overlap for a while.
- Large or busy tables, where locking or rewriting the table means minutes of blocked requests.
- Teams where not everyone knows PostgreSQL's locking rules. The linter shares that knowledge with everyone.
- Databases used by several services or jobs, where deploying everything at once isn't even an option.

## When it's not

- Small internal tools or early prototypes, where 30 seconds of downtime at night is fine. One migration plus a short maintenance window is simpler and harder to get wrong.
- Tiny tables, where every lock only lasts a few milliseconds anyway.
- Data you can rebuild, like caches or analytics copies. Just drop and recreate it.

## Limitations

- A linter checks patterns, not your data. It doesn't know a table has 500 million rows, or that some reporting job nobody told you about still reads a column. It also complains about things that are fine in context, which is why the `squawk-ignore` comments matter: an exception should be visible and reviewed.
- Expand/contract needs discipline. The contract step is easy to forget, and old columns and sync triggers pile up.
- The trigger adds a bit of cost to every write, and logic hidden in triggers is easy to overlook.
- Rollbacks aren't symmetric. After the contract step you can't go back to v1 anymore, so a fix usually means going forward.
- The lock demo was faked with `pg_sleep`. With real data you should measure, for example by running the migration against a production-sized copy in staging.

## Who it's for

Mostly backend developers who write migrations, and the platform or DevOps people who own the pipeline. The linter is a way to put the platform team's knowledge into the pipeline, and expand/contract is a habit the developers need to pick up.
