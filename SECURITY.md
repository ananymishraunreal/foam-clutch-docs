<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# Security policy


## Reporting

Report vulnerabilities to TODO(owner) (replace this placeholder with
the maintained contact). Include the version (`sluice version`),
manifest (redacted), and logs. Expect acknowledgment within 5
business days.

## Supported versions

Latest `main` only. No backport window is promised.

## Scope

The CLI, service, manifest loader, preflight, staging, and
scheduler adapters. OpenFOAM, Slurm, MPI, and container images are
upstream scope; report those upstream.
