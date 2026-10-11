<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0003: Cooperative USR1 checkpointing


## Context

Walltime kills solvers without usable restarts.

## Decision

Slurm `--signal=B:USR1@N` plus a trap that sets `stopAt writeNow`,
then `scontrol requeue`; next attempt starts at `latestTime`.

## Consequences

Needs `runTimeModifiable`, a cooperating solver, and requeue
permission. Requeue loops possible.

## Alternatives

Application-level checkpoint formats (solver-specific, rejected).
Rationale: TODO(owner) for the N-seconds-before-walltime choice.
