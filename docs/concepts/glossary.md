<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Glossary


- Case: an OpenFOAM case directory (`0/`, `constant/`, `system/`).
- Manifest: the YAML job description pointing at a case.
- Run: one submission: a run directory plus a Slurm job.
- Local job ID: Sluice's UUID for the run (primary key).
- Slurm job ID: the scheduler's integer (e.g. 48213 in tests).
- Cache: content-addressed frozen copy (`<cacheDir>/<sha256>/`).
- Run directory: mutable per-job copy (`<runDir>/<local-job-id>/`).
- Ranks: `resources.nodes x resources.tasksPerNode`.
- Backend: `cli` (sbatch commands) or `rest` (slurmrestd); `auto`
  picks REST when its env is fully set.
