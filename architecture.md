# foam-clutch architecture

## 1. What it is

foam-clutch is a small Go control plane that runs OpenFOAM cases on a Slurm
cluster. It sits between the engineer (who owns a case directory plus a YAML
manifest) and the cluster (Slurm + OpenFOAM + MPI + shared filesystem) and
makes the workflow safe, repeatable, and observable:

```text
manifest.yaml + OpenFOAM case
        │
        ▼
┌───────────────────┐
│ 1. manifest load  │  strict YAML, defaults, validation (internal/manifest)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 2. preflight      │  layout, symlinks, code-loading directives,
│                   │  controlDict/solver agreement, decompose check,
│                   │  checkpoint + mesh-source checks
│                   │  (internal/preflight + internal/service checks)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 3. stage + cache  │  SHA-256 content-addressed cache, isolated run copy
│                   │  (internal/stage)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 4. persist        │  STAGED row in SQLite (internal/store)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 5. script render  │  batch script generated 100% from the manifest
│                   │  (internal/service)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 6. submit         │  sbatch CLI or slurmrestd REST behind one interface
│                   │  (internal/scheduler, client.go) → QUEUED row
└────────┬──────────┘
         ▼
┌───────────────────┐
│ 7. supervise      │  poll Slurm → DONE/FAILED/CANCELLED/REQUEUED
│                   │  (internal/supervisor, internal/telemetry)
└───────────────────┘
```

The project deliberately does not replace OpenFOAM, Slurm, MPI, ParaView, or
Prometheus. It connects them with one consistent workflow. There is no
solver-specific code anywhere: `solver.name` is an arbitrary executable, and
heavySimple (`foamRun` + `incompressibleFluid`), heavyBuoyant (`foamRun` +
`fluid`), and any future solver share the exact same path.

## 2. Components

### 2.1 Manifest (`internal/manifest`)

The manifest is the only contract. Strict YAML decoding rejects unknown
fields (`KnownFields(true)`), relative paths resolve against the manifest
file's directory, defaults are applied (`fileHandler: collated`,
`mesh.strategy: auto`, `mpi.launcher: mpirun`, `threadsPerRank: 1`,
`foamBashrc` from manifest → `$FOAM_BASHRC` → auto-detected
`/opt/openfoam*/etc/bashrc` → built-in fallback), then validation runs.

Key validation rules (`manifest.go:Validate`):

- `apiVersion` must be `foam-clutch/v1alpha1`.
- `case.include` entries must be case-relative, single-line, existing, and
  must not duplicate canonical inputs or reference runner artefacts.
- `solver.name` must be a bare executable name (letters, digits, `. _ + -`,
  no slashes/whitespace) — any stock or custom solver passes.
- `solver.fileHandler` is `collated`, `uncollated`, or `none`.
- `checkpointSeconds` must be below the walltime.
- `mesh.strategy` is `auto`, `blockMesh`, `custom` (requires `commands`),
  or `none`.
- `runtime.mpi.launcher` is `mpirun` or `srun`.
- `resources.sbatchExtra` entries look like `--key`/`--key=value` and must
  not repeat runner-managed options (`job-name`, `partition`, `nodes`,
  `ntasks`, `time`, `output`, `error`, `signal`, `exclusive`, `hint`,
  `requeue`, ...). They are appended verbatim to the CLI script and
  best-effort mapped onto REST job fields via `SbatchExtraVars`.

### 2.2 Preflight (`internal/preflight`)

Cheap rejection before queue time is spent. `Runner.Run`:

1. Requires `system/` and `constant/` directories, plus `0/` **or** `0.orig/`
   (tutorials commonly ship `0.orig`).
2. Walks the case, skipping artefacts entirely (`.git`, `.foam-cache`,
   `.foam-runs`, `processor*`, `slurm-*`, `log.*`, `*.db*`).
3. Rejects symlinks escaping the case directory.
4. Scans only `0/`, `0.orig/`, `constant/`, `system/` dictionaries for the
   executable-directive blocklist `#codeStream`, `#calc`,
   `codedFixedValue`, `codedMixed`, `libs`. Docs and scripts mentioning
   those words never trigger findings. `AllowedDirectives` can exempt
   vetted tokens per case.
5. Optionally runs `foamDictionary -case` and `checkMesh -case` when
   configured; failures become findings.

### 2.3 Service checks (`internal/service`)

After preflight, `Service.Validate` runs four manifest-aware checks that
are generic over every project:

- `checkDecomposition` — skipped for serial runs (`ranks == 1`) and
  `mesh.strategy: none`. Otherwise `system/decomposeParDict`
  `numberOfSubdomains` must equal `nodes × tasksPerNode`, else fail fast
  instead of aborting inside the allocation.
- `checkControlDict` — parses `application` / `solver` entries with
  comment stripping. `application foamRun` requires manifest solver
  `foamRun` plus any `solver <model>;` physics entry (never hard-coded:
  `incompressibleFluid`, `fluid`, anything). A native application must
  equal the manifest solver name. Catches copy-paste manifests.
- `checkCheckpoint` — `checkpointSeconds > 0` requires
  `runTimeModifiable true`, otherwise the USR1 trap would silently do
  nothing and the job would die at walltime with no restart.
- `checkMeshSource` — `blockMesh` strategy needs `system/blockMeshDict`;
  `auto` needs `constant/polyMesh` or `system/blockMeshDict`;
  `custom`/`none` always pass.

### 2.4 Staging (`internal/stage`)

`Stager.Stage(caseDir, include...)`:

- Validates `case.include` tops (must exist, must not be canonical inputs
  or artefacts), then hashes the canonical inputs (`0/`, `0.orig/`,
  `constant/`, `system/`) plus included tops: relative paths sorted,
  file contents mixed in, symlinks hashed by target string. Result:
  SHA-256 hex digest.
- Cache directory `<cacheDir>/<sha256>/` is reused on hit (`Cached: true`).
  On miss, a temp dir is populated and atomically renamed (concurrent
  submitters racing the same hash converge: rename loser sees the winner).
- `Materialize` copies the cached case to `<runDir>/<uuid>/`. The run copy
  — never the cache — absorbs checkpoint edits (`controlDict`), logs,
  time directories, and `processor*`, keeping the cache a stable input
  artifact. Auxiliary files at the case root (README, scripts, manifests,
  logs, DBs) never enter the hash or the cache.

### 2.5 Persistence (`internal/store`)

SQLite (WAL, `busy_timeout`, single connection) with table `jobs`:

```text
id, name, state, manifest_path, case_hash, run_path, cache_path,
slurm_id, error, updated_at  (+ indexes on updated_at and state)
```

`run_path`/`cache_path` are added by migration to older databases.
Lifecycle: `Create(STAGED)` → `UpdatePaths(run, cache)` →
`UpdateState(QUEUED, slurmID)` → supervisor moves it to
`RUNNING`/`REQUEUED`/`UNKNOWN` → terminal `DONE`/`FAILED`/`CANCELLED`
(or `FAILED` on submit rejection). `ListByState` powers the CLI and
`/jobs?state=`; `GetBySlurm` finds a local job from a Slurm ID.

Local state machine:

```text
STAGED → QUEUED ⇄ RUNNING ⇄ REQUEUED → DONE / FAILED / CANCELLED
              ↘ UNKNOWN (Slurm unobservable, bounded retries)
```

### 2.6 Script rendering (`internal/service:checkpointScript`)

The whole batch script is built from the manifest — the single source of
the "no hard-coded element" property:

- **SBATCH header**: job-name, optional partition/account, nodes,
  ntasks-per-node, ntasks, walltime, `--exclusive`, `--hint=nomultithread`,
  `--requeue` + `--signal=B:USR1@N` only when `checkpointSeconds > 0`,
  raw `sbatchExtra` lines, explicit `--output/--error` into the run dir.
- **Environment**: sources `runtime.foamBashrc` (nounset-safe),
  `OMP_NUM_THREADS=threadsPerRank`.
- **Wrappers**: `foam_serial` / `foam_mpi` take one shell-command string.
  Host vs Apptainer-container and `mpirun` vs `srun` (flavour, extra args)
  only change the wrapper bodies. Quoting is single-quote escaping,
  verified safe for arguments containing spaces, quotes, `$`, backticks.
- **Mesh** per strategy: `none` skips; `blockMesh` always runs;
  `custom` runs `mesh.commands` when no `polyMesh`; `auto` uses
  `polyMesh` if present else `blockMesh` if `blockMeshDict` exists else
  errors with guidance. Idempotent across requeues.
- **Decompose**: skipped for serial runs; otherwise asserts
  `numberOfSubdomains == $SLURM_NTASKS` and rebuilds `processor*` when the
  count mismatches. Idempotent across requeues.
- **Solver**: `foamDictionary startFrom latestTime` (best effort), then
  `<name> <args> [-parallel] [-fileHandler …]` via `foam_serial` (serial)
  or `foam_mpi` (parallel) into `log.solver`. With checkpointing, a
  `checkpoint()` trap on USR1 sets `stopAt writeNow`, touches
  `.foam-checkpoint-requested`, and the script calls `scontrol requeue`.
  With `checkpointSeconds: 0` all of that is omitted.
- **Post**: after `RC == 0` without checkpoint, optional `reconstructPar`
  (parallel only) then `post.commands`.

`JobSpec` sent to the scheduler carries `Dir`, `Stdout`/`Stderr`
(`slurm-%j` in the run dir — REST ignores `#SBATCH`, so these matter),
`Requeue = checkpoint > 0`, and `Extra = {exclusive, hint, signal?,
sbatchExtra…}`.

### 2.7 Schedulers

One `Scheduler` interface (`Submit/State/Cancel`) with two adapters:

- **CLI** (`internal/scheduler`): `sbatch --parsable` (parses `id` or
  `id;cluster`), script saved as `<runDir>/foam-clutch.sbatch` (exact
  reproduction artifact). State via `squeue` → `scontrol` → `sacct`
  (covers pending through long-finished jobs; without accounting the job
  becomes `UNKNOWN` under a bounded retry budget). `scancel` cancels.
  Binaries overridable for tests. Works with zero configuration.
- **REST** (`client.go`): `slurmrestd` HTTP or Unix socket, `X-SLURM-USER-NAME`
  + `X-SLURM-USER-TOKEN` (refreshable provider func), API version in path
  (e.g. `v0.0.43` for Slurm 25.05 — verify against the cluster's
  `/openapi/v3`). Sends `nodes` as string, `time_limit` as
  `{number,set,infinite}`, default `PATH` environment, merges `Extra`.
  30 s timeout, 8 MiB response cap, Slurm `errors[]` surfaced even on
  HTTP 200. `auto` backend prefers REST when its env is fully set.

### 2.8 Supervision (`internal/supervisor`)

`Watch(localID, slurmID)` polls immediately (short jobs aren't missed),
then on a ticker (default 15 s). Slurm states map solver-agnostically:
`PENDING/SUSPENDED/CONFIGURING→QUEUED`, `RUNNING/COMPLETING→RUNNING`,
`COMPLETED→DONE`, `FAILED/OUT_OF_MEMORY→FAILED`, `CANCELLED→CANCELLED`,
`TIMEOUT/PREEMPTED/NODE_FAIL/REVOKED/RESIZING/SPECIAL_EXIT→REQUEUED`
(keeps polling — Slurm requeues). State errors mark `UNKNOWN`; after
`MaxUnknown` (default 5) consecutive failures `Watch` returns instead of
hanging forever. Terminal/requeue observations bump Prometheus counters.

### 2.9 CLI (`cmd/foam-clutch`)

- `run` — validate → submit → watch in one call. `-db` defaults to
  `<manifest-dir>/foam-clutch.db`. `-tail` streams solver + Slurm logs.
- `submit [-watch]`, `validate` (prints manifest + report JSON),
  `watch`, `status [-refresh]`, `cancel`, `list [-state]`,
  `logs [-id | -latest] [-follow]`, `init` (scaffold any solver),
  `serve`, `version`. All long-running commands respect Ctrl-C.
- `logs` resolves log paths from the DB: `tail -f $(… logs -latest
  -follow=false)` needs no pasted IDs.
- Token provider re-reads `SLURM_JWT_FILE` every request (rotation-safe),
  falling back to `SLURM_JWT`.

### 2.10 HTTP service

`serve` exposes `/healthz`, `/readyz` (DB check), `/metrics`
(Prometheus), `/jobs?state=` (Bearer auth when `FOAM_CLUTCH_API_TOKEN`
is set), `/version`. Graceful shutdown on SIGTERM, request logging,
read/write/idle timeouts. Read-only: no submit endpoint (add auth first).

### 2.11 Telemetry (`internal/telemetry`)

Nine process-local counters: submissions, preflight failures, stage
cache hits/misses, requeues, jobs done/failed/cancelled, watch errors.

## 3. Data flow for one `run`

```text
manifest.yaml ──Load──▶ Manifest ──Preflight──▶ Report
                                            ──checks──▶ ok
case/ ──Stage(hash)──▶ .foam-cache/<sha> ──Materialize──▶ .foam-runs/<uuid>/
store.Create(STAGED) ──UpdatePaths──▶ checkpointScript ──Submit──▶ slurmID
store.UpdateState(QUEUED) ──Watch poll──▶ RUNNING ⇄ REQUEUED ──▶ DONE/FAILED/CANCELLED
```

## 4. Failure modes

| Failure | Behavior |
|---|---|
| Bad manifest/case | `run` fails before DB/Slurm; `validate` prints JSON reason |
| `sbatch` rejects | local row → `FAILED` with Slurm's message |
| Solver exits non-zero | `FAILED`; `post` skipped; logs kept in run dir |
| Walltime approaches | USR1 → `writeNow` → `scontrol requeue` → restarts at `latestTime` |
| Job vanishes from Slurm | `UNKNOWN`, bounded retries, then `Watch` errors out |
| Ctrl-C during watch | polling stops; Slurm job keeps running; re-`watch`/`status` later |
| Two submits, same case | same hash → cache hit; separate run dirs, separate Slurm jobs |

## 5. What is intentionally not in the box

AuthN/Z on submit paths, Postgres/multi-instance store, outbox events,
restart reconciliation, `checkMesh` quality thresholds, residual/Courant
log parsing, Grafana dashboards, result indexing, autotuning, retention
cleanup. Each is a defined next step, not an accident — see the repo
`README.md` Limitations and `About.md` roadmap.
