<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Sluice


Sluice runs OpenFOAM cases on Slurm without repeating the same setup
every time.

Sluice is a job-lifecycle control plane around OpenFOAM and Slurm. It
checks your case, caches it, submits it, and follows it. It is not a
scheduler: Slurm still decides when and where jobs run.

## Quickstart (no cluster needed)

You need Go 1.26+ ([install
instructions](https://go.dev/doc/install)). Then:

```bash
go install github.com/ananymishradev/sluice/cmd/sluice@latest
sluice init --output manifest.yaml --solver simpleFoam --case ./case --tasks 1
sluice validate --manifest /abs/path/manifest.yaml
sluice doctor
sluice run --manifest /abs/path/manifest.yaml --dry-run
```

Use an absolute `--manifest` path (a relative path breaks case
resolution today). Use `--tasks 1` for a serial case, or ship
`system/decomposeParDict` with `numberOfSubdomains` equal to
`nodes x tasksPerNode`. `doctor` exits 3 without Slurm/OpenFOAM; that
is normal on a laptop. See [getting
started](docs/getting-started.md) for a full transcript.

## On a cluster

```bash
sluice run --manifest /abs/path/manifest.yaml
sluice run --manifest /abs/path/manifest.yaml --tail
sluice status --db sluice.db --id <local-job-id> --refresh
sluice logs --manifest /abs/path/manifest.yaml --latest
```

## What it does

- Strict manifests (`sluice/v1alpha1`, legacy accepted with a warning)
- Case preflight before queue time is spent
- SHA-256 cache plus isolated run directories
- SQLite job records, CLI and REST Slurm backends
- USR1 checkpoint/requeue, Prometheus metrics, small HTTP service

Details live in [docs/](docs/README.md).

## Status

Working control-plane foundation, not a multi-tenant platform. Do not
expose it unauthenticated on a shared network. See
[security](docs/security.md) and [roadmap](docs/roadmap.md).

## Links

- [Documentation index](docs/README.md)
- [Contributing](CONTRIBUTING.md) (docs repo; code carriage noted inside)
- [License](https://github.com/ananymishradev/sluice/blob/main/LICENSE)
  (Apache-2.0; this docs repo carries no separate license file)
