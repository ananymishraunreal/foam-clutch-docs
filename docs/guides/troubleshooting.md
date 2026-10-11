<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Troubleshooting


Each entry shows the exact message, its cause, its fix, and how to
confirm. Doctor checks link to entries: Slurm CLI, Slurm REST, JWT,
Slurm policy (requeue), OpenFOAM, MPI, Storage paths, Disk space,
Legacy install.

## `codedFixedValue` / `#codeStream` / `#calc` / `codedMixed` / `libs` rejected

Cause: a dictionary under `0/`, `0.orig/`, `constant/`, or `system/`
contains a code-loading directive. Fix: remove it or have the
operator vet an exemption. Confirm: `sluice validate --manifest
/abs/manifest.yaml`.

## symlink escapes case

Cause: a link target resolves outside the case directory. Fix:
vendor the file inside the case or list its top level in
`case.include`. Confirm: `sluice validate`.

## `decomposeParDict numberOfSubdomains=N does not match resources ... ranks`

Cause: parallel run whose dict count differs from
`nodes x tasksPerNode`. Fix: edit the dict or the manifest.
Confirm: `sluice validate`.

## `solver.checkpointSeconds=N requires runTimeModifiable true`

Cause: checkpointing armed on a non-modifiable controlDict. Fix: add
`runTimeModifiable true;` or set `checkpointSeconds: 0`. Confirm:
`sluice validate`.

## `mesh.strategy=auto found neither constant/polyMesh nor system/blockMeshDict`

Cause: no mesh source. Fix: ship `blockMeshDict`/`polyMesh`, add
`mesh.commands` with strategy `custom`, or use `none`. Confirm:
`sluice validate`.

## JWT expired / authentication rejected / API version not served

Cause: bad token, wrong user, or wrong `SLURM_API_VERSION` (check the
cluster `/openapi/v3`). Fix: refresh the token file, verify user and
version. Confirm: `sluice doctor`.

## requeue disabled / could not determine requeue policy

Cause: `JobRequeue` off while checkpointing is on (or `scontrol`
unavailable). Fix: enable requeue or set `checkpointSeconds: 0`.
Confirm: `sluice doctor --manifest /abs/manifest.yaml`.

## Job stuck QUEUED

Cause: still pending in Slurm. Fix: `squeue -j <slurm-id>`, then
`sluice status --id <id> --refresh`. The row only moves when Slurm
moves.

## `UNKNOWN` state (accounting disabled)

Cause: job left `slurmctld` and `sacct` has no record. Bounded
retries follow, then `watch` errors. Fix: enable accounting storage
or accept `UNKNOWN` for old jobs.

## Checkpoint requeue loop

Cause: every attempt times out again. Fix: longer walltime, smaller
checkpoint interval, or fix solver speed. Each generation restarts
from `latestTime`.

## Disk full / run directory not writable / DB locked

Cause: full filesystem or contested SQLite file. Fix: free space,
move cache/run dirs, keep one writer per DB. Confirm: `sluice
doctor`.

## Where are my logs

Run `sluice logs --manifest /abs/manifest.yaml --latest` or
`tail -f $(sluice logs --manifest /abs/manifest.yaml --latest
--follow=false)`. Files: `log.solver`, `slurm-<id>.out`,
`slurm-<id>.err` in the run directory.
