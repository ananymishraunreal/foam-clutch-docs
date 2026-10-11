<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0001: Separate cache and run directory


## Context

Checkpointing edits `system/controlDict` and the solver writes logs
and time directories during the run.

## Decision

Stage into an immutable content-addressed cache, then materialize a
private run copy per job. The cache never absorbs run edits.

## Consequences

Reproducible reruns and safe cache reuse; double disk use per job.

## Alternatives

Run in the cache directly (rejected: edits would poison later jobs).
Rationale: TODO(owner) for why copy won over overlay/bind-mount.
