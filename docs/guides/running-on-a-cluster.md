<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Running on a cluster


Pick a backend with `--backend auto|rest|cli` (default `auto`).
`cli` shells out to `sbatch`/`squeue`/`scontrol`/`sacct`/`scancel`
and needs nothing else. `rest` talks to `slurmrestd` and needs
`SLURM_API_VERSION`, `SLURM_USER`, a token (`SLURM_JWT_FILE`
preferred, re-read every request, or `SLURM_JWT`), plus
`SLURM_REST_URL` or `SLURM_SOCKET`. `auto` uses REST when all four
are set, else CLI. Never put tokens in shell history or logs; prefer
the file form so rotation needs no restart. A real run:

```bash
sluice run --manifest /abs/path/manifest.yaml --backend cli
sluice status --db sluice.db --id <local-job-id> --refresh
sluice logs --manifest /abs/path/manifest.yaml --latest
```

Detach with Ctrl-C or `q`: polling stops, the Slurm job keeps
running, and the notice tells you the `status`/`cancel` commands to
re-attach. Variable detail: [environment](../reference/environment.md).
