# Reflection: is it worth it?

We renamed one column with five migrations and two app deploys instead of one line, and added a check that sometimes blocks a change. That has a cost, so it's worth asking when the extra safety pays off.

## Why these tools

dbmate keeps migrations as plain SQL with an `up` and a `down` part, and it doesn't care what language the app is written in. We picked it because the point here is the SQL that actually reaches PostgreSQL. Framework tools like Django migrations, Rails, Alembic, Flyway or Liquibase do the same job, and in a real project you'd use whatever fits your stack. The underlying safety patterns stay the same.

squawk is made specifically for PostgreSQL and understands PostgreSQL lock levels and risky DDL patterns, not just SQL syntax. It's a single binary, with no server and no account, so it fits in any CI job (it can even comment on a GitHub pull request).

The concrete rules in this tutorial are PostgreSQL-specific, although broader ideas such as migration linting and expand/contract also apply to other database systems.

The lint stage runs before the deploy stage for the usual pipeline reason: fail early and cheaply, before anything you can't undo.

## When it's useful

- Services that deploy often with rolling, blue-green or canary deployments, where two versions always overlap for a while.
- Large or busy tables, where locking or rewriting a table can block requests long enough to cause visible outages.
- Teams where not everyone knows PostgreSQL's locking rules. The linter shares that knowledge with everyone.
- Databases used by several services or jobs, where deploying everything at once isn't even an option.

## When it's not

- Small internal tools or early prototypes where a short maintenance window is acceptable. One migration plus a maintenance window may be simpler and harder to get wrong.
- Small, lightly used tables where the relevant schema operation completes fast enough that the locking risk is negligible.
- Rebuildable data, such as caches or disposable analytics copies, where recreating the data may be simpler than carefully evolving the schema.

## Limitations

- A linter checks patterns, not your data. It doesn't know a table has 500 million rows, or that an external reporting job still reads a column. It also complains about things that are fine in context, which is why the `squawk-ignore` comments matter: an exception should be visible and reviewed.
- Expand/contract needs discipline. The contract step is easy to forget, and old columns and sync triggers pile up.
- The trigger adds overhead to every write, and logic hidden in triggers is easy to overlook.
- Rollbacks aren't symmetric. After the contract step you can't go back to v1 anymore, so a fix usually means going forward.
- The lock demo is simulated with `pg_sleep` to make the blocking behavior visible on a small dataset. With real data you should measure the actual migration behavior, ideally against a production-sized copy in staging.

## Who it's for

Mostly backend developers who write migrations, and the platform or DevOps people who own the pipeline. The linter is a way to put the platform team's knowledge into the pipeline, and expand/contract is a deployment practice application developers need to follow consistently.
