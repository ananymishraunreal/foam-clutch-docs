<!-- Audience: all three; start here, then follow your track. -->
# Documentation index


## Track 1: run cases (engineer)

- [Getting started](getting-started.md): install, first manifest,
  first run, first failure, with a real transcript.
- [Running on a cluster](guides/running-on-a-cluster.md): CLI vs REST
  backends, env vars, JWT handling.
- [Parameter sweeps](guides/parameter-sweeps.md): what works today.
- [Troubleshooting](guides/troubleshooting.md): symptom -> cause ->
  fix, built from real error strings.
- [Example cluster setup](guides/example-cluster-setup.md): the one
  cluster-specific example, labeled as such.

## Track 2: trust it (cluster admin)

- [Concepts overview](concepts/overview.md): plain-English behavior.
- [Security](security.md): trust boundaries, what preflight does not
  catch, hardening checklist.
- [Architecture](architecture.md): pipeline, state machine, crash
  semantics.
- [HTTP service](guides/http-service.md): endpoints, auth, what is not exposed.

## Track 3: change it (contributor / hiring manager)

- [Manifest reference](reference/manifest.md)
- [Environment reference](reference/environment.md)
- [CLI reference](reference/cli/sluice.md)
- [Exit codes](reference/exit-codes.md),
  [metrics](reference/metrics.md), [HTTP API](reference/http-api.md),
  [files](reference/files-and-directories.md)
- [Roadmap](roadmap.md) (not features), [ADRs](adr/),
  [migration](migration.md)

## Concepts

- [overview](concepts/overview.md), [manifest](concepts/manifest.md),
  [preflight](concepts/preflight.md),
  [cache-and-runs](concepts/cache-and-runs.md),
  [job-lifecycle](concepts/job-lifecycle.md),
  [checkpointing](concepts/checkpointing.md),
  [glossary](concepts/glossary.md)
