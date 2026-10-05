# Safe database migrations in Continuous Delivery

An executable tutorial for DD2482 Automated Software Testing and DevOps (KTH, 2026).

Run it in the browser: https://killercoda.com/tomasmbrito/scenario/safe-db-migrations

You break a running service with a one-line schema migration, add a migration linter as a check in a small CI/CD pipeline, and then do the same rename again with the expand/contract pattern while traffic keeps going, this time without any failed requests.

Tools: PostgreSQL 16, [dbmate](https://github.com/amacneil/dbmate) (migrations), [squawk](https://squawkhq.com) (migration linter), a small Python service in two versions, and bash scripts that simulate users, a load balancer, rolling deploys and the pipeline.

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

## Use of AI

We chose the topic and the tools, and we reviewed, edited and tested every step ourselves, both locally and on Killercoda. We used an AI assistant to help draft parts of the text, the scripts and the diagrams.
