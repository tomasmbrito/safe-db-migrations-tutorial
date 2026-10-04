# Done!

You changed the schema of a live service three times without a single failed request.

What you did:

- broke production with a one-line rename, and saw why: during a rollout the **old app version still runs against the new schema**;
- added a **migration linter as a pipeline stage** that blocks unsafe changes before they reach the database;
- renamed the column with **expand → migrate → contract**, keeping every running version compatible at every moment;
- replaced blocking operations (`SET NOT NULL`, `CREATE INDEX`) with **non-blocking alternatives** (`CHECK ... NOT VALID` + `VALIDATE`, `CREATE INDEX CONCURRENTLY`).

The full history of the schema is in the migration files, applied in order by dbmate:

```
dbmate status
ls db/migrations
```{{exec}}

## Further reading

- Martin Fowler, *ParallelChange*: https://martinfowler.com/bliki/ParallelChange.html
- squawk rules, with an explanation and a safe alternative for each: https://squawkhq.com/docs/rules
- dbmate documentation: https://github.com/amacneil/dbmate
- PostgreSQL documentation on explicit locking: https://www.postgresql.org/docs/16/explicit-locking.html
