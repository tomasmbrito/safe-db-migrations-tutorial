# Migrate: backfill and roll out v2

**Backfill the old rows.** Copy `name` into `full_name` for every row that existed before the expand step. Look at how the script does it first:

```
cat backfill.sh
```{{exec}}

It updates **5,000 rows at a time**, each batch in its own short transaction. A single `UPDATE users SET full_name = name` would also work, but on a big table it would hold row locks on every row for the whole run and produce one huge transaction; batches keep the database responsive while the backfill runs.

```
./backfill.sh
```{{exec}}

**Roll out v2.** Start the new version and add it to the load balancer, exactly one step of a rolling deploy:

```
./deploy.sh start v2
sleep 4; ./status.sh
```{{exec}}

Both versions now serve traffic **at the same time**, one using `name` and one using `full_name`, and neither fails. This is the state that the naive rename made impossible. Both see the same data:

```
curl -s localhost:8001/users; echo
curl -s localhost:8002/users; echo
```{{exec}}

**Finish the rollout** by taking v1 out of the load balancer and stopping it:

```
./deploy.sh stop v1
sleep 3; ./status.sh
```{{exec}}

Only v2 is left, still without errors. Nothing reads or writes `name` anymore, so it is safe to contract.
