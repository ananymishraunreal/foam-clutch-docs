<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Migrating from Foam Clutch


The rename landed: binary `clutch` is now `sluice`
(`github.com/ananymishradev/sluice`). Pure rename, no behavior
change except names. The `it` alias for `run` stays.
`.foam-cache/` and `.foam-runs/` keep their names.

- Binary: use `sluice`. No `clutch` shim; the installer only prints
  a notice when it finds an old copy.
- Manifests: `sluice init` writes `sluice/v1alpha1`.
  `foam-clutch/v1alpha1` still loads with a one-line stderr warning.
- Env: `SLUICE_API_TOKEN` replaces `FOAM_CLUTCH_API_TOKEN`; the old
  name still works with a once-per-process warning, new wins.
- DB: default `sluice.db`; an existing `foam-clutch.db` is used with
  a notice and never moved automatically.
- Runs: new scripts are `sluice.sbatch`; old run dirs untouched.
- Metrics: `foam_clutch_*` became `sluice_*` (breaking for
  dashboards; no dual emission).
