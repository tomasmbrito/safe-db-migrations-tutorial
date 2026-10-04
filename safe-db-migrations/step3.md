# Put a gate in the pipeline

The rename is still sitting in `db/migrations/` as a pending migration. This time it goes through our pipeline, `ci.sh`:

```
cat ci.sh
```{{exec}}

It has two stages, like a real CI/CD job:

1. **lint**: run `squawk` on every migration that is not applied yet;
2. **deploy**: only if stage 1 passed, run `dbmate up`.

squawk parses the SQL and knows which statements are dangerous on a live PostgreSQL database: which locks they take, what they block, and which ones break running clients. Its settings live in `.squawk.toml`:

```
cat .squawk.toml
```{{exec}}

Run the pipeline:

```
./ci.sh
```{{exec}}

The pipeline is **blocked** and the database was never touched. Read the warnings, they are the useful part:

- `renaming-column`: *renaming a column may break existing clients*. This is exactly what happened in the previous step;
- `require-lock-timeout`: the `ALTER` needs an `ACCESS EXCLUSIVE` lock, which blocks all reads and writes. If it has to wait for a long query, every request queues up behind it. A `lock_timeout` makes the migration give up quickly instead;
- `require-statement-timeout`: the same idea for statements that run for a long time.

Why a linter and not just code review? Reviewers know the business logic, but few know by heart which `ALTER TABLE` variants rewrite the table or take which lock. Encoding that knowledge in a check that runs on every change makes it **repeatable** and moves the feedback to the moment the migration is written, not the moment production breaks. This is "shift left" for databases.

The rename itself cannot be made safe, so delete it. The next steps do the same change in a safe way:

```
rm db/migrations/20261002000000_rename_name_to_full_name.sql
dbmate status
```{{exec}}
