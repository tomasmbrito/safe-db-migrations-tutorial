# Reflection: when is this worth it?

You renamed a column in **five migrations and two app deploys** instead of one line, and added a gate that sometimes says no. That is real cost, so it is worth being precise about when it pays off.

## Why these tools

- **dbmate** stores migrations as plain SQL with an `up` and a `down` part, and works with any language or framework. We used it because the point of the tutorial is the SQL that reaches PostgreSQL. Framework tools (Django, Rails, Alembic, Flyway, Liquibase) do the same job; in a real project you use the one that fits your stack. The patterns stay the same.
- **squawk** is specific to PostgreSQL and understands lock levels, not only syntax. It runs as a single binary with no server and no account, so it fits in any CI job (it can also comment directly on a GitHub pull request).
- **A separate lint stage before the deploy stage** follows the usual pipeline principle: fail fast and cheap, before anything irreversible happens.

## When it is useful

- Services that **deploy often** with rolling, blue-green or canary deployments, where two versions always overlap for a while.
- **Large or busy tables**, where a full-table lock or rewrite means minutes of blocked requests.
- **Teams**, where not everyone knows PostgreSQL's locking rules; the linter shares that knowledge with everyone.
- Systems where **several services or jobs read the same database**, so "just deploy everything at once" is not even possible.

## When it is not worth it

- **Small internal tools or early prototypes** where a 30-second maintenance window at night is fine. A single migration plus a short downtime is simpler and less error-prone.
- **Tiny tables**, where every lock lasts milliseconds anyway.
- **Data you can rebuild** (caches, analytics copies): drop and recreate.

## Limits of what you saw

- A linter checks **patterns, not your data**. It cannot know that a table has 500 million rows or that a column is still read by a reporting job nobody told you about. It also flags things that are fine in context, which is why the explicit `squawk-ignore` comments matter: an exception should be a visible, reviewed decision.
- Expand/contract needs **discipline over time**: the contract step is easy to forget, and half-finished migrations (old columns, sync triggers) pile up.
- The sync trigger costs a little on every write, and logic in triggers is easy to overlook.
- **Rollbacks are not symmetric**: after the contract step, rolling back the code to v1 is no longer possible. Going forward with a new fix is often the only real option.
- The lock demo was simulated with `pg_sleep`. On real data, measure: run the migration against a production-sized copy in a staging environment.

## Who it is for

Backend developers who write migrations, and the platform or DevOps engineers who own the deployment pipeline: the linter encodes the platform team's knowledge, and expand/contract is a habit the developers need.
