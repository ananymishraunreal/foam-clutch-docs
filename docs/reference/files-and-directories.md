<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Files and directories


Cache: `<cacheDir>/<sha256>/` (hit reuses, miss populates via atomic
rename). Never edited after creation.

Run directory `<runDir>/<local-job-id>/` holds: `log.solver` (all
ranks), `slurm-<id>.out` / `slurm-<id>.err`, the exact executed
`sluice.sbatch` (resubmit to reproduce), `log.blockMesh` /
`log.decomposePar` / `log.mesh` / `log.post` /
`log.reconstructPar` as produced, `processor*` for parallel runs,
and `.foam-checkpoint-requested` when a checkpoint fired.

Database (default `<manifest-dir>/sluice.db`; never moved
automatically). Real schema (`internal/store/store.go`):

```sql
CREATE TABLE IF NOT EXISTS jobs (
 id TEXT PRIMARY KEY, name TEXT NOT NULL, state TEXT NOT NULL,
 manifest_path TEXT NOT NULL, case_hash TEXT NOT NULL,
 slurm_id INTEGER NOT NULL DEFAULT 0,
 error TEXT NOT NULL DEFAULT '', updated_at TEXT NOT NULL
);
```

Later migrations add `run_path` and `cache_path`; indexes on
`updated_at` and `state`. SQLite WAL mode, single connection.
