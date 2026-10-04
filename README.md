# Safe database migrations in Continuous Delivery

An executable tutorial for DD2482 Automated Software Testing and DevOps (KTH, 2026).

**Run it in the browser:** https://killercoda.com/tomasmbrito/scenario/safe-db-migrations

You break a live service with a one-line schema migration, add a migration linter as a gate in a small CI/CD pipeline, and then rename the column again with the expand/contract pattern while traffic keeps flowing, without a single failed request.

**Tools:** PostgreSQL 16, [dbmate](https://github.com/amacneil/dbmate) (migrations), [squawk](https://squawkhq.com) (migration linter), a small Python service in two versions, and bash scripts that simulate users, a load balancer, rolling deploys and the pipeline.

## Structure

```
safe-db-migrations/        the Killercoda scenario
  index.json               list of steps, assets and the backend image
  intro.md                 learning outcomes, architecture, what gets installed
  background.sh            setup that runs while the intro is shown
  step1.md ... step8.md    the steps
  verify1.sh ... verify7.sh  checks behind the "Check" button
  finish.md                summary and further reading
  assets/                  copied to /root/tutorial in the sandbox
    app.py                 the service (v1 uses "name", v2 uses "full_name")
    ci.sh                  the pipeline: squawk, then dbmate up
    deploy.sh              start/stop one app version
    traffic.sh, status.sh  fake users and what they saw
    backfill.sh            fills the new column in batches
  images/                  diagrams used in the text
diagrams-src/              svg sources of the diagrams
```

All tool versions are pinned in `safe-db-migrations/background.sh`. No accounts or secrets are needed.

## Authors

Tomás Brito (tmldjb@kth.se) and Cesar Aceves Hernández (cesarah@kth.se)
