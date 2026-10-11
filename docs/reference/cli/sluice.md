<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# CLI reference

<!-- Audience: (3) a contributor or hiring manager reading the repo. -->

Generated from the real binary via `scripts/capture-cli.sh`
(`SLUICE_BIN=... ./scripts/capture-cli.sh`). Do not hand-edit the
`.txt` files; change `--help` text in `cmd/sluice/` and recapture.
Drift check: `scripts/check-docs.sh`.

- [sluice](sluice.txt) (root, global flags)
- [version](sluice-version.txt), [init](sluice-init.txt),
  [validate](sluice-validate.txt),
  [submit](sluice-submit.txt),
  [watch](sluice-watch.txt),
  [status](sluice-status.txt),
  [cancel](sluice-cancel.txt), [list](sluice-list.txt),
  [logs](sluice-logs.txt), [serve](sluice-serve.txt),
  [doctor](sluice-doctor.txt), [run](sluice-run.txt)
