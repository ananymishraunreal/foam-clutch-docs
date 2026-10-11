<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# Contributing (docs repo)


This repo holds standalone Sluice documentation. Source code lives
elsewhere; these notes cover both sides so doc edits stay honest.

## Docs workflow

- Capture, never invent: terminal output comes from the real binary
  (`SLUICE_BIN=... ./scripts/capture-cli.sh`), then strip ANSI and
  normalize IDs/paths.
- After any edit run `./scripts/check-docs.sh` (needs `SLUICE_BIN`):
  it recaptures CLI output and checks every relative link and anchor.
- Code-side drift guards (manifest reflection, env regex, example
  loading, link check, `verify:manifest` blocks) belong to the code
  repo and are not duplicated here; keep field tables in sync with
  `internal/manifest/manifest.go` by hand until they land there.

## Code repo notes (for cross-repo contributors)

Build: `go build ./...`. Test: `go test -race ./...`, plus the PTY
suite `go test -race -run '^TestPTY_' ./cmd/sluice` (needs a pty).
`testdata/fakeslurm` fakes sbatch/squeue/scontrol/sacct/scancel via
`$FAKESLURM_DIR/state` (deterministic ID 48213); `FAKESLURM_BLOCK_SBATCH=1`
blocks submit. Goldens come from the baseline commit and are never
regenerated from HEAD (see the golden README). UI rule: humans to
stderr, data to stdout, exit codes 0/1/2/3. Release version comes
from `-ldflags -X main.Version=...`. Commit style follows short
imperative subjects.
