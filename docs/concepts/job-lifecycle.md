<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Job lifecycle


Local states: `STAGED` (validated, row written), `QUEUED`
(submitted), `RUNNING`, `REQUEUED` (Slurm took it back), `UNKNOWN`
(Slurm unobservable), then terminal `DONE`, `FAILED`, `CANCELLED`.
A rejected submission records `FAILED` with Slurm's message.

Slurm maps solver-agnostically: PENDING/SUSPENDED/CONFIGURING to
QUEUED; RUNNING/COMPLETING to RUNNING; COMPLETED to DONE;
FAILED/OUT_OF_MEMORY to FAILED; CANCELLED to CANCELLED;
TIMEOUT/PREEMPTED/NODE_FAIL/REVOKED/RESIZING/SPECIAL_EXIT to
REQUEUED; anything else is preserved verbatim. State comes from
`squeue`, then `scontrol`, then `sacct`; without accounting storage
a long-finished job becomes `UNKNOWN` under a bounded retry budget
(`MaxUnknown`, default 5), after which `watch` returns an error.
