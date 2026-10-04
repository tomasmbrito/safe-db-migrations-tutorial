# Migrate: backfill and roll out v2

Now we fill in the old rows, copying `name` into `full_name` for everything that existed before the expand step. Have a look at the script first:

```
cat backfill.sh
```{{exec}}

It updates 5,000 rows at a time, each batch in its own short transaction. A single `UPDATE users SET full_name = name` would also work, but on a big table it would lock every row for the whole run and create one huge transaction. With batches the database stays responsive while the backfill runs.

```
./backfill.sh
```{{exec}}

Next, roll out v2: start the new version and add it to the load balancer, which is one step of a rolling deploy:

```
./deploy.sh start v2
sleep 4; ./status.sh
```{{exec}}

Now both versions serve traffic at the same time, one with `name` and one with `full_name`, and neither fails. This is exactly the situation the plain rename couldn't handle. They also see the same data:

```
curl -s localhost:8001/users; echo
curl -s localhost:8002/users; echo
```{{exec}}

To finish the rollout, take v1 out of the load balancer and stop it:

```
./deploy.sh stop v1
sleep 3; ./status.sh
```{{exec}}

Only v2 is left, still with no errors. Nothing uses `name` anymore, so we can contract.
