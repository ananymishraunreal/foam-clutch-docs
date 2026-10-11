<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# Environment reference


Every variable the code reads. Secrets are marked; values never
appear in logs or docs.

| Variable | Used by | Purpose | Secret |
|---|---|---|---|
| `SLUICE_API_TOKEN` | `serve` | Bearer token for `GET /jobs`; empty = open | yes |
| `SLURM_REST_URL` / `SLURM_SOCKET` | `submit run watch status cancel`, doctor | REST endpoint (one required for `rest`) | no |
| `SLURM_API_VERSION` | same | REST version, e.g. `v0.0.43` | no |
| `SLURM_USER` | same | Slurm user name | no |
| `SLURM_JWT_FILE` | same, doctor | JWT file, re-read per request (preferred) | yes |
| `SLURM_JWT` | same, doctor | static JWT fallback | yes |
| `FOAM_BASHRC` | manifest default, doctor, install | OpenFOAM env fallback | no |
| `NO_COLOR` | all commands | disables colors and the live view | no |
