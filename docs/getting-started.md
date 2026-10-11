<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Getting started


You install Sluice, scaffold a manifest, validate it, dry-run it, and
read your first failure. Nothing here needs Slurm.

## 1. Install

```bash
go install github.com/ananymishradev/sluice/cmd/sluice@latest
```

You need Go 1.26 or newer. `sluice version` should print a version.

## 2. First manifest

Make a serial case (one rank needs no `decomposeParDict`):

```bash
sluice init --output manifest.yaml --solver simpleFoam --case ./case --tasks 1
```

This writes `manifest.yaml` with `apiVersion: sluice/v1alpha1`. Always
pass `--manifest` as an absolute path from here on: a relative path
breaks case resolution today (known bug, reported not fixed).

## 3. First validation

```bash
sluice validate --manifest /abs/path/manifest.yaml
```

Success looks like this (captured from the real binary):

```text
[ok] manifest     myCase · sluice/v1alpha1
[ok] layout       0/ or 0.orig/ · constant/ · system/
[ok] symlinks     no escaping symlinks
[ok] directives   no blocked code-loading directives
[ok] checks       no warnings
```

## 4. First dry run

```bash
sluice run --manifest /abs/path/manifest.yaml --dry-run
```

Captured output (IDs shortened):

```text
12:53:31 [ok] manifest     myCase
12:53:31 [ok] cache        <WORK>/.foam-cache/<CASE_HASH>
# dry run: nothing was submitted
# cache: <WORK>/.foam-cache/<CASE_HASH> (miss)
# rendered batch script:
#!/bin/bash
#SBATCH --job-name=myCase
...
```

Nothing is submitted and no database row is written.

## 5. First failure

Remove `system/blockMeshDict` with strategy `auto` and revalidate.
You get exit code 2 and a preflight finding naming the file. Fix it,
re-run `validate`, and continue. Each finding names its path: see
[troubleshooting](guides/troubleshooting.md).

## 6. A full run (needs Slurm or the fakes)

Against `testdata/fakeslurm` (deterministic Slurm ID 48213), a real
run prints stage lines, a JSON record on stdout, then the terminal
record:

```text
sluice run backend=cli manifest=<WORK>/m.yaml db=<WORK>/jobs.db
[ok] manifest     demo
[ok] cache        <WORK>/.foam-cache/<CASE_HASH>
[ok] run dir      <WORK>/.foam-runs/<LOCAL_ID>
[ok] submitted    slurm job 48213
{"ID":"<LOCAL_ID>","SlurmID":48213,...}
terminal state=DONE slurm=48213
```

Human lines go to stderr; JSON goes to stdout. `doctor` on a laptop
exits 3 (missing sbatch, OpenFOAM, MPI): that is expected, not a bug.
