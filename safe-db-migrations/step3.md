# Put a gate in the pipeline

The rename is still in `db/migrations/` as a pending migration. This time we send it through our pipeline, `ci.sh`:

```
cat ci.sh
```{{exec}}

It has two stages, like a real CI/CD job: first it runs `squawk` on every migration that isn't applied yet, and only if that passes it runs `dbmate up`.

squawk parses the SQL and knows which statements are risky on a live PostgreSQL database: which locks they take, what they block and which ones break clients that are still running. Its settings are in `.squawk.toml`:

```
cat .squawk.toml
```{{exec}}

Run the pipeline:

```
./ci.sh
```{{exec}}

The pipeline is blocked and the database wasn't touched. The warnings are worth reading:

- `renaming-column`: renaming a column may break existing clients. That's exactly what happened in the last step.
- `require-lock-timeout`: the `ALTER` needs an `ACCESS EXCLUSIVE` lock, which blocks all reads and writes. If it has to wait behind a long query, every request queues up behind it too. With a `lock_timeout` the migration gives up quickly instead.
- `require-statement-timeout`: same idea, for statements that run for a long time.

Why not just rely on code review? Reviewers know the business logic, but not many people know by heart which `ALTER TABLE` variants rewrite the table or which lock they take. Putting that knowledge in a check that runs on every change makes it repeatable, and you get the feedback when you write the migration instead of when production breaks. Basically "shift left", but for the database.

There's no safe way to do the rename in one go, so delete it. The next steps make the same change safely:

```
rm db/migrations/20261002000000_rename_name_to_full_name.sql
dbmate status
```{{exec}}
