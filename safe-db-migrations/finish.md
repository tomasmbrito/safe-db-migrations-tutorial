# Done

You renamed a column and added an index on a live service, and neither change made a single request fail.

Quick recap:

- a one-line rename broke production, because during a rollout the old app version still runs against the new schema
- a migration linter in the pipeline blocks unsafe changes before they reach the database
- expand, migrate, contract renames the column while every running version keeps working
- blocking operations like `SET NOT NULL` and `CREATE INDEX` have non-blocking alternatives (`CHECK ... NOT VALID` + `VALIDATE`, and `CREATE INDEX CONCURRENTLY`)

The whole history of the schema is in the migration files, applied in order by dbmate:

```
dbmate status
ls db/migrations
```{{exec}}

## Further reading

- Martin Fowler, ParallelChange: https://martinfowler.com/bliki/ParallelChange.html
- squawk rules, each with an explanation and a safe alternative: https://squawkhq.com/docs/rules
- dbmate: https://github.com/amacneil/dbmate
- PostgreSQL docs on explicit locking: https://www.postgresql.org/docs/16/explicit-locking.html
