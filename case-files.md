# OpenFOAM case compatibility

This page lists exactly what must, may, and must-not be inside an OpenFOAM
case folder for foam-clutch to accept and run it. The rules come from
`internal/preflight/preflight.go`, `internal/stage/stage.go`, and the
`check*` functions in `internal/service/service.go` (repo:
`/home/shared/foam-clutch`).

## 1. Required entries

At the top level of `case.path`, these directories must exist:

| Entry | Rule | Why |
|---|---|---|
| `system/` | required directory | `controlDict`, `fvSchemes`, `fvSolution`, mesh/decompose dicts |
| `constant/` | required directory | physical properties, transport/thermo models |
| `0/` **or** `0.orig/` | at least one required | initial/boundary fields; tutorials often ship `0.orig` and create `0` at run time |

Inside `system/`, these files must exist (or the corresponding check fails):

| File | Rule |
|---|---|
| `system/controlDict` | required. Must declare `application <name>;`. With `application foamRun` (OpenFOAM 12 runner style) a `solver <model>;` entry is also required — the model name is free-form (`incompressibleFluid`, `fluid`, anything). For a native solver, `application` must equal manifest `solver.name`. With `checkpointSeconds > 0`, `runTimeModifiable true;` is required. |
| `system/decomposeParDict` | required for parallel runs (`nodes × tasksPerNode > 1`) unless `mesh.strategy: none`. `numberOfSubdomains` must equal the rank count. Not needed for serial (`1×1`) runs. |
| `system/blockMeshDict` | required when `mesh.strategy` is `blockMesh`, or `auto` without a prebuilt `constant/polyMesh`. Not needed when `polyMesh` is shipped or strategy is `custom`/`none`. |
| `system/fvSchemes`, `system/fvSolution` | required by OpenFOAM itself (not checked by foam-clutch, but the solver will fail without them). |

## 2. Optional entries (staged only if you ask)

Only `0/`, `0.orig/`, `constant/`, `system/` are staged and hashed by
default. Anything else at the case root is ignored **unless** listed in
manifest `case.include`, in which case it is staged, hashed, and shipped to
the job. Good candidates:

- `Allrun`, `Allclean`, `cleanCase.sh` — tutorial helpers you want frozen
  with the run for reproducibility.
- `constant/triSurface/` — STL geometry for `snappyHexMesh` workflows.
  Note: `constant/` itself is always staged, so `triSurface/` inside it
  needs no `include`; a *top-level* `triSurface/` would.
- Extra top-level inputs the job needs at run time (helper scripts,
  additional dictionaries). Anything the solver reads must be staged,
  or the job will fail with "file not found".

`case.include` entries must be case-relative, single-line, must exist, must
not duplicate canonical inputs, and must not point at runner artefacts
(`processor*`, `.foam-*`, `.git`, logs, DBs).

## 3. Ignored entries (may stay in the folder, never affect runs)

These are never scanned, hashed, or staged. Keep them alongside the case
freely — documentation, helper scripts, old results:

- `README.md`, manifests (`manifest.yaml`), shell scripts (`run_*.sh`,
  `Allrun` unless included), `*.slurm`, `foam-clutch-runs.log`
- `processor*/` — never staged, never scanned.
- `.git/`, `.foam-cache/`, `.foam-runs/` — runner/VCS state, skipped
  everywhere including directive scans.
- `slurm-*.out/.err`, `log.*`, `*.db*` — artefacts, skipped everywhere.
- Time directories (`100/`, `500/`, `postProcessing/`) from previous
  serial runs — top-level, not staged. (Clean them with the case's
  `cleanCase.sh`/`foamCleanCase` to keep the folder tidy, but foam-clutch
  does not care.)

Note: `constant/polyMesh/` *is* staged when present (it lives inside the
canonical `constant/`), which is exactly how pre-meshed cases skip
`blockMesh` under strategy `auto`.

## 4. Forbidden content (preflight rejects the case)

Inside `0/`, `0.orig/`, `constant/`, `system/` dictionaries only (docs and
scripts elsewhere are not scanned):

- Executable directives: `#codeStream`, `#calc`, `codedFixedValue`,
  `codedMixed`, `libs` (exact substring match per line). Each hit is an
  error with file and line number. A vetted case can exempt tokens via the
  preflight `AllowedDirectives` mechanism — there is no manifest flag for
  this; exemptions are operator-approved, not user-claimed.
- Symlinks (anywhere in the case) whose target resolves outside the case
  directory. Relative links staying inside are fine.

Also rejected at validation (not preflight proper, same fail-fast spirit):

- `controlDict` application/solver disagreeing with manifest `solver.name`.
- `decomposeParDict` subdomain count ≠ rank count (parallel runs).
- `checkpointSeconds > 0` without `runTimeModifiable true;`.
- `mesh.strategy: auto` with neither `polyMesh` nor `blockMeshDict`;
  `blockMesh` without `blockMeshDict`; `custom` without `commands`.

## 5. Worked examples

### heavySimple (steady, incompressible, `foamRun`)

Source: `/home/shared/openfoam/heavySimple/`.

```text
heavySimple/
  0/epsilon 0/f 0/k 0/nut 0/nuTilda 0/omega 0/p 0/U 0/v2
  constant/momentumTransport constant/physicalProperties
  system/blockMeshDict system/controlDict system/decomposeParDict
  system/functions system/fvSchemes system/fvSolution
  manifest.yaml          # solver foamRun, 2 nodes x 4 tasks, checkpoint 600
```

- `controlDict`: `application foamRun;` + `solver incompressibleFluid;` +
  `runTimeModifiable true;` → passes `checkControlDict` + `checkCheckpoint`.
- `decomposeParDict`: `numberOfSubdomains 8` = 2×4 → passes
  `checkDecomposition`.
- No `polyMesh` shipped + `blockMeshDict` present + strategy `auto` →
  the job runs `blockMesh` once, then `decomposePar`, then
  `mpirun foamRun -parallel -fileHandler collated`.
- `system/functions` uses `#includeFunc streamlinesLine` (not a blocked
  token) → passes preflight.
- Per-case extras (`Allrun`, `run_*.sh`, `cleanCase.sh`, README,
  `foam-clutch.db`, `.foam-cache/`, `.foam-runs/`) are ignored.

### heavyBuoyant (transient buoyant heat transfer, `foamRun`)

Source: `/home/shared/openfoam/heavyBuoyant/`.

```text
heavyBuoyant/
  0/alphat 0/epsilon 0/k 0/nut 0/omega 0/p 0/p_rgh 0/T 0/U
  constant/g constant/momentumTransport constant/physicalProperties
  constant/pRef
  system/blockMeshDict system/controlDict system/decomposeParDict
  system/fvSchemes system/fvSolution
  manifest.yaml          # solver foamRun, 2 nodes x 4 tasks, checkpoint 600
```

- `controlDict`: `application foamRun;` + `solver fluid;` → same generic
  `foamRun` path as heavySimple; the differing model name needs no code
  change anywhere.
- Deliberately ships **without** the tutorial's `system/sample`
  post-processing dict, which contains a library-loading entry the
  preflight blocklist rejects.

## 6. New-case checklist

1. `system/`, `constant/`, and `0/` (or `0.orig/`) exist.
2. `system/controlDict` declares the right `application` (and `solver`
   model for `foamRun`); add `runTimeModifiable true;` if checkpointing.
3. Parallel runs: `system/decomposeParDict` count equals
   `nodes × tasksPerNode`.
4. Meshing inputs present for the chosen `mesh.strategy` (`blockMeshDict`
   for `auto`/`blockMesh`, `mesh.commands` for `custom`, prebuilt
   `constant/polyMesh` or `none` otherwise).
5. `solver.name` matches the `controlDict` application.
6. No blocked directives in the four input dirs; no escaping symlinks.
7. Anything the job needs beyond the canonical three listed in
   `case.include`.
8. `validate` passes, then `run` (or `submit` + `watch`).
