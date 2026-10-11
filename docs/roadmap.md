<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# Roadmap


These are not features. Nothing below exists today.

## From About.md "What production still needs"

Token refresh and secret management; HTTP auth and auth; real
submit/cancel handlers; Postgres for replicas; leases and outbox
events; restart reconciliation; bounded retry/backoff policies;
abandoned run cleanup; cache retention and quotas; solver dictionary
schemas; mesh-quality thresholds; directive allow-lists; immutable
images; retention rules; structured logs and alerts; Grafana
dashboards; node health checks; staging integration tests; scaling
benchmarks.

## From About.md performance notes

Topology-aware decomposition; node-local storage; collated I/O;
serial-reconstruction avoidance; rank pinning; partial-node
benchmarks; MPI-wait measurement; rank counts from observed scaling;
mesh/decomposition caching. An autotuner needs controlled probes and
measured time-per-simulated-second, not universal rules.

## From this docs pass

Sweep runner and result index; `sacct`-free history for old jobs;
restart reconciliation of `STAGED` rows.
