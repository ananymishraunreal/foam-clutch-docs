<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0004: Scheduler interface with rest and cli backends


## Context

Clusters vary: some run `slurmrestd`, most have sbatch CLI.

## Decision

One `Submit/State/Cancel` interface; `cli` shells out,
`rest` speaks slurmrestd; `auto` prefers REST when fully configured.

## Consequences

Orchestration never branches on backend; state sources differ in
fidelity (`sacct` last resort, `UNKNOWN` without accounting).

## Alternatives

REST-only (rejected: excludes common clusters). Rationale:
TODO(owner) for the exact readiness rule.
