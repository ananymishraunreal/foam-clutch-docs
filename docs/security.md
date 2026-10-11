<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# Security


## Trust boundaries

You trust three things: the manifest author, the case author, and
the cluster. Sluice adds no sandbox between them. Every manifest
field below becomes a shell command run with your Unix identity on
the login or compute node:

- `solver.name` and `solver.arguments` run inside the batch script.
- `mesh.commands` and `post.commands` run through the same wrapper.
- `resources.sbatchExtra` appends raw `#SBATCH` lines (CLI) and REST
  fields.
- `runtime.foamBashrc` is sourced by the job shell.
- `case.include` stages files such as `Allrun`, which the job can
  execute.

Say it plainly: a malicious manifest or case runs arbitrary commands
as you. Do not submit manifests or cases you did not write or
review, and do not run the service for untrusted users.

## What preflight catches

Known code-loading directives in case dictionaries (`#codeStream`,
`#calc`, `codedFixedValue`, `codedMixed`, `libs`) and symlinks
escaping the case. It does not catch novel directives, code inside
`Allrun`/included scripts, container images, or anything the target
OpenFOAM version newly loads.

## JWT handling

Prefer `SLURM_JWT_FILE` (re-read per request, rotation-safe) over
`SLURM_JWT`. Tokens never appear in logs. Keep lifetimes short and
files `0600`.

## Production hardening checklist (not features)

Authenticate every caller; authorize accounts, partitions, and
paths; run jobs as the submitting user; isolate case data per user;
use a verified read-only image; enforce CPU/memory/disk/walltime
limits; never share the SQLite file over writable paths; log
submissions without secrets; scan archives for traversal; review new
OpenFOAM directives per version.
