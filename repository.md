# foam-clutch repository map

Every file in `/home/shared/foam-clutch`, what it does, and how it connects
to the rest. Read `architecture.md` first for the pipeline this repo
implements.

```text
/home/shared/foam-clutch
├── README.md / About.md / humanizeabout.md   # docs (start here)
├── go.mod / go.sum / .gitignore              # build + hygiene
├── client.go / client_test.go                # slurmrestd adapter (root pkg)
├── cmd/foam-clutch/main.go                   # CLI: every user command
├── internal/
│   ├── manifest/    # YAML contract (manifest.go, tests, example.yaml)
│   ├── preflight/   # case safety checks
│   ├── stage/       # content cache + run copies
│   ├── store/       # SQLite job records
│   ├── service/     # validate → stage → submit orchestration + script render
│   ├── scheduler/   # sbatch/squeue CLI adapter
│   ├── supervisor/  # Slurm polling → local states
│   └── telemetry/   # Prometheus counters
├── solver.sbatch.tmpl                        # standalone batch template
├── openfoam.def                              # Apptainer image recipe
└── examples/        # runnable manifests (heavySimple, heavyBuoyant, generic)
```

---

## Root docs

### `README.md`
Quick-start and operator reference: what the project does, manifest schema,
validate/submit/watch/run/logs commands, scheduler backends, heavySimple +
heavyBuoyant examples, log addresses, HTTP service, cache/run layout,
checkpoint behavior, security model, limitations. Points here for depth.

### `About.md`
Design essay: full architecture vision (ingest → planner/autotuner →
stage/cache → scheduler adapter → chained jobs → telemetry → stage-out),
tech-stack table (Go, chi, Postgres/SQLite, slurmrestd + CLI fallback,
Apptainer, Lustre scratch, Prometheus → Grafana), and the three things to
settle early (dictionary code execution, where the daemon runs, which user
jobs run as). Sections 1–8 that are *not* yet built are explicitly marked
as roadmap, not implementation.

### `humanizeabout.md`
Plain-language walkthrough of the implemented workflow for non-HPC readers:
manifest as contract, preflight, cache vs run dir, SQLite truth,
scheduler adapter, cooperative checkpointing. Mirrors `About.md` without
assuming cluster background.

---

## Build

### `go.mod` / `go.sum`
Module `github.com/ananymishradev/foam-clutch`, Go 1.26. Direct needs are
tiny (`gopkg.in/yaml.v3` for manifests, `github.com/google/uuid` for job
IDs, `modernc.org/sqlite` for pure-Go SQLite — no CGO, so the binary builds
anywhere). Everything else in `go.mod` is indirect (transitive deps of the
SQLite driver).

### `.gitignore`
Keeps run state out of git: `*.db*`, `.foam-cache/`, `.foam-runs/`,
`slurm-*.out/.err`, solver/mesh logs, `processor*/`, built binary.

---

## Scheduler interface + REST adapter (root package)

### `client.go` (package `slurmrest`, ~366 lines)
The `Scheduler` interface the whole control plane programs against, plus
the `slurmrestd` implementation:

- `Scheduler` — `Submit(ctx, JobSpec) (jobID, err)`,
  `State(ctx, jobID) (states, err)`, `Cancel(ctx, jobID) error`.
- `Config` — `BaseURL` (HTTP) or `SocketPath` (Unix socket),
  `APIVersion` (e.g. `v0.0.43`), `User`, `Token` func (refreshable JWT),
  optional `HTTPClient`.
- `NewClient` validates config at startup (URL shape, no credentials in
  URL, sane API version, non-empty user, token provider present).
- `Submit` validates the spec, defaults the environment, sends `nodes` as
  string (v0.0.4x schema), `time_limit` as `{number,set,infinite}`, merges
  `Extra` last (version-specific fields win), and surfaces Slurm
  `errors[]` even on HTTP 200.
- `State` reads `job_state[]`; explains that `slurmctld` forgets jobs
  after `MinJobAge` (query `slurmdbd` for older jobs).
- Transport: 30 s timeout, 8 MiB response cap, context-aware, auth via
  `X-SLURM-USER-NAME` / `X-SLURM-USER-TOKEN`.

### `client_test.go`
Mock-server tests: submit/state/cancel round-trip (checks token header and
`nodes`/`tasks`/`dependency` body), config rejection, spec validation
before any request, API errors inside successful responses.

---

## `cmd/foam-clutch/main.go` (~700 lines) — the CLI

Every user-facing command. All long-running commands use
`signal.NotifyContext` (Ctrl-C safe).

- `run` — the single command: validate → submit → watch. `-db` defaults
  to `<manifest-dir>/foam-clutch.db`; fails fast on bad manifests before
  touching DB/Slurm; `-tail` streams solver + Slurm logs; watch phase is
  decoupled from the submit timeout.
- `submit [-watch]` — submit only (bounded `-timeout`); `-watch` continues
  polling like `run`.
- `validate` — prints `{manifest, report, error}` JSON; exit 1 when invalid.
- `watch` — poll a submitted job to a terminal state, print final record.
- `status [-refresh]` — read the record; `-refresh` queries Slurm once and
  maps through `supervisor.ToLocal`.
- `cancel` — `scancel` by local ID (Slurm ID resolved from DB) and mark
  `CANCELLED`.
- `list [-state]` — newest-first JSON job listing.
- `logs [-id | -latest] [-follow]` — resolve log paths from the DB; stream
  them (`-follow`, default) or print them for `tail -f $(…)` (`-follow=false`).
- `init` — scaffold a generic manifest for any solver name.
- `serve` — HTTP service (`/healthz`, `/readyz`, `/metrics`, `/jobs?state=`,
  `/version`), optional `FOAM_CLUTCH_API_TOKEN` Bearer auth, graceful
  10 s shutdown, request logging.
- `version` — build version (`-ldflags -X main.Version=…`).
- Helpers: `selectScheduler` (auto prefers REST when its env is complete,
  else CLI), `tokenProvider` (`SLURM_JWT_FILE` re-read per request, else
  `SLURM_JWT`), `tailRunLogs`/`tailFrom` (offset-tracking multi-file
  streamer tolerant of missing/shrinking files).

---

## `internal/manifest/` — the YAML contract

### `manifest.go` (~393 lines)
Types `Manifest/Case/Resources/Solver/Mesh/Post/MPI/Runtime/Storage`,
`Load` (strict decode → resolve relative paths → `applyDefaults` →
`Validate`), `Ranks()` (`nodes × tasksPerNode`), `WallTime()` (Slurm
`HH:MM:SS`), `detectFoamBashrc` (manifest → `$FOAM_BASHRC` → glob
`/opt/openfoam*/etc/bashrc` → fallback), `validExecutable` (any bare
solver name, no allow-list), `validSbatchExtra` + `reservedSbatch`
(managed-option guard), `SbatchExtraVars` (CLI-extra → REST fields).

### `manifest_test.go`
Relative-path resolution: `case.path: ./case` becomes absolute against the
manifest directory.

### `example.yaml`
Legacy minimal manifest fixture (`cavity`, `simpleFoam`). Unreferenced by
code; superseded by top-level `examples/`. Kept for history.

---

## `internal/preflight/` — case safety checks

### `preflight.go` (~222 lines)
- `Runner{ FoamDictionary, CheckMesh, AllowedDirectives }` + `Run`:
  requires `system/`, `constant/`, `0/` or `0.orig/`; walks the case
  skipping `.git/.foam-cache/.foam-runs/processor*/logs/DBs`; rejects
  escaping symlinks; scans only `0/0.orig/constant/system` dicts for
  `DefaultBlockedTokens` (`#codeStream`, `#calc`, `codedFixedValue`,
  `codedMixed`, `libs`); optional tool runs become findings.
- `isDictPath`, `scanFile`, `within`, `runTool`, `Subdomains`
  (`numberOfSubdomains` parser for the decompose check).

### `preflight_test.go`
Blocked directive rejected; directives in README/slurm/manifest ignored;
`Subdomains` parsing.

### `preflight_generic_test.go`
`0.orig` satisfies layout; `AllowedDirectives: ["libs"]` exempts vetted
cases while the default still rejects.

---

## `internal/stage/` — content cache + run copies

### `stage.go` (~285 lines)
- `New(cacheDir)`, `Stage(caseDir, include...) → {Hash, Path, Cached}`,
  `Materialize(cached, runDir)`.
- Canonical inputs `0/0.orig/constant/system` + validated
  `case.include` tops (`checkIncludes`); deterministic sorted hash of
  names + contents (+ symlink targets); atomic cache populate with
  race convergence; `copyCaseTree` / `copyTree` with unsafe-symlink
  rejection. See `architecture.md §2.4`.

### `stage_test.go`
Stage + cache reuse (second identical submit is `Cached`); `README.md`
at case root is not staged and does not affect the hash.

### `stage_generic_test.go`
`case.include: ["Allrun"]` stages the file and changes the hash;
`0.orig` cases stage correctly.

---

## `internal/store/` — SQLite job records

### `store.go` (~155 lines)
WAL + `busy_timeout`, single connection, `jobs` table
(`id, name, state, manifest_path, case_hash, run_path, cache_path,
slurm_id, error, updated_at`; indexes on `updated_at`, `state`;
`run_path`/`cache_path` added by migration). `ValidStates` gate
(`STAGED/QUEUED/RUNNING/REQUEUED/UNKNOWN/DONE/FAILED/CANCELLED`).
`Create`, `UpdateState` (preserves `slurm_id` unless a new one is given),
`UpdatePaths`, `Get`, `List`/`ListByState`, `GetBySlurm`.

### `store_test.go`
Create → UpdateState → Get round-trip preserves state and Slurm ID.

---

## `internal/service/` — orchestration + script rendering

### `service.go` (~534 lines)
- `Service{ Scheduler, Store, Preflight, Metrics }`, `Result{ ID, CaseHash,
  CachePath, RunPath, SlurmID }`.
- `Validate` = manifest load + preflight + `checkDecomposition` (skipped
  serial/`none`) + `checkControlDict` (foamRun-any-model vs native match)
  + `checkCheckpoint` (`runTimeModifiable`) + `checkMeshSource`
  (strategy-appropriate inputs). Metrics bump on each rejection.
- `Submit` = validate → stage (with `case.include`) → `Create(STAGED)` →
  materialize → `UpdatePaths` → `checkpointScript` → scheduler submit
  (`Stdout`/`Stderr` set for REST, `Requeue = checkpoint>0`,
  `Extra = exclusive/hint/signal?/sbatchExtra`) → `QUEUED` (or `FAILED`
  on rejection) + metrics.
- `checkpointScript(m, runDir)` — the entire batch script from manifest
  fields only: SBATCH header, env, `foam_serial`/`foam_mpi` wrappers
  (host/container × mpirun/srun), mesh / decompose / solver / post
  sections, USR1 checkpoint iff enabled. `shellQuote`/`shellSingle`
  single-quote escaping; `joinArgs`/`quotedAll` per-arg quoting.

### `service_test.go`
Submit persists `QUEUED` with run/cache paths and renders SBATCH headers,
`blockMesh`/`decomposePar`, `mpirun`, requeue wiring.

### `service_generic_test.go`
The no-hard-coding proof: `foamRun` + `incompressibleFluid` / `fluid` /
custom model + native solvers all submit and invoke the manifest solver;
mismatch, missing `runTimeModifiable`, serial (no `-parallel`/decompose),
`srun` + `fileHandler: none`, and `checkpointSeconds: 0` (no
signal/requeue) behaviors pinned.

---

## `internal/scheduler/cli.go` — sbatch adapter (~137 lines)

`CliScheduler` (overridable binary names) implementing `Scheduler`:
`Submit` writes `<runDir>/foam-clutch.sbatch` and parses `sbatch
--parsable`; `State` tries `squeue` → `scontrol` → `sacct` (compound
states reduced to first word); `Cancel` via `scancel`. Zero-config
fallback wherever `slurmrestd` is absent.

## `internal/supervisor/supervisor.go` — Slurm polling (~133 lines)

`Supervisor{ Scheduler, Store, Metrics, PollInterval, MaxUnknown }`:
immediate first poll, then ticker; solver-agnostic `slurmToLocal` mapping
(`CONFIGURING→QUEUED`, `COMPLETING→RUNNING`, `OUT_OF_MEMORY→FAILED`,
requeue-class stays polling); `UNKNOWN` with default-5 bounded retries;
`ToLocal` export for one-shot CLI refresh; requeue/terminal counters.

## `internal/telemetry/metrics.go` — Prometheus (~60 lines)

Nine atomic counters with `HELP`/`TYPE` exposition: submissions,
preflight failures, stage hits/misses, requeues, jobs done/failed/
cancelled, watch errors.

---

## Templates, images, examples

### `solver.sbatch.tmpl`
Standalone `text/template` twin of `checkpointScript`: same fields
(solver/args/parallel/file-handler flags, launcher/flavour/MPI extras,
mesh strategy + commands, reconstruct/post, checkpoint-gated
requeue+signal, container SIF/bind, raw `sbatchExtra`) for rendering a
batch script outside the Go service. Header comment documents every field.

### `openfoam.def`
Apptainer recipe from `opencfd/openfoam-run:${OF_VERSION}` (default
`2506`): sets `FOAM_BASHRC`/`OMP_NUM_THREADS`, documents the three MPI
strategies (image MPI + `srun --mpi=pmix`, rebuild against host MPI,
container for pre/post only) and keeps case data bind-mounted instead of
baked into the image. Build with `--fakeroot`, verify
`ompi_info | grep -i pmix` for multi-node use.

### `examples/`
- `heavySimple.yaml` — 2×4 `foamRun` (model `incompressibleFluid`),
  checkpoint 600, `auto` mesh, `mpirun`, repo-absolute cache/run dirs.
- `heavyBuoyant.yaml` — same shape, physics `fluid` (buoyant cavity).
- `generic.yaml` — commented template for any solver: arbitrary
  `solver.name`, `sbatchExtra`, container, custom mesh/post, `srun`
  flavour. Start new projects by copying this file.
